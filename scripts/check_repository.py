"""Offline checks for source publication. Native/device tests are separate."""
from pathlib import Path
import hashlib, json, re, subprocess, tempfile, py_compile, xml.etree.ElementTree as ET
ROOT = Path(__file__).resolve().parents[1]
files = [Path(p) for p in subprocess.check_output(['git','ls-files'], cwd=ROOT, text=True).splitlines()]
for p in files:
 assert p.parts[0] not in {'build','downloads','dist','device-readback','upstream'}, f'Generated/private path tracked: {p}'
 assert p.name not in {'state.json','zlibrary-session.json','source.log','crash.log'}, f'Private data tracked: {p}'
 if p.suffix == '.py':
  with tempfile.TemporaryDirectory() as d:
   py_compile.compile(str(ROOT/p), cfile=str(Path(d)/'code.pyc'), doraise=True)
 if p.suffix == '.json': json.loads((ROOT/p).read_text())
 if p.suffix == '.svg': ET.parse(ROOT/p)
 if p.suffix in {'.md','.lua','.py','.sh','.yml','.json'}:
  text=(ROOT/p).read_text()
  secrets=[r'gh' + r'p_[A-Za-z0-9]{30,}', r'github_' + r'pat_[A-Za-z0-9_]{40,}', r'-----BEGIN '+r'(RSA |OPENSSH |EC )?PRIVATE KEY-----']
  assert not any(re.search(pattern,text) for pattern in secrets), f'Possible credential in {p}'
 if p.suffix == '.md':
  text=(ROOT/p).read_text()
  for link in re.findall(r'\]\(([^\s)]+)\)',text):
   if '://' in link or link.startswith(('#','mailto:')): continue
   target=link.split('#')[0]
   assert (ROOT/p.parent/target).exists(), f'Broken link in {p}: {target}'
for entry in json.loads((ROOT/'assets/sources/manifest.json').read_text()):
 p=ROOT/'assets/sources'/(entry['id']+'.aix')
 assert hashlib.sha256(p.read_bytes()).hexdigest()==entry['sha256'], f'Adapter hash mismatch: {p.name}'
assert '* @KapoorCommits' in (ROOT/'.github/CODEOWNERS').read_text()
assert 'GNU AFFERO GENERAL PUBLIC LICENSE' in (ROOT/'LICENSE').read_text()
print(f'PASS repository checks: {len(files)} tracked files; links, syntax, licenses, adapter hashes and publication boundaries')
