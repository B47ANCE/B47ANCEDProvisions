"""Exercise real ZIP corruption/inventory boundaries without game execution."""
import importlib.util
from pathlib import Path
import tempfile
import unittest
import warnings
from zipfile import ZipFile

spec = importlib.util.spec_from_file_location('workshop_package', Path(__file__).parents[1] / 'scripts/workshop_package.py')
package = importlib.util.module_from_spec(spec)
spec.loader.exec_module(package)


class PackageIntegrity(unittest.TestCase):
    def test_clean_archive(self):
        with tempfile.TemporaryDirectory() as folder:
            p = Path(folder) / 'test.zip'
            expected = {'VERSION': b'fixture\n', 'Contents/mods/Test/42/mod.info': b'id=Test\n'}
            with ZipFile(p, 'w') as archive:
                for name, data in expected.items():
                    archive.writestr(name, data)
            package.audit_archive(p, expected)

    def test_unsafe_paths(self):
        for name in ['../outside', '/absolute', 'C:/drive', 'a\\b', 'a/./b', 'a//b', 'a/../b']:
            with self.subTest(name=name), self.assertRaises(AssertionError):
                package.safe(name)

    def test_tampered_inventory(self):
        for members in [[('VERSION', b'changed')], [('VERSION', b'expected'), ('extra', b'junk')],
                        [('VERSION', b'expected'), ('version', b'collision')],
                        [('VERSION', b'expected'), ('VERSION', b'duplicate')],
                        [('VERSION', b'expected'), ('../outside', b'unsafe')]]:
            with self.subTest(members=members), tempfile.TemporaryDirectory() as folder:
                p = Path(folder) / 'test.zip'
                with warnings.catch_warnings():
                    warnings.simplefilter('ignore', UserWarning)
                    with ZipFile(p, 'w') as archive:
                        for name, data in members:
                            archive.writestr(name, data)
                with self.assertRaises(AssertionError):
                    package.audit_archive(p, {'VERSION': b'expected'})

    def test_vdf_preserves_fields_and_paragraphs(self):
        value = package.make_vdf(Path('stage'), 'Title', 'One\n\nTwo "quoted"', 'Test upload')
        self.assertNotIn('previewfile', value)
        self.assertNotIn('visibility', value)
        self.assertIn('One\n\nTwo \\"quoted\\"', value)
        self.assertIn('"publishedfileid" "3788591331"', value)


if __name__ == '__main__':
    unittest.main()
