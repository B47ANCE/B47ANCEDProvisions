"""Authored contracts and optional read-only installed B42 evidence; never runtime proof."""
import argparse
import hashlib
import json
import re
from io import BytesIO
from pathlib import Path
from zipfile import ZipFile

ROOT = Path(__file__).resolve().parents[1]
MEDIA = ROOT / 'Contents/mods/B47ANCEDProvisions/42/media'


def digest(data):
    return hashlib.sha256(data).hexdigest()


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--game-root', type=Path)
    parser.add_argument('--steam-build')
    args = parser.parse_args()
    report = json.loads((ROOT / 'docs/SWEET_PRESERVES_EVIDENCE.json').read_text(encoding='utf-8'))
    assert report['project_version'] == (ROOT / 'VERSION').read_text(encoding='utf-8').strip()
    assert report['runtime_status'] == 'NOT_TESTED' and report['g7'] == 'BLOCKED / NOT TESTED'
    for row in report['project_files']:
        assert digest((ROOT / row['path']).read_bytes().replace(b'\r\n', b'\n')) == row['sha256'], row['path']
    script = (MEDIA / 'scripts/foodWorks_SweetPreserves.txt').read_text(encoding='utf-8')
    definitions = dict(re.findall(r'item (\w+)\s*\{([^}]+)\}', script))
    assert set(definitions) == {'JamSealed', 'JellySealed', 'JamOpened', 'JellyOpened', 'StrainedFruitPulp'}
    assert script.count('{') == script.count('}') and 'module foodWorks' in script
    names = json.loads((MEDIA / 'lua/shared/Translate/EN/ItemName.json').read_text(encoding='utf-8'))
    tips = json.loads((MEDIA / 'lua/shared/Translate/EN/Tooltip.json').read_text(encoding='utf-8'))
    for name, body in definitions.items():
        assert names['foodWorks.' + name]
        assert 'ItemType = base:food,' in body and 'IsCookable = false,' in body
        assert tips[re.search(r'Tooltip = (\w+),', body)[1]]
        assert ('CantEat = true,' in body) == name.endswith('Sealed')
        assert ('ReplaceOnUse = Base.EmptyJar,' in body) == name.endswith('Opened')
        assert 'ReplaceOnCooked' not in body and 'Tags =' not in body
    assert not args.game_root or args.steam_build == report['steam_build'] == '25485521'
    print('PASS sweet-preserve definitions/localization/current authored fingerprints')
    if not args.game_root:
        print('Installed binding/control-flow checks NOT RUN; supply --game-root and --steam-build')
        return
    game = args.game_root
    manifest = (game.parent.parent / 'appmanifest_108600.acf').read_text(encoding='utf-8')
    assert re.search(r'"buildid"\s+"' + args.steam_build + '"', manifest)
    for row in report['game_files']:
        assert digest((game / row['path']).read_bytes()) == row['sha256'], row['path']
    from jawa.cf import ClassFile
    with ZipFile(game / 'projectzomboid.jar') as archive:
        classes = {}
        for row in report['native_classes']:
            data = archive.read(row['member'])
            assert digest(data) == row['sha256'], row['member']
            loose = game / row['member']
            if loose.exists():
                assert loose.read_bytes() == data
            classes[row['member'].removesuffix('.class')] = ClassFile(BytesIO(data))

        def constants(owner, method):
            found = []
            for m in classes[owner].methods:
                if m.name.value != method or not m.code:
                    continue
                for ins in m.code.disassemble():
                    for op in ins.operands:
                        if op.op_type.name != 'CONSTANT_INDEX':
                            continue
                        c = classes[owner].constants.get(op.value)
                        if hasattr(c, 'class_') and hasattr(c, 'name_and_type'):
                            found.append(c.name_and_type.name.value)
                        elif hasattr(c, 'string'):
                            found.append(c.string.value)
                        elif c.__class__.__name__ == 'ConstantClass':
                            found.append(c.name.value)
            return found

        registered = constants('zombie/Lua/LuaManager$Exposer', 'exposeAll')
        for owner in ['zombie/inventory/types/Food', 'zombie/inventory/InventoryItem',
                      'zombie/inventory/ItemContainer', 'zombie/iso/objects/IsoStove']:
            assert owner in registered, owner
        wanted = {
            'zombie/inventory/types/Food': {'setCalories', 'setCarbohydrates', 'setLipids', 'setProteins',
                'setHungChange', 'setBaseHunger', 'setThirstChange', 'setEnduranceChange', 'setPainReduction',
                'setFluReduction', 'setFoodSicknessChange'},
            'zombie/inventory/InventoryItem': {'setAge', 'setOffAge', 'setOffAgeMax', 'setWeight', 'setActualWeight',
                'setCustomWeight', 'setName', 'setCustomName', 'setCooked', 'setFatigueChange',
                'setBoredomChange', 'setUnhappyChange', 'getConditionMax'},
            'zombie/iso/objects/IsoStove': {'Activated', 'getCurrentTemperature', 'isMicrowave'},
            'zombie/inventory/ItemContainer': {'Remove', 'AddItem', 'contains', 'isPowered', 'getItemById'},
        }
        for owner, methods in wanted.items():
            actual = {m.name.value for m in classes[owner].methods if m.access_flags.acc_public}
            assert methods <= actual, (owner, methods - actual)
        net = 'zombie/core/NetTimedAction'
        assert {'new', 'locvars', 'numParams'} <= set(constants(net, 'set'))
        # parse supplies netAction; it does not rebind the constructor's actor.
        assert 'netAction' in constants(net, 'parse')
        assert {'serverStart', 'setTimeData'} <= set(constants(net, 'start'))
        assert 'serverStop' in constants(net, 'stop')
        assert 'complete' in constants(net, 'perform')
        assert 'getDuration' in constants(net, 'getDuration')
        assert 'getServerTimeMills' in constants('zombie/core/Action', 'setTimeData')
        assert 'client' in constants('zombie/characters/CharacterTimedActions/LuaTimedActionNew', 'complete')
        assert 'getPlayerFromConnection' in constants('zombie/network/fields/character/PlayerID', 'parsePlayer')
        assert {'parse', 'getPlayer'} <= set(constants('zombie/network/PZNetKahluaTableImpl', 'load'))
        assert 'currentTimeMillis' in constants('zombie/Lua/LuaManager$GlobalObject', 'getTimestampMs')
    action = (game / 'media/lua/shared/ActionManager.lua').read_text(encoding='utf-8')
    assert action.index('inv:AddItem(item)') < action.index('sendAddItemToContainer(inv, item)')
    assert 'AddWorldInventoryItem(item,' in action
    all_items = '\n'.join((game / row['path']).read_text(encoding='utf-8') for row in report['game_files']
                          if row['path'].startswith('media/scripts/generated/items/'))
    for kind in report['vanilla_inputs']:
        assert re.search(r'\bitem\s+' + re.escape(kind.split('.')[1]) + r'\s*\{', all_items), kind
    print('PASS installed build, vanilla identities, exposed classes/public methods, server action construction/timing and native output synchronization')
    print('Static/offline only; native SP/dedicated NOT TESTED. G7/stable G8 BLOCKED.')


if __name__ == '__main__':
    main()
