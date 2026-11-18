"""Package the pinned official manga engine for existing KindleHF installations."""
from pathlib import Path
import base64,hashlib,json,zipfile
r=Path(__file__).resolve().parents[1]
lock=json.loads((r/'runtime-lock.json').read_text());version=lock['source_engine_release']
archive=r/'downloads'/f'rakuyomi-kindlehf-{version}.zip'
assert hashlib.sha256(archive.read_bytes()).hexdigest()==lock['inputs'][archive.name]
with zipfile.ZipFile(archive) as z:server=z.read('rakuyomi.koplugin/server')
assert server[:5]==b'\x7fELF\x01' and int.from_bytes(server[18:20],'little')==40
name='yomigami-engine-'+version;out=r/'dist'/name;out.mkdir(exist_ok=True)
(out/'server').write_bytes(server);digest=hashlib.sha256(server).hexdigest()
script=r'''#!/bin/sh
set -eu
ROOT=/mnt/us/yomigami
HERE=/mnt/us/__NAME__
exec >>"$ROOT/engine-update.log" 2>&1
fail() { eips 1 3 "$1"; exit 1; }
[ -x "$ROOT/engine/server" ] || fail "Install Yomigami first."
[ ! -d /var/tmp/yomigami.lock ] || fail "Close Yomigami before updating."
[ "$(sha256sum "$HERE/server" | awk '{print $1}')" = '__SHA__' ] || fail "Engine checksum failed."
BACKUP="$ROOT/.backup-engine-$(date +%Y%m%d-%H%M%S)-$$"
mkdir "$BACKUP"
cp -p "$ROOT/engine/server" "$BACKUP/server"
SWAPPED=0
rollback() {
 if [ "$SWAPPED" = 1 ]; then cp -p "$BACKUP/server" "$ROOT/engine/server.restore" && mv "$ROOT/engine/server.restore" "$ROOT/engine/server"; fi
 rm -f "$ROOT/engine/server.new"
}
trap rollback EXIT HUP INT TERM
cp "$HERE/server" "$ROOT/engine/server.new"
chmod 755 "$ROOT/engine/server.new"
[ "$(sha256sum "$ROOT/engine/server.new" | awk '{print $1}')" = '__SHA__' ] || fail "Engine copy failed."
SWAPPED=1
mv "$ROOT/engine/server.new" "$ROOT/engine/server"
sync
trap - EXIT HUP INT TERM
eips 1 3 "Manga engine updated. Open Yomigami."
'''.replace('__NAME__',name).replace('__SHA__',digest)
(out/'install.sh').write_text(script)
launcher='#!/bin/sh\n# Name: Update Manga Engine\n# Author: Yomigami contributors\n# Icon: data:image/png;base64,'+base64.b64encode((r/'assets/icon.png').read_bytes()).decode()+'\n# DontUseFBInk\nexec sh /mnt/us/'+name+'/install.sh\n'
(out/'Update Manga Engine.sh').write_text(launcher)
with zipfile.ZipFile(r/'dist'/f'Yomigami-Manga-Engine-{version}.zip','w',zipfile.ZIP_DEFLATED) as z:
 z.write(out/'server',name+'/server');z.write(out/'install.sh',name+'/install.sh');z.writestr('documents/Update Manga Engine.sh',launcher)
 z.write(r/'LICENSE','LICENSE');z.write(r/'THIRD_PARTY_NOTICES.md','THIRD_PARTY_NOTICES.md')
 z.writestr('START_HERE.txt',f'Existing Yomigami on jailbroken Paperwhite 12 required. Close Yomigami, copy the extracted folders to Kindle storage, eject USB and open Update Manga Engine. Previous engine is backed up in yomigami/.backup-engine-*. Books, settings and Kindle Home are not changed.\nOfficial unmodified Rakuyomi {version} KindleHF engine. Corresponding source: https://github.com/tachibana-shin/rakuyomi/tree/{version}\nThe KindleHF engine is included for the tested Paperwhite 12 target; other devices are unverified.\n')
print('Engine update:',out,'SHA256:',digest)
