"""Build the October reader update. Does not patch Kindle firmware or user state."""
from pathlib import Path
import hashlib, tarfile, base64, zipfile, subprocess
r=Path(__file__).resolve().parents[1]
name='yomigami-reader-october-20261002';out=r/'dist'/name;out.mkdir(parents=True,exist_ok=True)
files=sorted((r/'app').glob('*.lua'))
subprocess.run(['sips','-Z','180',str(r/'assets/icon.png'),'--out',str(out/'launcher-icon.png')],check=True,stdout=subprocess.DEVNULL)
icon=(out/'launcher-icon.png').read_bytes()
assert len(icon)<60000, 'Launcher artwork must fit Kindle scanner cache'
canonical=(r/'launcher/Yomigami.sh').read_text().replace('# Icon: /mnt/us/yomigami/icon.png','# Icon: data:image/png;base64,'+base64.b64encode(icon).decode())
(out/'Yomigami.sh').write_text(canonical)
entries=[(file,'app/'+file.name) for file in files]+[(r/'assets/icon.png','icon.png'),(out/'Yomigami.sh','Yomigami.sh')]
with tarfile.open(out/'payload.tar.gz','w:gz') as archive:
    for file,name_in_tar in entries:archive.add(file,arcname=name_in_tar)
digest=hashlib.sha256((out/'payload.tar.gz').read_bytes()).hexdigest()
checks='\n'.join(hashlib.sha256(file.read_bytes()).hexdigest()+'  '+name_in_tar for file,name_in_tar in entries)
script=r'''#!/bin/sh
set -eu
ROOT=/mnt/us/yomigami
HERE=/mnt/us/__NAME__
exec >>"$ROOT/reader-update.log" 2>&1
fail() { eips 1 3 "$1"; exit 1; }
[ -f "$ROOT/app/main.lua" ] || fail "Install Yomigami first."
PID="$(cat /var/tmp/yomigami.lock/pid 2>/dev/null || true)"
case "$PID" in ''|*[!0-9]*) ;; *)
 if kill -0 "$PID" 2>/dev/null && tr '\000' ' ' <"/proc/$PID/cmdline" | grep -q "$ROOT/launch.sh"; then fail "Close Yomigami before updating."; fi;; esac
[ "$(sha256sum "$HERE/payload.tar.gz" | awk '{print $1}')" = '__DIGEST__' ] || fail "Update checksum failed."
STAGE="$ROOT/.reader-stage.$$"
BACKUP="$ROOT/.backup-reader-$(date +%Y%m%d-%H%M%S)-$$"
mkdir "$STAGE"
SWAPPED=0
ART_READY=0
DOC=/mnt/us/documents
restore_art() {
 for pair in "icon.png:$ROOT/icon.png" "Yomigami.sh:$DOC/Yomigami.sh" "cache.png:$DOC/Yomigami.sh.sdr/icon.png"; do
  key=${pair%%:*}; dest=${pair#*:}
  if [ -f "$BACKUP/$key" ]; then cp -p "$BACKUP/$key" "$dest"; else rm -f "$dest"; fi
 done
}
rollback() {
 code=$?
 if [ "$code" -ne 0 ]; then
  if [ "$SWAPPED" = 1 ]; then
   [ ! -d "$ROOT/app" ] || mv "$ROOT/app" "$STAGE/failed-app"
   mv "$BACKUP/app" "$ROOT/app"
  fi
  if [ "$ART_READY" = 1 ]; then restore_art; fi
  sync
  eips 1 3 "Update failed. Previous reader preserved."
 fi
}
trap rollback EXIT
trap 'exit 1' HUP INT TERM
tar -xzf "$HERE/payload.tar.gz" -C "$STAGE"
cd "$STAGE"
sha256sum -c - <<'CHECKSUMS'
__CHECKS__
CHECKSUMS
cd "$ROOT/runtime"
for file in "$STAGE/app/"*.lua; do
 YOMIGAMI_CHECK_FILE="$file" ./luajit -e 'assert(loadfile(os.getenv("YOMIGAMI_CHECK_FILE")))'
done
mkdir "$BACKUP"
mkdir -p "$DOC/Yomigami.sh.sdr"
for pair in "icon.png:$ROOT/icon.png" "Yomigami.sh:$DOC/Yomigami.sh" "cache.png:$DOC/Yomigami.sh.sdr/icon.png"; do
 key=${pair%%:*}; dest=${pair#*:}
 [ ! -f "$dest" ] || cp -p "$dest" "$BACKUP/$key"
done
sync
ART_READY=1
mv "$ROOT/app" "$BACKUP/app"
SWAPPED=1
mv "$STAGE/app" "$ROOT/app"
cp "$STAGE/icon.png" "$ROOT/icon.png.new"
mv "$ROOT/icon.png.new" "$ROOT/icon.png"
cp "$STAGE/Yomigami.sh" "$DOC/Yomigami.sh.new"
chmod 755 "$DOC/Yomigami.sh.new"
mv "$DOC/Yomigami.sh.new" "$DOC/Yomigami.sh"
cp "$STAGE/icon.png" "$DOC/Yomigami.sh.sdr/icon.png.new"
mv "$DOC/Yomigami.sh.sdr/icon.png.new" "$DOC/Yomigami.sh.sdr/icon.png"
sync
printf '%s\n' "Reader update installed. Backup: $BACKUP"
trap - EXIT HUP INT TERM
# Reopen Library and wake the existing navigation helper after USB indexing.
# No firmware bundle or Home preferences are replaced here.
if [ -f "$ROOT/home/enabled" ]; then
 start yomigami-library-watch 2>/dev/null || true
fi
lipc-set-prop com.lab126.appmgrd start 'app://com.lab126.KPPMainApp?view=KPP_LIBRARY' 2>/dev/null || true
eips 1 3 "Reader update installed. Opening Yomigami..."
exec "$ROOT/launch.sh" --kual --asap
'''.replace('__NAME__',name).replace('__DIGEST__',digest).replace('__CHECKS__',checks)
(out/'install.sh').write_text(script)
launcher='# !/bin/sh'.replace('# !','#!')+'\n# Name: Update Yomigami Reader\n# Author: Yomigami contributors\n# Icon: data:image/png;base64,'+base64.b64encode(icon).decode()+'\n# DontUseFBInk\nexec sh /mnt/us/'+name+'/install.sh\n'
(out/'Update Yomigami Reader.sh').write_text(launcher)
with zipfile.ZipFile(r/'dist/Yomigami-October-Reader-Update.zip','w',zipfile.ZIP_DEFLATED) as z:
    z.write(out/'payload.tar.gz',name+'/payload.tar.gz');z.write(out/'install.sh',name+'/install.sh')
    z.writestr('documents/Update Yomigami Reader.sh',launcher)
    z.writestr('START_HERE.txt','Existing Yomigami installation required. Copy both extracted folders to Kindle storage, close Yomigami, unplug USB, and open Update Yomigami Reader in the Kindle library. KUAL is not required. App files, launcher and cover are backed up before replacement. User books/state and native Home are untouched. This is a development build, not hardware-verified. Sources are distributed separately.\n')
print(out);print('Payload SHA256:',digest)
