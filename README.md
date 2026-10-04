<p align="center"><img src="docs/images/banner.svg" alt="Yomigami — Manga, books, and a place to return to." width="100%"></p>

<p align="center">
<a href="LICENSE"><img alt="AGPL v3 or later" src="https://img.shields.io/badge/license-AGPL--3.0--or--later-35473b?style=flat-square"></a>
<img alt="Experimental alpha" src="https://img.shields.io/badge/status-experimental_alpha-8b6e46?style=flat-square">
<img alt="Jailbroken Kindle" src="https://img.shields.io/badge/built_for-jailbroken_Kindle-35473b?style=flat-square">
</p>

<p align="center"><b>Your manga. Your books. Your place in the story.</b><br>
An open-source reader for Kindle, with a library of its own.</p>

<p align="center"><a href="#what-you-can-do">Features</a> · <a href="#install-yomigami">Install</a> · <a href="docs/READER_GUIDE.md">Reader guide</a> · <a href="docs/BUILDING.md">Build</a> · <a href="#built-on-shared-foundations">Credits</a></p>

Yomigami brings manga, PDFs and EPUBs together in a cover-first library. Open a book, pick up at your bookmark, and hide the controls when you want the whole screen for reading. Send a book from your phone, collect passages worth remembering, or queue the next chapters while you read.

It runs independently of your separately installed KOReader, using its own copy of KOReader's reading components and Rakuyomi's manga engine. Updating KOReader does not replace Yomigami's app files.

> **Know what you're installing.** The **0.5.0 RC2 update** includes the features below and is an early testing release for people who already have Yomigami installed. The **0.4.0 alpha ZIP** is the older first-install package. The development target is a **jailbroken Kindle Paperwhite 12, firmware 5.18.5.0.1**; other devices and firmware versions are unverified. See the [verification record](docs/VERIFICATION.md) for what has actually been tested.

## What you can do

| Make it your library | Make the page yours | Bring the next book |
| --- | --- | --- |
| Cover grid and chapter menus | PDF, EPUB and CBZ reading | Search 20 bundled manga sources |
| Saved page and chapter bookmarks | Crop, zoom, contrast and reading direction | Queue individual chapters or a whole series |
| Rename, trash and restore books | Per-book settings and EPUB font size | Follow series and check for new chapters |
| Per-book storage usage | Light-grey highlights, notes and Markdown export | Resume supported PDF/EPUB downloads |
| Optional numeric app passcode | Light/dark mode, brightness and warmth | Local Wi-Fi import with a QR code |

### A shelf that remembers

Chapter menus mark your current place with a ribbon. Returning to Library or quitting saves progress. Reading settings belong to the book or manga series, so a crop or contrast adjustment for one scan doesn't change everything else. **Library → + → Storage** shows what occupies space; deleted books stay in Recently deleted until permanently removed.

### Passages worth keeping

In an EPUB or PDF with a text layer, hold a page to open its text, then hold and drag to select a passage. Save it as a highlight or attach a note. New highlights appear as **light-grey backgrounds on the original page**, keeping the lettering dark.

Highlights persist across reopening. When an EPUB font size changes, Yomigami looks for the same passage in its new position; if it cannot identify the passage confidently, it keeps your saved note without marking the wrong text. Export highlights and notes as Markdown. Image-only scans support page notes; OCR is not included.

### Send a book without a cable

