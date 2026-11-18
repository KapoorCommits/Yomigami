"""Wrap the verified first-run installer in a copy-to-Kindle ZIP."""
from pathlib import Path
import hashlib, zipfile
ROOT=Path(__file__).resolve().parents[1]
OUT=ROOT/'dist/Yomigami-0.5.0-Paperwhite12-Install.zip'
readme="""YOMIGAMI 0.5.0 - FIRST INSTALL

For a jailbroken Kindle Paperwhite 12, firmware 5.18.5.0.1, with a working
scriptlet book launcher. Other devices and firmware are unverified.

1. Extract this ZIP on your computer.
2. Copy yomigami-0.5.0.tar.gz to the top level of Kindle storage. Do not unpack it.
3. Copy documents/Yomigami.sh into the Kindle documents folder.
4. Eject and unplug USB. Open Yomigami in the Kindle library.

The installer verifies its payload before installing. It refuses to overwrite
an existing incomplete installation. For an existing working Yomigami, use the
Update ZIP instead. Back up yomigami/data before updates.

This package does not jailbreak your Kindle or change Kindle Home. It contains
original sample books only. It uses its own KOReader runtime and Rakuyomi engine.

Help and source files: https://github.com/KapoorCommits/Yomigami/releases/tag/v0.5.0
Credits and licenses: see THIRD_PARTY_NOTICES.md and the licenses folder.
"""
with zipfile.ZipFile(OUT,'w',zipfile.ZIP_DEFLATED) as z:
 z.write(ROOT/'dist/yomigami-0.5.0.tar.gz','yomigami-0.5.0.tar.gz')
 z.write(ROOT/'dist/installer/Yomigami.sh','documents/Yomigami.sh')
 z.writestr('START_HERE.txt',readme)
 for name in ['LICENSE','THIRD_PARTY_NOTICES.md','docs/RELEASE-SOURCES.md']:
  z.write(ROOT/name,Path(name).name)
 for p in (ROOT/'licenses').iterdir():z.write(p,'licenses/'+p.name)
print(OUT.name,OUT.stat().st_size,hashlib.sha256(OUT.read_bytes()).hexdigest())
