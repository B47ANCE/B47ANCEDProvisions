"""Check current source contracts; optional installed-source/native inspection only."""
import argparse
import csv
import hashlib
import json
import re
from pathlib import Path
from zipfile import ZipFile
from io import BytesIO

ROOT = Path(__file__).resolve().parents[1]
LUA = ROOT / 'Contents/mods/B47ANCEDProvisions/42/media/lua'


def digest(data):
    return hashlib.sha256(data).hexdigest()


def profiles():
    source = (LUA / 'shared/foodWorks/FruitDryingProfiles.lua').read_text(encoding='utf-8')
    return ['Base.' + n for n in re.findall(r'"([A-Za-z][A-Za-z0-9]*)"', source.split('local known=')[0])]


def native_checks(archive):
    from jawa.cf import ClassFile

    def calls(member, name):
        cf = ClassFile(BytesIO(archive.read(member)))
        methods = [m for m in cf.methods if m.name.value == name]
        assert len(methods) == 1, (member, name)
        result = []
        for ins in methods[0].code.disassemble():
            if not ins.mnemonic.startswith(('invoke', 'getstatic')):
                continue
            for operand in ins.operands:
                if operand.op_type.name != 'CONSTANT_INDEX':
                    continue
                c = cf.constants.get(operand.value)
                if hasattr(c, 'class_') and hasattr(c, 'name_and_type'):
                    result.append((ins.pos, c.class_.name.value, c.name_and_type.name.value))
        return result

    recipe = calls('zombie/entity/components/crafting/recipe/CraftRecipeData.class', 'createOutputItems')
    flag = next(pos for pos, owner, name in recipe if name == 'InheritFood')
    stop = next(pos for pos, owner, name in recipe if pos > flag and name == 'InheritCooked')
    section = [name for pos, owner, name in recipe if flag < pos < stop]
    assert section == ['getFirstInputItemWithFlag', 'getIntAmount', 'copyFoodFromSplit'], section
    food = calls('zombie/inventory/types/Food.class', 'update')
    replace = next(pos for pos, owner, name in food if name == 'getReplaceOnCooked')
    add = next(pos for pos, owner, name in food if pos > replace and name == 'AddItem')
    remove = next(pos for pos, owner, name in food if pos > add and name == 'Remove')
    section = [name for pos, owner, name in food if add < pos < remove]
    assert 'copyConditionStatesFrom' in section and section.index('sendAddItemToContainer') < section.index('sendRemoveItemFromContainer')
    assert not any(name.startswith(('copyAge', 'copyNutrition', 'copyFood', 'setAge')) for name in section)
    print('PASS static native limitations: first-food inheritance; heat replacement lacks age/nutrition copying before publication')


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--game-root', type=Path)
    parser.add_argument('--steam-build')
    args = parser.parse_args()
    kinds = profiles()
    assert len(kinds) == len(set(kinds)) == 22
    assert not set(kinds) & {'Base.Watermelon', 'Base.Rosehips', 'Base.BerryPoisonIvy', 'Base.HollyBerry', 'Base.Beef'}
    translation = json.loads((LUA / 'shared/Translate/EN/UI.json').read_text(encoding='utf-8'))
    for kind in kinds:
        name = kind.split('.')[1]
        assert translation['UI_foodWorks_FruitDrying_Input_' + name]
        assert translation['UI_foodWorks_AppleDrying_DriedName' if name == 'Apple' else 'UI_foodWorks_FruitDrying_Dried_' + name]
    with (ROOT / 'docs/PRESERVATION_CATALOG.csv').open(encoding='utf-8', newline='') as f:
        rows = list(csv.DictReader(f))
    assert len(rows) == len({r['full_type'] for r in rows}) == 149
    assert set(kinds) <= {r['full_type'] for r in rows}
    implemented = {r['full_type'] for r in rows if r['implementation'].startswith('Implemented')}
    assert implemented == set(kinds)
    report = json.loads((ROOT / 'docs/PRESERVATION_EXPANSION_EVIDENCE.json').read_text(encoding='utf-8'))
    assert report['project_version'] == (ROOT / 'VERSION').read_text(encoding='utf-8').strip()
    assert report['runtime_status'] == 'NOT_TESTED'
    for entry in report['project_files']:
        assert digest((ROOT / entry['path']).read_bytes().replace(b'\r\n', b'\n')) == entry['sha256'], entry['path']
    print('PASS current profiles/localization, 149 unique vanilla catalog identities/statuses and project fingerprints')
    if not args.game_root:
        print('Installed game/native checks NOT RUN; supply --game-root and --steam-build')
        return
    assert args.steam_build == report['steam_build'] == '25485521'
    manifest = (args.game_root.parent.parent / 'appmanifest_108600.acf').read_text(encoding='utf-8')
    assert re.search(r'"buildid"\s+"' + args.steam_build + '"', manifest)
    for entry in report['game_files']:
        assert digest((args.game_root / entry['path']).read_bytes()) == entry['sha256'], entry['path']
    with ZipFile(args.game_root / 'projectzomboid.jar') as archive:
        for entry in report['native_classes']:
            data = archive.read(entry['member'])
            assert digest(data) == entry['sha256'], entry['member']
            loose = args.game_root / entry['member']
            if loose.exists():
                assert loose.read_bytes() == data, entry['member']
        native_checks(archive)
    s = (args.game_root / 'media/scripts/generated/items/food.txt').read_text(encoding='utf-8-sig')
    names = set(re.findall(r'^\s*item\s+(\w+)\s*\{', s, re.M))
    assert all(r['full_type'].startswith('Base.') and r['full_type'][5:] in names for r in rows)
    action = (args.game_root / 'media/lua/shared/Entity/TimedActions/ISHandcraftAction.lua').read_text(encoding='utf-8')
    body = action.split('function ISHandcraftAction:performRecipe()', 1)[1].split('\nfunction ', 1)[0]
    assert body.index('Actions.addOrDropItem') < body.index(':luaCallOnCreate') < body.index(':processDestroyAndUsedItems')
    print('PASS installed build/files/classes, all 149 vanilla identities and handcraft output-before-callback order')
    print('Offline/source only; native SP/dedicated NOT TESTED. G7 and stable G8 BLOCKED.')


if __name__ == '__main__':
    main()
