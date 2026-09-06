"""Wrap the verified first-run installer in a copy-to-Kindle ZIP."""
from pathlib import Path
import hashlib, zipfile
ROOT=Path(__file__).resolve().parents[1]
OUT=ROOT/'dist/Yomigami-0.4.0-Paperwhite12-Install.zip'
readme="""YOMIGAMI 0.4.0 ALPHA — KINDLE PAPERWHITE 12

Target: an already jailbroken Paperwhite 12th generation, firmware 5.18.5.0.1,
with a working scriptlet/book launcher. Other firmware, including nearby versions,
is unverified. This package does not jailbreak a Kindle.

FIRST INSTALL — NO BUILD TOOLS NEEDED
1. Extract this ZIP on your computer.
2. Copy yomigami-0.4.0.tar.gz to the Kindle storage root. Do not unpack that tar.gz.
3. Copy documents/Yomigami.sh into the Kindle's documents folder.
4. Disconnect USB and open the Yomigami book on the Kindle.
5. First launch verifies the payload, installs the app and opens it.

The installer refuses to overwrite an existing Yomigami installation. It keeps
KOReader and Rakuyomi separate. Back up your Yomigami data before any future update.

This is an alpha: core reading/page turns have been exercised on the target Kindle;
newer PDF/EPUB discovery and display changes still need physical confirmation.
After installing, try Reader Test, Library/Quit, sleep/wake, and page resume.

Code, help, updates and source companion:
https://github.com/KapoorCommits/Yomigami/releases/tag/v0.4.0-alpha

Credits: KOReader for the private device/native runtime; Rakuyomi for the manga
engine; Aidoku Community, MuPDF, ZlibraryKO and their upstream contributors.
See THIRD_PARTY_NOTICES.md and the bundled notices. No commercial books are included.
"""
with zipfile.ZipFile(OUT,'w',zipfile.ZIP_DEFLATED) as z:
 z.write(ROOT/'dist/yomigami-0.4.0.tar.gz','yomigami-0.4.0.tar.gz')
 z.write(ROOT/'dist/installer/Yomigami.sh','documents/Yomigami.sh')
 z.writestr('START_HERE.txt',readme)
 for name in ['LICENSE','THIRD_PARTY_NOTICES.md','docs/RELEASE-SOURCES.md']:
  z.write(ROOT/name,Path(name).name)
 for p in (ROOT/'licenses').iterdir():z.write(p,'licenses/'+p.name)
print(OUT.name,OUT.stat().st_size,hashlib.sha256(OUT.read_bytes()).hexdigest())
