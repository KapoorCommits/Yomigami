from pathlib import Path
import tempfile,subprocess,os,shutil
r=Path(__file__).resolve().parents[1];package=r/'dist/yomigami-engine-v1.43.4'
for mode in ['success','checksum','copy-failure','swap-failure']:
 with tempfile.TemporaryDirectory() as d:
  p=Path(d);usb=p/'usb';root=usb/'yomigami';(root/'engine').mkdir(parents=True)
  old=root/'engine/server';old.write_bytes(b'old engine');old.chmod(0o755)
  (root/'data').mkdir();(root/'data/state.json').write_text('keep')
  here=usb/package.name;shutil.copytree(package,here)
  if mode=='checksum':(here/'server').write_bytes(b'bad')
  script=(here/'install.sh').read_text().replace('/mnt/us',str(usb)).replace('/var/tmp/yomigami.lock',str(p/'lock'))
  if mode=='copy-failure':script=script.replace('cp "$HERE/server" "$ROOT/engine/server.new"','false')
  if mode=='swap-failure':script=script.replace('mv "$ROOT/engine/server.new" "$ROOT/engine/server"','false')
  (here/'install.sh').write_text(script);bins=p/'bin';bins.mkdir();(bins/'eips').write_text('#!/bin/sh\nexit 0\n');(bins/'eips').chmod(0o755)
  result=subprocess.run(['sh',str(here/'install.sh')],env=dict(os.environ,PATH=str(bins)+':'+os.environ['PATH']))
  assert (result.returncode==0)==(mode=='success')
  assert old.read_bytes()==((package/'server').read_bytes() if mode=='success' else b'old engine')
  assert (root/'data/state.json').read_text()=='keep'
  if mode=='success':assert next(root.glob('.backup-engine-*/server')).read_bytes()==b'old engine'
 print('PASS engine installer',mode)
