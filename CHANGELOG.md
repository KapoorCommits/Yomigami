# Changelog

## Unreleased — October 2026 reader updates

- Light-grey on-page highlights in text-based PDFs and EPUBs; persistent notes and Markdown export. Passage context relocates EPUB highlights after reflow and rejects ambiguous matches.
- Optional 4–8 digit app-start passcode with protected change/disable controls and persisted retry delays.
- Local Wi-Fi/QR PDF, EPUB and CBZ import; per-book storage views; resumable PDF/EPUB download queues.
- Per-book reading preferences and EPUB font size based on the actual viewport.
- Durable state writes with flush/fsync, validated backups and fallback recovery.
- Direction-aware page prefetch, cached panned regions and bounded memory use.
- Followed-series checks with selective missing-chapter downloads and duplicate queue prevention.
- Separate manga/text refresh intervals, tap-zone controls and optional book-cover sleep display.
- Twenty bundled English-capable manga adapters. Revised book discovery, clearer provider errors and PDFDrive removal.
- Caption-free heron launcher cover, encoded at 586 × 880 within the Kindle scanner's image limit.
- Reader updater with checksum and syntax validation, file backups and replacement-failure rollback.

These source changes are newer than the published 0.4.0 binary. See [verification](docs/VERIFICATION.md) and [candidate update instructions](docs/OCTOBER_UPDATE.md).

## 0.4.0 alpha

Published first-install ZIP for the jailbroken Paperwhite 12 target: independent reader runtime, cover library, chapter navigation, saved progress, PDF/EPUB/CBZ rendering, manga search/downloads, and reading display controls. See the [release](https://github.com/KapoorCommits/Yomigami/releases/tag/v0.4.0-alpha).