Open **PDFs → Import PDF From Anywhere**, scan the QR code or open the displayed URL from a phone or computer on the same Wi-Fi, and upload a PDF, EPUB or CBZ. No cloud account or AirDrop is required. Keep the transfer screen open; closing it stops the receiver. [Transfer details and limits](docs/READER_GUIDE.md#wi-fi-import).

### Your next chapter, prepared

Optional pre-rendering follows your navigation direction, preparing four pages ahead and one behind within a 32 MB cache. Recently panned regions can be reused. Configure full-refresh intervals separately for manga and text, choose tap zones, or display the current book's cover during sleep. E-ink refresh and cold-page rendering still take time.

### More to read, less to manage

Twenty English-capable adapters include **Weeb Central and MangaDex**. Search results identify the source; inspect chapters and choose what to download. Manga queues support progress, pause, retry and background reading. Follow a series and use **+ → Followed series** to check for missing chapters; checks are manual, not push notifications.

PDF/EPUB downloads remember their progress and can pick up where they stopped when the website supports it. Sources that cannot safely resume restart from the beginning. Transfers run while Yomigami is open. [Bundled source list](docs/SOURCES.md).

### An optional lock for your reading space

**Options → Passcode** enables a 4–8 digit code at app startup. Changing or disabling it requires the current code; repeated wrong attempts trigger a delay. It is an interface lock, **not file encryption**, and does not lock an already-open session after sleep. [Setup and recovery](docs/READER_GUIDE.md#passcode).

## A look inside

These are emulator captures at the Paperwhite's 1272 × 1696 resolution, using original test books and sample metadata. They illustrate the library, chapter and options design; they are not device photographs or screenshots of every latest control.

<p align="center">
<img src="docs/images/library.png" width="31%" alt="Cover library with reading progress">
<img src="docs/images/chapters.png" width="31%" alt="Chapter menu with a bookmark ribbon">
<img src="docs/images/options.png" width="31%" alt="Brightness, warmth and contrast options">
</p>

<details>
<summary>The new Kindle launcher cover</summary>
<p align="center"><img src="assets/icon.png" width="260" alt="Yomigami cover: a heron among mountains shaped like book pages"></p>
A caption-free, 586 × 880 grayscale cover, encoded to preserve detail within Kindle's scanner limits.
</details>

## Install Yomigami

You need an **already jailbroken compatible Kindle** and a working scriptlet/book launcher. Yomigami does not jailbreak the device.

| You want to… | Start here |
| --- | --- |
| Try the published 0.4.0 alpha | [Download its Paperwhite 12 installer ZIP](https://github.com/KapoorCommits/Yomigami/releases/download/v0.4.0-alpha/Yomigami-0.4.0-Paperwhite12-Install.zip) · [Installation guide](docs/INSTALL.md) |
| Build the latest source | [Build instructions](docs/BUILDING.md) |
| Already have Yomigami? Get the new features | [Download the 0.5.0 RC2 update ZIP](https://github.com/KapoorCommits/Yomigami/releases/download/v0.5.0-rc2/Yomigami-Highlights-Update.zip) · [Simple update steps](docs/OCTOBER_UPDATE.md) |
| Understand device support and test coverage | [Verification record](docs/VERIFICATION.md) |

For the published installer: extract the ZIP on your computer, copy `yomigami-0.4.0.tar.gz` to Kindle storage root and `documents/Yomigami.sh` into `documents`, then disconnect USB and open **Yomigami**. Leave the tar.gz compressed. This first-install package refuses to overwrite an existing installation.

Your app and reading data live under `/mnt/us/yomigami`; your separate KOReader installation stays separate. Back up `yomigami/data` before alpha updates. The current reader updater validates checksums and Lua syntax, backs up the app and cover, and restores replaced files if installation fails. It does not patch Kindle Home or provide a general runtime-crash rollback feature.

## Book discovery and source availability

The PDFs section includes Gutenberg discovery through Gutendex, Open Textbook Library, Internet Archive discovery, direct HTTPS links, and local Wi-Fi import. Account-based providers are experimental: Z-Library may return HTTP 403, and Anna's Archive uses browser handoff or a member-key download route. Authenticated provider access is not broadly hardware-verified. PDFDrive was removed after repeated failures.

Websites, account limits and source adapters change. Bundled adapters are not a promise that every provider works at all times. **No commercial books, manga chapters, personal reading data or credentials are distributed with this repository.**

## What to know before using it

- This is experimental software, developed and exercised on one Kindle model/firmware combination.
- Local regression checks passed for the latest passcode and on-page highlights; physical touch, sleep and network behavior still need broader device testing.
- EPUB reading position after changing layout is approximate; highlight anchors are resolved separately by text context.
- Wi-Fi import uses local HTTP with a temporary session token. Use a trusted network; interrupted uploads must be sent again.
- No DRM removal, OCR, continuous webtoon scrolling, landscape/two-page spreads, or battery-aware download scheduling yet.
- Kindle Home customization experiments are separate and are not part of the public reader installer.

See [what changed](CHANGELOG.md), [architecture](docs/ARCHITECTURE.md), and [security guidance](SECURITY.md).

## Built on shared foundations

**[KOReader](https://github.com/koreader/koreader)** provides the Kindle device integration, e-ink display and input handling, power lifecycle, widgets, and native document runtime. Yomigami includes a private, adapted KOReader-derived runtime; it does not claim to replace that engineering from scratch.

**[Rakuyomi](https://github.com/tachibana-shin/rakuyomi)** provides the Rust engine behind manga discovery and downloads. Its work made Yomigami's standalone manga experience possible.

Thank you also to **[Aidoku Community](https://github.com/Aidoku-Community/sources)** for adapters, **[MuPDF](https://mupdf.com/)** for rendering, **[ZlibraryKO](https://github.com/ZlibraryKO/zlibrary.koplugin)** for the Z-Library protocol reference, and all upstream library, font and tooling contributors. [Credits, licenses and source locations](THIRD_PARTY_NOTICES.md).

Yomigami is independent and is not an official release or endorsement of those projects.

## Contribute

Created and maintained by **[@KapoorCommits](https://github.com/KapoorCommits)**. Device testing, clear bug reports, accessibility improvements and focused pull requests are welcome. Start with [CONTRIBUTING.md](CONTRIBUTING.md); include your Kindle model, firmware, app version and reproduction steps.

`@KapoorCommits` owns every path through CODEOWNERS. The protected main branch requires maintainer review and repository checks; [governance](GOVERNANCE.md) describes the policy and the single-maintainer exception.

**[AGPL-3.0-or-later](LICENSE).** Upstream components retain their own licenses. Read, modify and share Yomigami under the applicable terms.
