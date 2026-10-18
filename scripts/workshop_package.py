"""Build/verify a source-bound Workshop test package. Never uploads or deletes files."""
import argparse
import hashlib
import json
from pathlib import Path, PurePosixPath
import re
import subprocess
from zipfile import ZipFile, ZipInfo, ZIP_DEFLATED

ROOT = Path(__file__).resolve().parents[1]
MOD = 'Contents/mods/B47ANCEDProvisions/'
THUMBNAIL = 'e5331f185067436ec530f6464dfe14600eeb41d4ea0458335013701d14a26ea3'
NOTICE = 'MP testing build - dedicated multiplayer NOT TESTED'
EXTRA = ['VERSION', 'preview.png', 'workshop.txt', 'WORKSHOP_DESCRIPTION.txt', 'WORKSHOP_CHANGE_NOTE.txt']


def sha(data):
    return hashlib.sha256(data).hexdigest()


def git(*args):
    return subprocess.check_output(['git', '-C', str(ROOT), *args])


def safe(name):
    p = PurePosixPath(name)
    assert name and '\\' not in name and ':' not in name and not p.is_absolute()
    assert all(part not in ('', '.', '..') for part in name.split('/'))
    return p


def source():
    assert not git('status', '--porcelain=v1').strip(), 'Commit intended source before packaging'
    commit = git('rev-parse', 'HEAD').decode().strip()
    paths = git('ls-files', '-z').decode().split('\0')
    selected = sorted(p for p in paths if p.startswith(MOD) or p in EXTRA)
    assert set(EXTRA) <= set(selected)
    assert len(selected) == len({p.casefold() for p in selected})
    data = {}
    for name in selected:
        safe(name)
        if name.startswith(MOD):
            assert Path(name).suffix.lower() in {'.lua', '.json', '.txt', '.info', '.png'}, name
        data[name] = git('show', 'HEAD:' + name)
    version = data['VERSION'].decode().strip()
    info = dict(line.split('=', 1) for line in data[MOD + '42/mod.info'].decode().splitlines() if '=' in line)
    assert info['id'] == 'B47ANCEDProvisions' and info['modversion'] == version
    assert (ROOT / 'WORKSHOP_ID.txt').read_text(encoding='utf-8').strip() == '3788591331'
    assert sha(data['preview.png']) == sha(data[MOD + 'thumbnail.png']) == THUMBNAIL
    description = data['WORKSHOP_DESCRIPTION.txt'].decode().strip()
    changelog = data['WORKSHOP_CHANGE_NOTE.txt'].decode()
    note = re.split(r'\n\[b\]Version ', changelog, maxsplit=1)[0].strip()
    for text in [description, note]:
        assert NOTICE in text and '\\n' not in text and not re.search(r'\bTODO\b', text)
    assert f'[b]Version {version}[/b]' in note
    assert 'https://github.com/B47ANCE/B47ANCEDProvisions' in description
    workshop = data['workshop.txt'].decode().splitlines()
    assert 'id=3788591331' in workshop
    assert '\n'.join(line[12:] for line in workshop if line.startswith('description=')) == description
    title = next(line[6:] for line in workshop if line.startswith('title='))
    status = json.loads(git('show', 'HEAD:docs/RELEASE_STATUS.json'))
    assert status['project_version'] == version and status['offline'] == 'PASS'
    assert status['dedicated'] == 'NOT_TESTED' and status['stable_g8'] == 'BLOCKED'
    provenance = {'schema': 1, 'version': version, 'commit': commit, 'mod_id': info['id'],
        'workshop_id': '3788591331', 'steam_app': '108600', 'game_version': '42.21',
        'steam_build': '25485521', 'validation': status,
        'files': {name: sha(content) for name, content in data.items()}}
    data['SOURCE.json'] = (json.dumps(provenance, indent=2) + '\n').encode()
    return data, provenance, title, description, note


