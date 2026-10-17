#!/usr/bin/env python3
"""Static native persistence/sync checks for in-place drying; never executes game code.

Requires development-only jawa==2.2.0. Not a mod runtime dependency.
"""
import argparse
from io import BytesIO
import json
from zipfile import ZipFile

from jawa.cf import ClassFile

import check_fruit_drying_evidence as fingerprints
from check_native_drying_hooks import method, calls, require


def fields(cf, method_name, operation):
    names = set()
    for instruction in method(cf, method_name).code.disassemble():
        if instruction.mnemonic == operation:
            reference = cf.constants.get(instruction.operands[0].value)
            names.add(reference.name_and_type.name.value)
    return names


def main():
    p = argparse.ArgumentParser(description=__doc__)
    p.add_argument("--game-root", required=True)
    p.add_argument("--steam-build", required=True)
    args = p.parse_args()
    fingerprints.main(["--process", "--game-root", args.game_root, "--steam-build", args.steam_build])
    report = json.loads((fingerprints.ROOT / "docs/APPLE_DRYING_EVIDENCE.json").read_text(encoding="utf-8"))
    classes = {}
    with ZipFile(fingerprints.safe_path(fingerprints.Path(args.game_root), "projectzomboid.jar")) as archive:
        for entry in report["native_classes"]:
            data = archive.read(entry["member"])
            loose = fingerprints.safe_path(fingerprints.Path(args.game_root), entry["member"])
            if loose.exists():
                require(loose.read_bytes() == data, "Loose/native mismatch: " + entry["member"])
            classes[entry["member"][:-6]] = ClassFile(BytesIO(data))
    food = classes["zombie/inventory/types/Food"]
    item = classes["zombie/inventory/InventoryItem"]
    resource = classes["zombie/entity/components/resources/Resource"]
    resource_item = classes["zombie/entity/components/resources/ResourceItem"]
    for name in ("age", "offAge", "offAgeMax", "thirstChange", "calories", "proteins", "lipids", "carbohydrates"):
        require(name in fields(food, "save", "getfield"), "Food field not saved: " + name)
        require(name in fields(food, "load", "putfield"), "Food field not loaded: " + name)
    require("id" in fields(item, "save", "getfield") and "id" in fields(item, "load", "putfield"), "Item ID persistence changed")
    for name, target in (("save", "save"), ("load", "load")):
        require(any(owner == "se/krka/kahlua/vm/KahluaTable" and symbol == target
                    for _, owner, symbol, _ in calls(item, name)), "Item ModData persistence changed")
    require(any(symbol == "getActualWeight" for _, _, symbol, _ in calls(item, "save")), "Custom weight save changed")
    require(any(owner == "zombie/inventory/InventoryItem" and symbol == "saveWithSize"
                for _, owner, symbol, _ in calls(resource_item, "saveSync")), "Resource full-item sync changed")
    require(any(symbol == "sendToRelative" for _, _, symbol, _ in calls(resource, "sync")), "Resource sync send changed")
    require(any(symbol == "save" and owner == "zombie/inventory/CompressIdenticalItems"
                for _, owner, symbol, _ in calls(resource_item, "save")), "Resource item persistence changed")
    require(any(symbol == "load" and owner == "zombie/inventory/CompressIdenticalItems"
                for _, owner, symbol, _ in calls(resource_item, "load")), "Resource item restore changed")
    require(any(symbol == "removeItem" for _, _, symbol, _ in calls(resource_item, "removeItemById")), "Exact item removal changed")
    require(any(symbol == "getWorldAgeHours" for _, _, symbol, _ in calls(food, "updateAge", "(Z)V")), "Native age source changed")
    print("PASS static Food age/threshold/nutrition, item ID/ModData/custom-weight persistence and full-item resource synchronization")
    print("Source control flow only. Lua binding, native save/load, transfer crash behavior and dedicated operation NOT TESTED.")


if __name__ == "__main__":
    main()
