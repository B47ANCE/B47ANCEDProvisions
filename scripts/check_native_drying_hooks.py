#!/usr/bin/env python3
"""Recheck installed drying call order without loading or executing game classes.

Development-only dependency: jawa==2.2.0. This tool is never part of mod runtime.
PASS means the recorded static findings match, including implementation blockers.
"""
import argparse
from hashlib import sha256
from io import BytesIO
import json
from pathlib import Path
from zipfile import ZipFile

from jawa.cf import ClassFile


ROOT = Path(__file__).resolve().parents[1]


def require(condition, message):
    if not condition:
        raise ValueError(message)


def method(cf, name, descriptor=None):
    found = [m for m in cf.methods if m.name.value == name
             and (descriptor is None or m.descriptor.value == descriptor)]
    require(len(found) == 1, f"Ambiguous/missing method: {name} {descriptor}")
    return found[0]


def calls(cf, name, descriptor=None):
    result = []
    for instruction in method(cf, name, descriptor).code.disassemble():
        if instruction.mnemonic not in ("invokevirtual", "invokespecial", "invokestatic", "invokeinterface"):
            continue
        reference = cf.constants.get(instruction.operands[0].value)
        result.append((instruction.pos, reference.class_.name.value,
                       reference.name_and_type.name.value,
                       reference.name_and_type.descriptor.value))
    return result


def ordered(cf, name, expected, descriptor=None):
    observed = calls(cf, name, descriptor)
    positions = []
    for owner, target in expected:
        matches = [pos for pos, cls, symbol, _ in observed if cls == owner and symbol == target]
        require(len(matches) == 1, f"Ambiguous/missing call: {name} -> {owner}.{target}")
        positions.append(matches[0])
    require(positions == sorted(positions), f"Changed call order in {name}")
    return positions


def main():
    p = argparse.ArgumentParser(description=__doc__)
    p.add_argument("--game-root", type=Path, required=True)
    p.add_argument("--steam-build", required=True)
    args = p.parse_args()
    evidence = json.loads((ROOT / "docs/FRUIT_DRYING_HOOK_EVIDENCE.json").read_text(encoding="utf-8"))
    require(args.steam_build == evidence["steam_build"], "STALE_BUILD: repeat audit")
    classes = {}
    with ZipFile(args.game_root / "projectzomboid.jar") as archive:
        for entry in evidence["native_classes"]:
            member = entry["member"]
            # Evidence is a bounded, project-owned list; reject path traversal anyway.
            parts = Path(member).parts
            require(not Path(member).is_absolute() and ".." not in parts and ":" not in member
                    and "\\" not in member and member.startswith("zombie/")
                    and member.endswith(".class"), "Unsafe class member")
            data = archive.read(member)
            require(sha256(data).hexdigest() == entry["sha256"], f"STALE_SOURCE: {member}")
            loose = args.game_root / member
            if loose.exists():
                require(loose.read_bytes() == data, f"Loose/packaged class mismatch: {member}")
            classes[member[:-6]] = ClassFile(BytesIO(data))

    prefix = "zombie/entity/components/crafting/"
    data_name = prefix + "recipe/CraftRecipeData"
    system = classes[prefix + "CraftLogicSystem"]
    data = classes[data_name]
    recipe = classes["zombie/scripting/entity/components/crafting/CraftRecipe"]
    resources = classes["zombie/entity/components/resources/ResourceItem"]

    # This stub must not be mistaken for the separate, live per-item OnTest path.
    test = list(method(data, "luaCallOnTest").code.disassemble())
    require([i.mnemonic for i in test] == ["iconst_1", "ireturn"], "Recipe-level test changed")
    item_test = calls(recipe, "OnTestItem")
    require(any(symbol == "protectedCallBoolean" for _, _, symbol, _ in item_test), "Per-item OnTest changed")
    manager = classes[prefix + "recipe/CraftRecipeManager"]
    require(any(owner == "zombie/scripting/entity/components/crafting/CraftRecipe" and symbol == "OnTestItem"
                for _, owner, symbol, _ in calls(manager, "consumeInputItemInternal")), "Resource per-item test changed")

    start_order = ordered(system, "start", [
        (prefix + "CraftLogic", "canStart"), (data_name, "consumeInputs"),
        (prefix + "CraftLogic", "onStart"), (data_name, "luaCallOnStart")])
    stop_order = ordered(system, "stop", [(data_name, "createOutputs"), (data_name, "luaCallOnCreate"),
                                         (prefix + "CraftLogic", "finaliseRecipe")])
    output_order = ordered(data, "createOutputsInternal", [(data_name, "createRecipeOutputs"),
                                                         (data_name, "destroyAllSurvivingDestroyInputs")])
    distribute_order = ordered(data, "createRecipeOutputs", [(data_name, "createOutputItems"),
                                                           (data_name, "distributeItemsToResources")])
    # The resource offer requests immediate server sync before OnCreate is reached.
    distribution = list(method(data, "distributeItemsToResources").code.disassemble())
    offers = [i for i, ins in enumerate(distribution) if ins.mnemonic == "invokevirtual"
              and getattr(cfref := data.constants.get(ins.operands[0].value), "class_", None)
              and cfref.class_.name.value == "zombie/entity/components/resources/Resource"
              and cfref.name_and_type.name.value == "offerItem"]
    require(len(offers) == 1, "Resource offer path changed")
    require([ins.mnemonic for ins in distribution[offers[0]-3:offers[0]]] == ["iconst_1"] * 3,
            "Resource offer no longer requests sync")
    require(any(symbol == "sync" for _, _, symbol, _ in calls(
        resources, "offerItem", "(Lzombie/inventory/InventoryItem;ZZZ)Lzombie/inventory/InventoryItem;")),
        "Resource synchronization path changed")
    for name in ("luaCallOnStart", "luaCallOnUpdate", "luaCallOnCreate", "luaCallOnFailed"):
        for m in data.methods:
            if m.name.value == name:
                require(m.descriptor.value.endswith("V"), f"Callback gained a return contract: {name}")
    require(not any(m.name.value == "setTime" for m in recipe.methods), "New duration setter: reaudit")
    require(any(symbol == "save" and owner == "se/krka/kahlua/vm/KahluaTable"
                for _, owner, symbol, _ in calls(data, "save")), "Job ModData save changed")
    require(any(symbol == "load" and owner == "se/krka/kahlua/vm/KahluaTable"
                for _, owner, symbol, _ in calls(data, "load")), "Job ModData load changed")
    print(f"PASS {len(classes)} class fingerprints; loose files match where present")
    print(f"PASS start offsets {start_order}; finish offsets {stop_order}")
    print(f"PASS output/destruction offsets {output_order}; creation/distribution offsets {distribute_order}")
    print("PASS static findings: live per-item test, inert recipe test, void callbacks, pre-callback output sync,")
    print("no declared setTime, native job ModData serialization. No game classes executed.")
    print("PRODUCTION BLOCKED: these checks confirm limitations, not safe Lua integration or runtime behavior.")
    print("SP/dedicated NOT TESTED; G7 and stable G8 BLOCKED.")


if __name__ == "__main__":
    main()
