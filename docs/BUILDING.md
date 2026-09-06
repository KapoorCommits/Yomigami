# Build Yomigami

## Build a Kindle installer locally

Requires Python 3.10+, Git, internet access and roughly 1 GB of working space.
These scripts assemble a private runtime from checksum-pinned upstream releases;
they do not compile KOReader or Rakuyomi from source.

```sh
git clone https://github.com/KapoorCommits/Yomigami.git
cd Yomigami
python3 scripts/bootstrap.py
python3 scripts/package.py
python3 scripts/make_installer.py
python3 scripts/make_update.py
```

`bootstrap.py` downloads the exact inputs in `runtime-lock.json`, verifies SHA-256,
preserves existing extracted runtimes, and generates original sample books in an
isolated packaging-fixture directory. No personal library or source database is needed.

Install using `dist/yomigami-0.4.0.tar.gz` and `dist/installer/Yomigami.sh`. See the
[installation guide](INSTALL.md). The updater is for an existing Yomigami installation.
Generated output is excluded from Git. Always test updates on hardware before sharing them.

## Check the source

```sh
python3 scripts/check_repository.py
```

GitHub Actions checks Python compilation, relative documentation links, source-adapter
hashes, shell/Lua syntax and prohibited generated/private file paths. It does not emulate
a Kindle, exercise authenticated providers, or certify a binary for all devices.

## Native macOS tests

The original development environment uses the KOReader arm64 2024.11-283 macOS emulator.
Obtain a compatible emulator from upstream and put `KOReader.app` under `build/macos/`.
This emulator is separate from the pinned Kindle runtime. Its setup is currently manual.
The `luajit` binary should be at `build/macos/KOReader.app/Contents/koreader/luajit`.
Copy `build/kindle/koreader/data/ca-bundle.crt` to the emulator’s `data/` for HTTPS tests.

```sh
python3 scripts/bootstrap.py --macos-engine
./scripts/test.sh
YOMIGAMI_HOME="$PWD/build/test-data" YOMIGAMI_NO_ENGINE=1 SDL_VIDEODRIVER=dummy \
  EMULATE_READER_W=1272 EMULATE_READER_H=1696 \
  YOMIGAMI_TEST="$PWD/tests/ui.lua" ./scripts/run_macos.sh
python3 tests/installer.py
python3 tests/upgrade.py
```

Additional native tests cover design, toolbar, discovery, books, crop and prefetch.
Some `*_live` scripts need internet, an account or a local test input and are not
part of the offline CI suite. Do not run them against personal libraries.

## Upstream source and redistribution

Pinned revisions and official source locations are in [THIRD_PARTY_NOTICES.md](../THIRD_PARTY_NOTICES.md)
and `runtime-lock.json`. `scripts/package.py` applies the runtime adaptations; the resulting
diff is recorded in `docs/runtime.patch`. To inspect or compile the underlying engines,
check out the listed revisions and follow their upstream recursive-submodule/build instructions.

The prebuilt installer and its source companion are published together. See
[RELEASE-SOURCES.md](RELEASE-SOURCES.md) for the exact source contents and how the native
dependencies are obtained. To create the copy-to-Kindle ZIP after building the installer,
run `python3 scripts/make_release_zip.py`.
