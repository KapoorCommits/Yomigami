from pathlib import Path
import hashlib,tarfile,base64,json
r=Path(__file__).resolve().parents[1]
version='0.5.0'
archive=r/f'dist/yomigami-update-{version}.tar.gz'
icon=base64.b64encode((r/'assets/icon.png').read_bytes()).decode()
launcher=(r/'launcher/Yomigami.sh').read_text().replace('# Icon: /mnt/us/yomigami/icon.png','# Icon: data:image/png;base64,'+icon)
(r/'build/Yomigami.sh').write_text(launcher)
with tarfile.open(archive,'w:gz') as t:
    t.add(r/'assets/icon.png',arcname='icon.png');t.add(r/'build/Yomigami.sh',arcname='Yomigami.sh')
    t.add(r/'app',arcname='app');t.add(r/'assets/sources',arcname='sources')
    t.add(r/'scripts/upgrade_data.lua',arcname='upgrade_data.lua')
digest=hashlib.sha256(archive.read_bytes()).hexdigest()
icon=base64.b64encode((r/'assets/icon.png').read_bytes()).decode()
script='''#!/bin/sh
# Name: Update Yomigami 0.5.0
# Author: Yomigami contributors
# Icon: data:image/png;base64,__ICON__
# DontUseFBInk
set -eu
ROOT=/mnt/us/yomigami
ARCHIVE=/mnt/us/yomigami-update-0.5.0.tar.gz
exec >>/mnt/us/yomigami-update.log 2>&1
if [ ! -f "$ROOT/app/main.lua" ]; then eips 1 2 "Install Yomigami first."; exit 1; fi
if [ -d /var/tmp/yomigami.lock ]; then eips 1 2 "Close Yomigami before updating."; exit 1; fi
if [ "$(cat "$ROOT/app/version.txt" 2>/dev/null || true)" = '0.5.0-alpha' ]; then exec "$ROOT/launch.sh" --kual --asap; fi
ACTUAL="$(sha256sum "$ARCHIVE" | awk '{print $1}')"
if [ "$ACTUAL" != "__SHA__" ]; then eips 1 2 "Yomigami update: checksum failed."; exit 1; fi
STAGE="$ROOT/.update-0.5.0.$$"
mkdir "$STAGE"
tar -xzf "$ARCHIVE" -C "$STAGE"
[ -s "$STAGE/app/main.lua" ]
BACKUP="$ROOT/.backup-before-0.5.0.$$"
mkdir "$BACKUP"
cp -R "$ROOT/app" "$BACKUP/app"
if [ -f /mnt/us/documents/Yomigami.sh ]; then cp /mnt/us/documents/Yomigami.sh "$BACKUP/Yomigami.sh"; fi
cp "$ROOT/icon.png" "$BACKUP/icon.png"
if [ -d "$ROOT/data/sources/sources" ]; then cp -R "$ROOT/data/sources/sources" "$BACKUP/sources"; fi
if [ -f "$ROOT/data/sources/settings.json" ]; then cp "$ROOT/data/sources/settings.json" "$BACKUP/settings.json"; fi
if [ -f "$ROOT/data/state.json" ]; then cp "$ROOT/data/state.json" "$BACKUP/state.json"; fi
cd "$ROOT/runtime"
./luajit "$STAGE/upgrade_data.lua" "$ROOT" "$STAGE"
mkdir -p "$ROOT/data/sources/sources"
cp "$STAGE/sources/"*.aix "$ROOT/data/sources/sources/"
mv "$STAGE/settings.json" "$ROOT/data/sources/settings.json"
mv "$STAGE/state.json" "$ROOT/data/state.json"
mv "$ROOT/app" "$STAGE/previous-app"
mv "$STAGE/app" "$ROOT/app"
mv "$STAGE/icon.png" "$ROOT/icon.png"
chmod +x "$STAGE/Yomigami.sh"
mv "$STAGE/Yomigami.sh" /mnt/us/documents/Yomigami.sh
printf '%s\\n' '0.5.0-alpha' >"$ROOT/app/version.txt"
echo "Yomigami 0.5.0 installed. Backup: $BACKUP"
exec "$ROOT/launch.sh" --kual --asap
'''.replace('__ICON__',icon).replace('__SHA__',digest)
p=r/'dist/Update Yomigami 0.5.0.sh';p.write_text(script);p.chmod(0o755)
print('Update archive',archive.stat().st_size,'bytes; SHA256',digest)
