"""Read-only icon alpha, thumbnail preservation and source provenance checks."""
import hashlib
import json
from pathlib import Path
from PIL import Image

ROOT = Path(__file__).resolve().parents[1]
SOURCE = ROOT / 'Contents/mods/B47ANCEDProvisions'


def main():
    record = json.loads((ROOT / 'assets/branding/icon-provenance.json').read_text(encoding='utf-8'))
    for name in ['preview.png', 'Contents/mods/B47ANCEDProvisions/thumbnail.png']:
        assert hashlib.sha256((ROOT / name).read_bytes()).hexdigest() == record['thumbnail_sha256']
    for name, expected in record['files'].items():
        data = (ROOT / name).read_bytes()
        if Path(name).suffix != '.png':
            data = data.replace(b'\r\n', b'\n')
        assert hashlib.sha256(data).hexdigest() == expected, name
    with Image.open(SOURCE / '42/icon.png') as im:
        assert im.size == (64, 64) and im.mode == 'RGBA'
        alpha = im.getchannel('A')
        assert alpha.getextrema() == (0, 255) and alpha.histogram()[0] > 64 * 64 / 4
        assert alpha.getpixel((0, 0)) == 0
    assert 'icon=icon.png' in (SOURCE / '42/mod.info').read_text(encoding='utf-8')
    print('PASS 64x64 RGBA icon, true alpha, approved master/export fingerprints and unchanged thumbnail bytes')


if __name__ == '__main__':
    main()