def escape(text):
    # Real paragraph breaks are retained; only VDF quote/backslash escaping is applied.
    return text.replace('\\', '\\\\').replace('"', '\\"')


def make_vdf(stage, title, description, note):
    fields = {'appid': '108600', 'publishedfileid': '3788591331',
        'contentfolder': str((stage / 'Contents').resolve()), 'title': title,
        'description': description, 'changenote': note}
    return '"workshopitem"\n{\n' + ''.join(f'    "{key}" "{escape(value)}"\n' for key, value in fields.items()) + '}\n'


def audit_archive(path, expected):
    with ZipFile(path) as archive:
        names = archive.namelist()
        assert len(names) == len(set(names)) == len({n.casefold() for n in names})
        for name in names:
            safe(name)
        assert set(names) == set(expected), 'Unexpected or missing package members'
        assert archive.testzip() is None, 'CRC failure'
        for name, content in expected.items():
            assert archive.read(name) == content, 'Package/source mismatch: ' + name


def verify(directory):
    data, provenance, title, description, note = source()
    record = json.loads((directory / 'release-provenance.json').read_text(encoding='utf-8'))
    assert record['package'] == f'B47ANCEDProvisions-{provenance["version"]}-workshop-ready.zip'
    archive = directory / record['package']
    assert record['commit'] == provenance['commit'] and record['version'] == provenance['version']
    assert record['workshop_id'] == '3788591331' and record['mod_id'] == 'B47ANCEDProvisions'
    assert record['steam_app'] == '108600' and record['steam_build'] == '25485521'
    assert record['validation'] == provenance['validation']
    assert record['package_sha256'] == sha(archive.read_bytes())
    audit_archive(archive, data)
    stage = directory / 'stage'
    actual = {p.relative_to(stage).as_posix() for p in stage.rglob('*') if p.is_file()}
    assert actual == set(data), 'Unexpected or missing staged file'
    for name, content in data.items():
        assert (stage / name).read_bytes() == content, 'Staging/source mismatch: ' + name
    assert (directory / 'workshop.vdf').read_text(encoding='utf-8') == make_vdf(stage, title, description, note)
    print('PASS exact source/commit/version, native Lua-only payload, stage/ZIP parity, paths/case/CRC/SHA-256 and VDF canonical text')
    print('PASS thumbnail unchanged; VDF omits preview/visibility updates; G7/stable G8 remain BLOCKED')
    return record


def build(directory):
    data, provenance, title, description, note = source()
    # Refuse replacement: old packages/staging/provenance are recovery evidence.
    assert not directory.exists(), 'Output already exists; choose a new empty artifact directory'
    directory.mkdir(parents=True)
    stage = directory / 'stage'
    for name, content in data.items():
        target = stage / name
        target.parent.mkdir(parents=True, exist_ok=True)
        with target.open('xb') as stream:
            stream.write(content)
    name = f'B47ANCEDProvisions-{provenance["version"]}-workshop-ready.zip'
    with ZipFile(directory / name, 'x', compression=ZIP_DEFLATED) as archive:
        for path, content in sorted(data.items()):
            entry = ZipInfo(path, (2026, 1, 1, 0, 0, 0))
            entry.compress_type = ZIP_DEFLATED
            entry.external_attr = 0o100644 << 16
            archive.writestr(entry, content)
    record = dict(provenance, package=name, package_sha256=sha((directory / name).read_bytes()))
    (directory / 'release-provenance.json').write_text(json.dumps(record, indent=2) + '\n', encoding='utf-8')
    (directory / 'workshop.vdf').write_text(make_vdf(stage, title, description, note), encoding='utf-8', newline='\n')
    verify(directory)
    print('Prepared package and upload metadata; SteamCMD was not invoked: ' + str(directory))


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    group = parser.add_mutually_exclusive_group(required=True)
    group.add_argument('--build', type=Path)
    group.add_argument('--verify', type=Path)
    options = parser.parse_args()
    if options.build:
        build(options.build.resolve())
    else:
        verify(options.verify.resolve())
