#!/usr/bin/env python3
"""Run offline identity checks and existing tests in isolated Lua 5.1 VMs."""
import json
from pathlib import Path

from lupa.lua51 import LuaRuntime


ROOT = Path(__file__).resolve().parents[1]
SOURCE = ROOT / "Contents/mods/B47ANCEDProvisions"
LUA = SOURCE / "42/media/lua"


def text(path):
    return path.read_text(encoding="utf-8")


def main():
    metadata = dict(line.split("=", 1) for line in text(SOURCE / "42/mod.info").splitlines() if "=" in line)
    assert metadata["name"] == "B47ANCE’d Provisions"
    assert metadata["id"] == "B47ANCEDProvisions"
    assert metadata["modversion"] == text(ROOT / "VERSION").strip()
    assert not (ROOT / "Contents/mods/foodWorks").exists()
    assert text(ROOT / "WORKSHOP_ID.txt").strip() == "3788591331"
    workshop = text(ROOT / "workshop.txt").splitlines()
    assert "title=B47ANCE’d Provisions" in workshop
    body = "\n".join(line.removeprefix("description=") for line in workshop if line.startswith("description=")) + "\n"
    assert body == text(ROOT / "WORKSHOP_DESCRIPTION.txt"), "Workshop description mirrors differ"
    assert "Mod ID: B47ANCEDProvisions\n" in body
    assert "\\n" not in body, "Description must contain actual paragraph breaks"
    translations = json.loads(text(LUA / "shared/Translate/EN/Sandbox.json"))
    assert translations["Sandbox_foodWorks"] == "B47ANCE’d Provisions"
    assert "foodWorks.EnableFoodInspection" in text(SOURCE / "42/media/sandbox-options.txt")
    print("PASS identity, Workshop text, and preserved sandbox identifiers", flush=True)

    # Validate exact require-path case without relying on Windows' filesystem case folding.
    for module in ["API", "ApplianceTransactions", "PreservationProcesses", "AppleDrying", "FruitDryingProfiles", "Load"]:
        assert f"{module}.lua" in {p.name for p in (LUA / "shared/foodWorks").iterdir()}
    for module in ["FoodInspection", "FruitDryingPreview", "AppleDryingClient"]:
        assert module + ".lua" in {p.name for p in (LUA / "client/foodWorks").iterdir()}

    cases = [
        ("test_api.lua", []),
        ("test_food_inspection.lua", [LUA / "client/foodWorks/FoodInspection.lua"]),
        ("test_fruit_drying_preview.lua", [LUA / "client/foodWorks/FruitDryingPreview.lua"]),
        ("test_appliance_transactions.lua", [LUA / "shared/foodWorks/ApplianceTransactions.lua"]),
        ("test_preservation_processes.lua", [LUA / "shared/foodWorks/PreservationProcesses.lua"]),
        ("test_apple_drying.lua", [LUA / "server/foodWorks/AppleDryingServer.lua", LUA / "client/foodWorks/AppleDryingClient.lua"]),
        ("test_sweet_preserves.lua", [LUA / "shared/foodWorks/SweetPreservesAction.lua", LUA / "client/foodWorks/SweetPreservesClient.lua", LUA / "server/foodWorks/SweetPreservesServer.lua"]),
        ("test_load_graph.lua", [LUA / f"{realm}/foodWorks/Load.lua" for realm in ["shared", "server", "client"]]),
    ]
    for name, arguments in cases:
        lua = LuaRuntime(unpack_returned_tuples=True)
        lua.globals().arg = lua.table_from({i: p.as_posix() for i, p in enumerate(arguments, 1)})
        lua.globals().TRANSLATIONS = lua.table_from(json.loads(text(LUA / "shared/Translate/EN/UI.json")))
        lua.execute('package.path = ... .. ";" .. package.path', LUA.as_posix() + "/shared/?.lua")
        lua.execute(text(ROOT / "tests" / name), name=name)
        print("PASS " + name, flush=True)

    lua = LuaRuntime(unpack_returned_tuples=True)
    lua.execute('''
        package.preload["TimedActions/ISBaseTimedAction"]=function()
            ISBaseTimedAction={}
            function ISBaseTimedAction:derive(name)
                local o={Type=name};o.__index=o;setmetatable(o,{__index=self});return o
            end
        end
    ''')
    lua.execute('package.path = ... .. ";" .. package.path', ";".join((LUA / realm).as_posix() + "/?.lua" for realm in ["shared", "client", "server"]))
    loader = lua.eval("dofile")
    shared = loader((LUA / "shared/foodWorks/Load.lua").as_posix())
    assert shared.VERSION == text(ROOT / "VERSION").strip()
    loader((LUA / "server/foodWorks/Load.lua").as_posix())
    loader((LUA / "client/foodWorks/Load.lua").as_posix())
    assert lua.eval('foodWorks.ApplianceTransactions.ROOT_KEY') == "foodWorks.applianceTransaction.v1"
    assert lua.eval('foodWorks.ApplianceTransactions.HISTORY_KEY') == "foodWorks.applianceOperations.v1"
    for path in sorted(LUA.rglob("*.lua")):
        lua.execute('assert(loadfile(...))', path.as_posix())
    print("PASS production loaders, Lua syntax, legacy API and persistence keys", flush=True)
    print("Offline Lua 5.1 only; SP and dedicated multiplayer NOT TESTED.", flush=True)


if __name__ == "__main__":
    main()
