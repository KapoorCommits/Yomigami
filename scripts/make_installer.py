
from pathlib import Path
import hashlib,base64,shutil
ROOT=Path(__file__).resolve().parents[1]
archive=ROOT/'dist/yomigami-0.4.0.tar.gz'
digest=hashlib.sha256(archive.read_bytes()).hexdigest()
icon=base64.b64encode((ROOT/'assets/icon.png').read_bytes()).decode()
script='''#!/bin/sh
# Name: Yomigami
# Author: Yomigami contributors
# Icon: data:image/png;base64,__ICON__
# DontUseFBInk
ROOT=/mnt/us/yomigami
ARCHIVE=/mnt/us/yomigami-0.4.0.tar.gz
EXPECTED=__SHA__
if [ ! -x "$ROOT/launch.sh" ]; then
    exec >>/mnt/us/yomigami-install.log 2>&1
    if [ -e "$ROOT" ]; then
        echo "Yomigami exists but is incomplete. Refusing to overwrite."
        eips 1 2 "Yomigami: existing folder needs review."
        exit 1
    fi
    if [ ! -f "$ARCHIVE" ]; then
        eips 1 2 "Yomigami: copy the archive to USB root."
        exit 1
    fi
    eips 1 2 "Installing Yomigami. Please wait..."
    ACTUAL="$(sha256sum "$ARCHIVE" | awk '{print $1}')"
    if [ "$ACTUAL" != "$EXPECTED" ]; then
        echo "Archive checksum mismatch: $ACTUAL"
        eips 1 3 "Yomigami: incomplete archive. Copy again."
        exit 1
    fi
    STAGE="/mnt/us/.yomigami-install.$$"
    mkdir "$STAGE" || exit 1
    if ! tar -xzf "$ARCHIVE" -C "$STAGE"; then
        echo "Extraction failed. Staging preserved at $STAGE"
        eips 1 3 "Yomigami: extraction failed. See log."
        exit 1
    fi
    if [ ! -f "$STAGE/yomigami/runtime/yomigami.lua" ]; then exit 1; fi
    chmod +x "$STAGE/yomigami/launch.sh" "$STAGE/yomigami/runtime/yomigami-runtime.sh" "$STAGE/yomigami/runtime/yomigami.lua" "$STAGE/yomigami/runtime/luajit" "$STAGE/yomigami/engine/server"
    mv "$STAGE/yomigami" "$ROOT" || exit 1
    rmdir "$STAGE"
    echo "Yomigami installed successfully."
fi
exec "$ROOT/launch.sh" --kual --asap
'''.replace('__SHA__',digest).replace('__ICON__',icon)
out=ROOT/'dist/installer';out.mkdir(exist_ok=True)
(out/'Yomigami.sh').write_text(script);(out/'Yomigami.sh').chmod(0o755)
print('Installer checksum: '+digest)
