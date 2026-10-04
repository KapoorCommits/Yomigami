"""Exercise the real source installer in a temporary Kindle-shaped directory."""
from pathlib import Path
import json,subprocess,tempfile,shutil,os
r=Path(__file__).resolve().parents[1]
manifest=json.loads((r/'assets/sources/manifest.json').read_text())
assert len(manifest)==20 and all('en' in s['languages'] for s in manifest)
assert {'en.weebcentral','multi.mangadex'} <= {s['id'] for s in manifest}
script=(r/'dist/Add 20 English Sources.sh').read_text()
with tempfile.TemporaryDirectory() as d:
 usb=Path(d)/'usb';root=usb/'yomigami';(root/'app').mkdir(parents=True);(root/'app/main.lua').write_text('original app')
 sources=root/'data/sources/sources';sources.mkdir(parents=True);(sources/'custom.aix').write_bytes(b'keep custom')
 state=root/'data/state.json';state.write_text('{"bookmark":17}')
 settings=root/'data/sources/settings.json';settings.write_text('{"languages":["en"]}')
 library=root/'data/library';library.mkdir();(library/'original.pdf').write_bytes(b'original book')
 p=Path(d)/'install.sh';p.write_text(script.replace('/mnt/us',str(usb)).replace('/var/tmp/yomigami.lock',str(Path(d)/'lock')))
 binpath=Path(d)/'bin';binpath.mkdir();eips=binpath/'eips';eips.write_text('#!/bin/sh\nexit 0\n');eips.chmod(0o755)
 env=dict(os.environ,PATH=str(binpath)+':'+os.environ['PATH'])
 archive_name=next(line.split('/')[-1] for line in script.splitlines() if line.startswith('ARCHIVE='))
 (usb/archive_name).write_bytes(b'bad');assert subprocess.run(['sh',str(p)],env=env).returncode!=0
 assert list(sources.iterdir())==[sources/'custom.aix']
 shutil.copyfile(r/'dist'/archive_name,usb/archive_name)
 for _ in range(2):subprocess.run(['sh',str(p)],env=env,check=True)
 assert len(list(sources.glob('*.aix')))==21
 for entry in manifest:assert (sources/(entry['id']+'.aix')).read_bytes()==(r/'assets/sources'/(entry['id']+'.aix')).read_bytes()
 assert (sources/'custom.aix').read_bytes()==b'keep custom'
 assert state.read_text()=='{"bookmark":17}' and settings.read_text()=='{"languages":["en"]}'
 assert (library/'original.pdf').read_bytes()==b'original book'
 assert len(list(root.glob('.sources-backup.*')))==2 and not list(root.glob('.sources-stage.*'))
 print('PASS 20 English adapters; checksum rejection, repeat install, backup, custom-source/book/settings preservation')
