# October reader update candidate

This source-built update is for an existing Yomigami installation on the inspected Paperwhite 12 / firmware 5.18.5.0.1 target. It is not a new public binary release or a first-install package. Keep a copy of `yomigami/data` before updating.

From a checkout of the latest source on macOS:

```sh
python3 scripts/make_reader_update.py
python3 tests/reader_installer.py
```

The builder creates `dist/Yomigami-Highlights-Update.zip`. Extract it on your computer. Copy the `yomigami-highlights-20261004` folder to Kindle storage root and `documents/Update Yomigami Highlights.sh` into Kindle's `documents` folder. Quit Yomigami, disconnect USB, then open **Update Yomigami Highlights** from the Kindle library. KUAL is not required.

This includes the latest reader Lua modules, the passcode option and the sharp caption-free cover. It validates payload/file checksums and Lua syntax, backs up replaced app/cover files, and rolls back if replacement fails. It preserves books, progress and passcode settings. It does not change Kindle Home, replace the native runtime or install/update manga adapters. For the separate source pack, see [SOURCES.md](SOURCES.md).

Validation includes local reader regressions, injected installer failures and byte-for-byte USB readback. The highlight update has been transferred to the development Kindle; on-device visual/touch confirmation is pending. Do not interpret successful transfer as proof of every runtime feature.
