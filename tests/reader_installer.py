from pathlib import Path
import os,subprocess,tempfile,shutil
r=Path(__file__).resolve().parents[1];package=r/'dist/yomigami-highlights-20261004'
assert (package/'Update Yomigami Highlights.sh').stat().st_size<100000
assert (package/'Yomigami.sh').stat().st_size<100000
for mode in ['success','bad-checksum','syntax-failure','swap-failure','cover-failure']:
 with tempfile.TemporaryDirectory() as d:
  tmp=Path(d);usb=tmp/'usb';root=usb/'yomigami';here=usb/package.name
  (root/'app').mkdir(parents=True);(root/'app/main.lua').write_text('original reader')
  (root/'data/library').mkdir(parents=True);(root/'data/library/original.pdf').write_text('original book');(root/'data/state.json').write_text('{"progress":{"sample":17}}')
  (root/'runtime').mkdir();lua=root/'runtime/luajit';lua.write_text('#!/bin/sh\nexit '+('1' if mode=='syntax-failure' else '0')+'\n');lua.chmod(0o755)
  launch=root/'launch.sh';launch.write_text('#!/bin/sh\nprintf started > "'+str(tmp/'started')+'"\n');launch.chmod(0o755)
  doc=usb/'documents';(doc/'Yomigami.sh.sdr').mkdir(parents=True)
  art=[root/'icon.png',doc/'Yomigami.sh',doc/'Yomigami.sh.sdr/icon.png']
  for path in art:path.write_text('original '+path.name)
  shutil.copytree(package,here)
  if mode=='bad-checksum':(here/'payload.tar.gz').write_bytes(b'broken')
  script=(here/'install.sh').read_text().replace('/mnt/us',str(usb)).replace('/var/tmp/yomigami.lock',str(tmp/'lock'))
  if mode=='swap-failure':script=script.replace('mv "$STAGE/app" "$ROOT/app"','false')
  if mode=='cover-failure':script=script.replace("printf '%s\\n'", "false\n"+"printf '%s\\n'")
  (here/'install.sh').write_text(script)
  bins=tmp/'bin';bins.mkdir();eips=bins/'eips';eips.write_text('#!/bin/sh\nexit 0\n');eips.chmod(0o755)
  result=subprocess.run(['sh',str(here/'install.sh')],env=dict(os.environ,PATH=str(bins)+':'+os.environ['PATH']))
  assert (result.returncode==0)==(mode=='success'),mode+' '+(root/'reader-update.log').read_text()
  assert (root/'data/state.json').read_text()=='{"progress":{"sample":17}}'
  assert (root/'data/library/original.pdf').read_text()=='original book'
  if mode=='success':
   assert (root/'icon.png').read_bytes()==(r/'assets/icon.png').read_bytes()
   assert (doc/'Yomigami.sh.sdr/icon.png').read_bytes()==(r/'assets/icon.png').read_bytes()
   assert '# Icon: data:image/png;base64,' in (doc/'Yomigami.sh').read_text()
   assert (root/'app/annotations.lua').exists() and (tmp/'started').exists()
   assert next(root.glob('.backup-reader-*/app/main.lua')).read_text()=='original reader'
  else:
   assert (root/'app/main.lua').read_text()=='original reader'
   for path in art:assert path.read_text()=='original '+path.name
 print('PASS installer '+mode)
