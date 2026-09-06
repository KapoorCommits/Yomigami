"""Fetch checksum-pinned upstream binary inputs for a local Kindle build."""
from pathlib import Path
import argparse, hashlib, json, os, shutil, stat, subprocess, sys, urllib.request, zipfile
ROOT = Path(__file__).resolve().parents[1]
LOCK = json.loads((ROOT / 'runtime-lock.json').read_text())
p = argparse.ArgumentParser(description=__doc__)
p.add_argument('--macos-engine', action='store_true', help='Also fetch the optional macOS source engine')
a = p.parse_args()
inputs = [
 ('koreader-kindlehf-v2026.07.1.zip', 'https://github.com/koreader/koreader/releases/download/v2026.07.1/koreader-kindlehf-v2026.07.1.zip', 'build/kindle', 'koreader'),
 ('rakuyomi-kindlehf-v1.41.6.zip', 'https://github.com/tachibana-shin/rakuyomi/releases/download/v1.41.6/rakuyomi-kindlehf.zip', 'build/source-kindle', 'rakuyomi.koplugin'),
]
if a.macos_engine:
 inputs.append(('rakuyomi-macos-v1.41.6.zip', 'https://github.com/tachibana-shin/rakuyomi/releases/download/v1.41.6/rakuyomi-macos.zip', 'build/source-macos', 'rakuyomi.koplugin'))
(ROOT / 'downloads').mkdir(exist_ok=True)
for name, url, folder, sentinel in inputs:
 archive = ROOT / 'downloads' / name
 expected = LOCK['inputs'][name]
 if not archive.exists():
  part = archive.with_suffix('.part')
  try:
   with urllib.request.urlopen(url, timeout=120) as src, part.open('wb') as out:
    shutil.copyfileobj(src, out)
   assert hashlib.sha256(part.read_bytes()).hexdigest() == expected, 'Checksum mismatch: ' + name
   part.rename(archive)
  finally:
   part.unlink(missing_ok=True)
 assert hashlib.sha256(archive.read_bytes()).hexdigest() == expected, 'Checksum mismatch: ' + name
 dest = ROOT / folder
 if (dest / sentinel).exists():
  print('Verified archive; preserving existing runtime:', folder)
  continue
 dest.mkdir(parents=True, exist_ok=True)
 with zipfile.ZipFile(archive) as z:
  for entry in z.infolist():
   target = dest / entry.filename
   assert target.resolve().is_relative_to(dest.resolve()), 'Archive path escapes destination'
   mode = entry.external_attr >> 16
   if stat.S_ISLNK(mode):
    target.parent.mkdir(parents=True, exist_ok=True)
    link = z.read(entry).decode()
    assert (target.parent / link).resolve().is_relative_to(dest.resolve()), 'External archive symlink'
    target.symlink_to(link)
   else:
    z.extract(entry, dest)
    if mode & 0o777:
     target.chmod(mode & 0o777)
 print('Prepared:', folder)
env = dict(os.environ, YOMIGAMI_HOME=str(ROOT / 'build/package-fixtures'))
subprocess.run([sys.executable, str(ROOT / 'scripts/make_fixtures.py')], env=env, check=True)
print('Ready: python3 scripts/package.py && python3 scripts/make_installer.py')
