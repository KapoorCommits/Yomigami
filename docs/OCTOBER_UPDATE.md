# Update Yomigami to 0.5.0 RC2

This source-built update is for an existing Yomigami installation on the inspected Paperwhite 12 / firmware 5.18.5.0.1 target. It is not a new public binary release or a first-install package. Keep a copy of `yomigami/data` before updating.

## Which download do I need?

- **Yomigami already opens on your Kindle:** [download the update ZIP](https://github.com/KapoorCommits/Yomigami/releases/download/v0.5.0-rc2/Yomigami-Highlights-Update.zip).
- **You have never installed Yomigami:** start with the [first-install guide](INSTALL.md), then apply this update.

“RC” means release candidate: a version ready for testing, with some device checks still pending. It is not a promise that every feature works on every Kindle.

## Update in five steps

1. Close Yomigami and connect your Kindle by USB. Back up its `yomigami/data` folder to your computer.
2. Download the ZIP and extract it **on your computer**.
3. Copy `yomigami-highlights-20261004` to the Kindle's top-level storage folder—the same place that contains `documents`. Leave the `payload.tar.gz` inside it compressed.
4. Copy `documents/Update Yomigami Highlights.sh` from the extracted ZIP into the Kindle's existing `documents` folder.
5. Unplug USB. In the Kindle library, open **Update Yomigami Highlights**. It checks the files, installs the update and opens Yomigami. You do not need KUAL.

The title says “Highlights”, but this package also includes the passcode option and the other October reader improvements.

## Build it yourself

From a source checkout on macOS:

```sh
python3 scripts/make_reader_update.py
python3 tests/reader_installer.py
```

The resulting ZIP is `dist/Yomigami-Highlights-Update.zip`.

## What changes—and what stays yours

This includes the latest reader Lua modules, the passcode option and the sharp caption-free cover. It validates payload/file checksums and Lua syntax, backs up replaced app/cover files, and rolls back if replacement fails. It preserves books, progress and passcode settings. It does not change Kindle Home, replace the native runtime or install/update manga adapters. For the separate source pack, see [SOURCES.md](SOURCES.md).

Validation includes local reader regressions, injected installer failures and byte-for-byte USB readback. The highlight update has been transferred to the development Kindle; on-device visual/touch confirmation is pending. Do not interpret successful transfer as proof of every runtime feature.
