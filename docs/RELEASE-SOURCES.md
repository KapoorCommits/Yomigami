# Sources for the 0.4.0 prebuilt alpha

The installer packages Yomigami’s Lua application, the official KOReader kindlehf
v2026.07.1 runtime with the changes in `docs/runtime.patch`, and Rakuyomi’s v1.41.6
kindlehf source engine. It does not require a separately installed KOReader.

Download **Yomigami-0.4.0-Sources.tar.gz** from the same GitHub release as the installer.
It contains:

- `yomigami/`: application source, local packaging scripts, notices, build guide and runtime patch.
- `koreader/`: the pinned release source tree with its recursive submodules, including base,
  crengine, fonts, translations and test data.
- `rakuyomi/`: the pinned engine source, Cargo lockfile and upstream build instructions.
- `dependency-archives/`: collected native dependency archives and Rust crate/git sources.
- `UPSTREAM-SOURCES.json` and `DEPENDENCY-SOURCES.json`: exact revisions, source locations,
  locally included paths and SHA-256 hashes. Entries without a local file retain their
  upstream download URLs; see the source archive README for the collection report.

`runtime-lock.json` records the exact official binary input hashes. The public app source
is AGPL-3.0-or-later; upstream libraries retain their own notices. See
[THIRD_PARTY_NOTICES.md](../THIRD_PARTY_NOTICES.md).

## Recreate the application package

Follow [BUILDING.md](BUILDING.md). Those commands reproduce the assembly process from
checksum-verified official binary inputs; archive timestamps can differ. They are not a
claim that rebuilding every native dependency locally produces bit-identical binaries.

## Rebuild the upstream native components

Use the exact revisions in the manifests and the included KOReader and Rakuyomi READMEs.
KOReader’s KindleHF cross-build uses its upstream toolchain and CMake recipes under
`base/thirdparty`; those recipes specify source versions, download locations and patches.
Rakuyomi’s engine dependencies are pinned in `backend/Cargo.lock`. The dependency archives
are originals (the `.source` suffix does not change their compression format), not patched
working trees; apply the included upstream build recipes/patches when rebuilding.

The collection helpers in `scripts/collect_release_sources.py` and
`scripts/collect_release_dependencies.py` require Python 3.11+ and internet access.
They fetch source only, do not execute it, and store results under `build/release-sources`.
