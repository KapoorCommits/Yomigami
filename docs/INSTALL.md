# Install or update Yomigami

Tested on a jailbroken Kindle Paperwhite 12th generation running firmware 5.18.5.0.1, with a working scriptlet book launcher. Other models and firmware versions are unverified. These files do not install a jailbreak.

Get the ZIP from the [latest release](https://github.com/KapoorCommits/Yomigami/releases/latest). Do not use GitHub's automatic Source code ZIP to install the app.

## First installation

1. Download `Yomigami-0.5.0-Paperwhite12-Install.zip` and extract it on your computer.
2. Connect the Kindle by USB.
3. Copy `yomigami-0.5.0.tar.gz` to the top level of Kindle storage. Leave this archive packed.
4. Copy `documents/Yomigami.sh` into the Kindle's `documents` folder.
5. Eject the Kindle, unplug USB, and open **Yomigami** in the Kindle library.

The launcher checks the archive, installs the app and opens it. It refuses to overwrite an existing incomplete installation. Reader Test and Welcome PDF are small original samples; no commercial books are bundled.

## Update an existing installation

1. Quit Yomigami and connect USB.
2. Back up the entire `yomigami/data` folder to your computer. It contains your books, progress, settings and notes.
3. Extract `Yomigami-0.5.0-Paperwhite12-Update.zip`.
4. Copy all extracted folders and the source archive to the top level of Kindle storage. Merge the `documents` folder with the existing one.
5. Eject, unplug USB, then open **Update Yomigami**.
6. When Yomigami opens, check your library and resume a book. You can then remove the temporary update book and update files listed in `START_HERE.txt`.

The update installs the reader, manga engine and bundled source adapters. It keeps your books, notes, preferences and the current Kindle Home layout. Component backups remain inside the Yomigami folder. Each component is verified before replacement; if an update reports an error, keep the files and logs for diagnosis.

## Add your own books

Copy PDF, EPUB or CBZ files into `yomigami/data/library`, then use **+ → Rescan**. For wireless transfer, open **PDFs → Import PDF From Anywhere** and follow the local Wi-Fi instructions. Your phone or computer must be on the same network. EPUB and CBZ uploads are supported too; this is a browser upload, not AirDrop.

## If something goes wrong

Do not factory-reset the Kindle or delete your data folder. Keep these logs if present:

- `yomigami-install.log` for first installation.
- `yomigami-update.log` for reader updates.
- `yomigami/runtime/crash.log` for reader errors.
- `yomigami/data/source.log` for manga source errors.

Remove personal details before sharing logs in an issue. Include your model, firmware and the steps that failed.

To remove the app, quit it, back up `yomigami/data`, then remove the `yomigami` folder and `documents/Yomigami.sh`.
