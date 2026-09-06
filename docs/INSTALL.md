# Install Yomigami

**Target:** jailbroken Kindle Paperwhite 12th generation, firmware 5.18.5.0.1,
with a working scriptlet launcher. Other models are unverified. This is alpha software.
Yomigami does not install a jailbreak. Nearby firmware versions are unverified.
Download the **[Paperwhite 12 installer ZIP](https://github.com/KapoorCommits/Yomigami/releases/download/v0.4.0-alpha/Yomigami-0.4.0-Paperwhite12-Install.zip)**; no build tools are required.

## First installation

1. Download and extract the installer ZIP on your computer (or [build it locally](BUILDING.md)).
2. Copy `yomigami-0.4.0.tar.gz` to the Kindle storage root.
3. Copy `documents/Yomigami.sh` into the Kindle’s `documents` folder.
4. Disconnect USB and open the new **Yomigami** book.
5. The installer checks the archive checksum and installs into `/mnt/us/yomigami`.
   It refuses to overwrite an existing or incomplete installation.
6. Try **Reader Test**, the original 12-page test book, and the Welcome PDF.

The same launcher opens the installed app on subsequent runs. Your separately installed
KOReader and Rakuyomi are not altered. No commercial books are included.

## Update an existing installation

Back up `/mnt/us/yomigami/data`, then quit Yomigami before connecting USB.
Copy `dist/yomigami-update-0.4.0.tar.gz` to the storage root and
`dist/Update Yomigami 0.4.0.sh` into `documents`. Disconnect, then open the update book.
It checks its payload and retains a backup of the prior app, settings and bookmarks.
This updater applies 0.4.0 to earlier versions; it does not reinstall an already marked 0.4.0.

## Read your books

Copy PDF, EPUB or CBZ files into `/mnt/us/yomigami/data/library`, then choose **+ → Rescan**.
The import control copies a file already on Kindle without replacing its original.
Covers use the book’s first page. Hold a cover to rename its display title or move it to
Recently deleted; restore or permanently delete from that menu.

Tap a book or chapter to read. Edge taps turn pages; the center hides or restores the
reading toolbar. **Library** saves your place and returns to the shelf; **Quit ×** exits
to Kindle. The title opens the chapter menu. Chapter boundaries require an explicit choice.

Options includes brightness, warmth, contrast, reading direction, page fit, zoom,
light/dark mode, pre-rendering and auto-crop. Pinch to zoom where the device supports it.
Auto-crop fills width, so tall content pans before the next page. Originals are unchanged.
EPUB uses a fixed reflow layout; font customization and DRM support are not implemented.

## Find manga

Open **Mangas**, enter a title and search installed sources. Eleven English-capable
adapters are bundled, including Weeb Central and MangaDex. Each result names its source.
Select a manga, inspect its chapters, then choose **Download All at once** or an individual
chapter. The × search control clears the query and results.

The progress screen can stay open or run in the background while you read. Up to three
chapters are active, with eight page requests per chapter. The queue persists across
restarts; transfers stop when Yomigami exits. New scheduling pauses below 512 MB free.
Providers may be unavailable or rate limited; the app cannot guarantee download speed.

## Find PDFs and EPUBs

Open **PDFs** in the library. Gutenberg searches classics through Gutendex. Internet Archive
searches publicly downloadable PDFs. Direct HTTPS book links are also supported.

For Z-Library, choose **Sign in / change server**, then enter your current HTTPS server,
email and password on the Kindle. Choose **Search PDF & EPUB** afterward. Only session tokens
are saved, without encryption on Kindle storage; sign out removes them. Authenticated
search/download remains unverified in this alpha. PDFDrive integration is unavailable.

Book downloads run in background workers while the app is open, with a 128 MB file limit
and a 20-minute ceiling. Quitting cancels active PDF/EPUB transfers. Local reading is offline;
remote discovery and downloads require Wi-Fi.

## Recovery and removal

- Books, preferences and progress: `/mnt/us/yomigami/data/`.
- Reader diagnostics: `/mnt/us/yomigami/runtime/crash.log`.
- Source diagnostics: `/mnt/us/yomigami/data/source.log`.
- Installer diagnostics: `/mnt/us/yomigami-install.log`.

To remove Yomigami, quit it, back up `data`, and remove its own application folder and
launcher. Do not remove the separately installed KOReader directory. Redact personal
information and session data before sharing diagnostics.

After an update, check chapter/page resume, Library and Quit, power-button sleep/wake,
lighting, dark mode, auto-crop and source downloads on the physical Kindle. Emulator
success alone does not establish those hardware behaviors.
