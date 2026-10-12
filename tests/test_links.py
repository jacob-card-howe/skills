"""Run with: python3 -m unittest discover -s tests"""
import os
from pathlib import Path
import shutil
import subprocess
import tempfile
import unittest


class LinkSkillsTest(unittest.TestCase):
    def test_backups_links_and_repeat_runs(self):
        with tempfile.TemporaryDirectory() as temp:
            root = Path(temp)
            repo = root / 'repo with spaces'
            repo.mkdir()
            shutil.copy2(Path(__file__).resolve().parents[1] / 'link-skills.sh', repo)
            for name in ('alpha', 'beta'):
                skill = repo / 'skills' / name
                skill.mkdir(parents=True)
                (skill / 'SKILL.md').write_text(f'---\nname: {name}\n---\n')
            home = root / 'home'
            pi = home / '.pi' / 'agent'
            claude = home / '.claude'
            original = pi / 'skills' / 'alpha'
            original.mkdir(parents=True)
            (original / 'keep.txt').write_text('original')
            (pi / 'skills' / 'beta').symlink_to(root / 'missing')
            synced = claude / 'skills' / 'synced' / 'keep.txt'
            synced.parent.mkdir(parents=True)
            synced.write_text('synced')
            env = dict(os.environ, HOME=str(home))

            def run():
                return subprocess.run(['bash', str(repo / 'link-skills.sh')],
                                      env=env, capture_output=True, text=True)

            first = run()
            self.assertEqual(first.returncode, 0, first.stderr)
            for agent in (pi, claude):
                for name in ('alpha', 'beta'):
                    link = agent / 'skills' / name
                    self.assertTrue(link.is_symlink())
                    self.assertEqual(link.resolve(), (repo / 'skills' / name).resolve())
            backups = list(pi.glob('skills-backup.*'))
            self.assertEqual(len(backups), 1)
            self.assertEqual((backups[0] / 'alpha' / 'keep.txt').read_text(), 'original')
            self.assertTrue((backups[0] / 'beta').is_symlink())
            self.assertEqual(synced.read_text(), 'synced')
            second = run()
            self.assertEqual(second.returncode, 0, second.stderr)
            self.assertEqual(second.stdout, '')
            self.assertEqual(list(pi.glob('skills-backup.*')), backups)

            (repo / 'skills' / 'invalid').mkdir()
            invalid = run()
            self.assertNotEqual(invalid.returncode, 0)
            self.assertIn('Missing SKILL.md', invalid.stderr)
            self.assertFalse((pi / 'skills' / 'invalid').exists())
