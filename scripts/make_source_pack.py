"""Build a sources-only update without changing reader settings or user books."""
from pathlib import Path
import base64, hashlib, json, tarfile, zipfile
r=Path(__file__).resolve().parents[1]
manifest=json.loads((r/'assets/sources/manifest.json').read_text())
assert len(manifest)==20 and len({x['id'] for x in manifest})==20
fingerprint=hashlib.sha256((r/'assets/sources/manifest.json').read_bytes()).hexdigest()[:12]
name=f'yomigami-sources-{fingerprint}.tar.gz';archive=r/'dist'/name
with tarfile.open(archive,'w:gz') as t:
 for entry in manifest:
  p=r/'assets/sources'/(entry['id']+'.aix');assert hashlib.sha256(p.read_bytes()).hexdigest()==entry['sha256'];t.add(p,arcname=p.name)
 t.add(r/'assets/sources/manifest.json',arcname='manifest.json')
digest=hashlib.sha256(archive.read_bytes()).hexdigest()
script='''#!/bin/sh
# Name: Add 20 English Sources
# Author: Yomigami contributors
# Icon: data:image/png;base64,__ICON__
# DontUseFBInk
set -eu
ROOT=/mnt/us/yomigami
ARCHIVE=/mnt/us/__ARCHIVE__
exec >>/mnt/us/yomigami-sources-update.log 2>&1
if [ ! -f "$ROOT/app/main.lua" ]; then eips 1 2 "Install Yomigami first."; exit 1; fi
if [ -d /var/tmp/yomigami.lock ]; then eips 1 2 "Close Yomigami before adding sources."; exit 1; fi
ACTUAL="$(sha256sum "$ARCHIVE" | awk '{print $1}')"
if [ "$ACTUAL" != '__SHA__' ]; then eips 1 2 "Sources update: checksum failed."; exit 1; fi
STAGE="$ROOT/.sources-stage.$$"
mkdir "$STAGE"
trap 'rm -rf "$STAGE"' EXIT HUP INT TERM
tar -xzf "$ARCHIVE" -C "$STAGE"
[ -s "$STAGE/manifest.json" ]
BACKUP="$ROOT/.sources-backup.__ID__.$$"
mkdir "$BACKUP"
mkdir -p "$ROOT/data/sources/sources"
cp -R "$ROOT/data/sources/sources" "$BACKUP/sources"
cp "$STAGE/"*.aix "$ROOT/data/sources/sources/"
cp "$STAGE/manifest.json" "$ROOT/data/sources/sources/manifest.json"
eips 1 2 "20 English sources added. Open Yomigami."
'''.replace('__ICON__',base64.b64encode((r/'assets/icon.png').read_bytes()).decode()).replace('__ARCHIVE__',name).replace('__SHA__',digest).replace('__ID__',fingerprint)
launcher=r/'dist/Add 20 English Sources.sh';launcher.write_text(script);launcher.chmod(0o755)
readme=f'''Yomigami — 20 English manga sources\n\nQuit Yomigami, then connect USB. Copy {name} to Kindle storage root.\nCopy documents/Add 20 English Sources.sh to the Kindle documents folder.\nDisconnect USB and open Add 20 English Sources. Then open Yomigami → Mangas.\n\nExisting books, reading settings and additional sources are kept. Previous adapters\nare backed up inside yomigami/.sources-backup.*. Site availability can change.\nSee SOURCES.md for exact versions and verification limits.\n'''
with zipfile.ZipFile(r/'dist/Yomigami-20-English-Sources.zip','w',zipfile.ZIP_DEFLATED) as z:
 z.write(archive,name);z.write(launcher,'documents/'+launcher.name);z.writestr('START_HERE.txt',readme)
 z.write(r/'docs/SOURCES.md','SOURCES.md');z.write(r/'THIRD_PARTY_NOTICES.md','THIRD_PARTY_NOTICES.md')
 for p in (r/'licenses').iterdir():
  if p.is_file():z.write(p,'licenses/'+p.name)
print('Source pack:',archive.name,'SHA256:',digest)
