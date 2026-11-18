# Changelog

## 0.5.0 - November 18, 2026

- Refine library, chapter, manga search, book discovery and download screens with shared rounded controls and calm grayscale cards.
- Add geometric icons, rounded close buttons, larger primary touch targets and clearer download actions.
- Schedule owned-series checks for Sunday 10 PM and Monday 6 PM India time, with catch-up on reopening. This currently requires Yomigami to be running and does not wake a sleeping Kindle.

- Rank exact manga titles first, add double-tap paragraph highlights, and fix download-screen repainting.
- Cancel all downloads or clear failed and queued entries without deleting completed books.
- Reduce download progress writes and reuse a bounded cover cache to keep input responsive.
- Publish a current first-install ZIP, an update ZIP, and real Kindle screenshots.

### Reader and download fixes

- Add per-book Edge-to-edge fit with tight blank-border removal and selectable-text protection.
- Recognize diagonal page swipes; preserve the current position when the next render fails.
- Refresh before durable progress writes; delay background pre-rendering to prioritize input.
- Reset stale animation flags and animate tall-page scrolling on supported Kindle hardware.
- Skip highlight lookup when a book has no annotations.
- Expand the source bundle to 25 adapters. See the source guide for compatibility and availability limits.


## 0.5.0 RC2 - October 2026 reader update (prerelease)

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

The update ZIP requires an existing installation. The 0.4.0 ZIP remains the first-install package. See [verification](docs/VERIFICATION.md) and [candidate update instructions](docs/OCTOBER_UPDATE.md).

## 0.4.0 alpha

Published first-install ZIP for the jailbroken Paperwhite 12 target: independent reader runtime, cover library, chapter navigation, saved progress, PDF/EPUB/CBZ rendering, manga search/downloads, and reading display controls. See the [release](https://github.com/KapoorCommits/Yomigami/releases/tag/v0.4.0-alpha).
