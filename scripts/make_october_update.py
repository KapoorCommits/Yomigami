"""Combine the independently verified reader, engine and source updates behind one launcher."""
from pathlib import Path
import zipfile,base64,hashlib,json
r=Path(__file__).resolve().parents[1];version=json.loads((r/'runtime-lock.json').read_text())['source_engine_release']
files={};sources=None
for name in ['Yomigami-Reader-Update-20261011.zip',f'Yomigami-Manga-Engine-{version}.zip','Yomigami-Manga-Sources-20261011.zip']:
 with zipfile.ZipFile(r/'dist'/name) as z:
  for n in z.namelist():
   if n=='documents/Update Manga Sources.sh':sources=z.read(n)
   if n.startswith('documents/') or '/' not in n and not n.endswith('.tar.gz'):continue
   if n in files:assert files[n]==z.read(n)
   files[n]=z.read(n)
assert sources
folder='yomigami-october-20261011';files[folder+'/sources.sh']=sources
script=f'''#!/bin/sh
set -eu
if ! sh /mnt/us/yomigami-engine-{version}/install.sh; then eips 1 3 "Engine update failed. Previous engine preserved."; exit 1; fi
if ! sh /mnt/us/{folder}/sources.sh; then eips 1 3 "Source update failed. See source-update log."; exit 1; fi
exec sh /mnt/us/yomigami-reader-20261011/install.sh
'''
files[folder+'/install.sh']=script.encode()
launcher='#!/bin/sh\n# Name: Update Yomigami October\n# Author: Yomigami contributors\n# Icon: data:image/png;base64,'+base64.b64encode((r/'assets/icon.png').read_bytes()).decode()+'\n# DontUseFBInk\nexec sh /mnt/us/'+folder+'/install.sh\n'
files['documents/Update Yomigami October.sh']=launcher.encode()
files['START_HERE.txt']=b'Close Yomigami. Extract this ZIP on your computer and copy all its folders and the source tar.gz to Kindle storage. Eject USB and open Update Yomigami October from the Kindle library. This updates the private manga engine, sources and reader. Backups are kept inside yomigami. It does not modify Kindle Home or user books. Existing Yomigami and jailbroken Paperwhite 12 required. On-device validation pending.\n'
for name in ['docs/READER_GUIDE.md','docs/SOURCES.md','docs/UPSTREAM_REVIEW_20261011.md','THIRD_PARTY_NOTICES.md','LICENSE']:files[name]=(r/name).read_bytes()
files['SHA256SUMS.txt']=''.join(hashlib.sha256(data).hexdigest()+'  '+name+'\n' for name,data in sorted(files.items())).encode()
out=r/'dist/Yomigami-October-20261011.zip'
with zipfile.ZipFile(out,'w',zipfile.ZIP_DEFLATED) as z:
 for name,data in sorted(files.items()):z.writestr(name,data)
print(out,hashlib.sha256(out.read_bytes()).hexdigest())
