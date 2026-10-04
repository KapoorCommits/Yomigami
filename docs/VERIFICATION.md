# Verification record

## Passed locally

- Nine native core test groups: page-two regression, repeated end events,
  backward navigation/resume/jumps, one-page boundaries, tall-page panning,
  natural sort, progress round-trip/corrupt-state preservation, copy-only import,
  rendering every page of five PDFs and one 12-page CBZ, module isolation.
- Native UI test: cover layout, all 12 page turns, final-page confirmation,
  saved-page reopen, options/menu dismissal, filters, keyboard dialog,
  nested source-ID API schema, PDF panning, sleep flag lifecycle.
- Verified no `apps/reader/*` or plugin-loader module loaded in those UI flows.
- Actual independent macOS Rakuyomi server: loopback startup, 528 source records,
  source installation, live WeebCentral search returning Sakamoto-related results.
- MANGA Plus installation succeeded but the tested query returned no results;
  this is not claimed as a working search integration for that source.
- Kindle read-only inspection: launcher presence, KOReader version, Rakuyomi
  build info and historical chapter-switch logs.

## Pending physical confirmation

Real manga chapter navigation, sleep/wake and the new toolbar controls
on Paperwhite 12 / firmware 5.18.5.0.1. Desktop SDL tests cannot establish
those hardware results. Device source downloading also needs confirmation.

The macOS native runtime is the upstream bundled 2024.11-283 emulator; the Kindle
runtime is pinned separately to v2026.07.1. Core FFI interfaces are exercised on
macOS, but the actual ARM/Linux bundle must pass on-device checks.

## First physical test and revision

The user confirmed Yomigami opens on the Kindle. They reported overlapping text,
requested a visible exit control and smoother page turning. Font:getFace already
applies screen scaling, while the application had scaled the requested size first.
This doubled scaling on the high-resolution Kindle (the 600-pixel emulator hid the error).
Version 0.1.1 removes that duplicate scaling and has been visually checked at
1264x1680. A visible library exit control is included. Page turns use partial
refresh, a full refresh after six turns, and the PW6 MTK native swipe animation
when supported. The user subsequently confirmed readable text and beautiful
page turning on the Kindle.

Additional local checks: real WeebCentral search, 273 chapter records, a completed
chapter download with an empty page-error list; installer tests for missing
payload, bad checksum, existing-folder preservation, extraction and repeat launch.
The first device archive and scriptlet were read back byte-for-byte and hashed
successfully before the user unplugged the device.

The first-run hardware log identifies KindlePaperWhite6 and an actual framebuffer
of 1272x1696. The corrected layout is also tested at that exact size. The log shows
a normal exit code 0 and the launcher log shows framework services resumed.
A real source chapter downloaded successfully and all 58 pages rendered locally.
The 0.1.1 update archive and scriptlet were also read back and hash-verified.

## Version 0.1.2

Added separate Library and Quit controls in a hideable reading toolbar. The
center tap restores controls in full-screen mode. Native UI and core regressions
pass, including toolbar visibility, full-screen page turns, saved-page reopen,
and separate Library/Quit callbacks at the device framebuffer size 1272x1696.
A Sakamoto Days chapter from the earlier source download is transferred separately
for the user-requested hardware test; it is not included in distributable packages.
Hardware toolbar and real-chapter confirmation remain pending.

## Version 0.2.0

- Native core/UI/toolbar regressions pass at 1272x1696.
- Actual MuPDF pinch-scale rendering and horizontal/vertical panning remain
  bounded to the screen buffer. Gesture delivery itself needs device testing.
- Lighting panel tested with a simulated device power interface; actual Kindle
  brightness/warmth values still need physical confirmation.
- Ribbon bookmarks, rename, delete/restore, persistent queue deduplication and
  completed-job metadata pass native tests.
- Live requests run in child processes and return through the native UI loop.
- A real two-chapter queue completed with saved chapter IDs and grouping.
- Eleven bundled English-capable adapters returned search results: Weeb Central,
  MangaDex, Asura Scans, Flame Comics, Guya, TCB Scans, Magus Manga, Hive Scans,
  Vortex Scans, Danke fürs Lesen and MangaRead.org. This is a tested selection
  from the user's list, not a global popularity ranking. Comix errored; Aqua,
  Drake and MangaKakalot returned no results for the tested queries.
- Single-run desktop comparison, same 58-page chapter and fresh download folders:
  4 concurrent page requests: 5.10 s; 8: 3.31 s. Both had zero page errors.
  Order/CDN cache/network variability were not controlled. This is not a measured
  improvement over the user's Rakuyomi installation or a Kindle speed guarantee.
- Upgrade preparation preserves page bookmarks, aliases and existing source
  preferences; invalid JSON aborts before applying data changes.
- Device validation of all new 0.2.0 controls remains pending.

## Version 0.2.1

Direct Options sliders for brightness, warmth and contrast; centered custom
button and toolbar labels; designed offline chapter menu positioned at the current
bookmark; original 600x916 launcher cover. The aspect ratio matches the inspected
KOReader launcher cover (938x1432) to within rounding.

Native tests verify contrast alters grayscale rendering, controls stay inside the
1272x1696 framebuffer, chapter pagination opens at the saved chapter, and existing
reader/library/queue regressions pass. Screens were rendered and visually inspected.
Actual Kindle cover-cache refresh and appearance remain pending user confirmation.

## Version 0.3.0

- Native discovery, chapter selection and live progress layouts inspected at 1272x1696.
- Live multi-source search selected Sakamoto Days and fetched 273 chapters.
- Synthetic blank and edge-marked crop tests pass; actual MuPDF crop render enlarges
  content while preserving safety padding. Contrast regression caught and fixed.
- Cache hit verified on the next page; crop invalidation and release on close pass.
  Cache allocation capped at 32 MB. Prefetch runs one page per scheduled UI idle
  callback; an individual decode can still occupy the UI thread briefly.
- Desktop fixture benchmark: 15 repeats averaged 2.64 ms uncached and 0.02 ms cached.
  This excludes e-ink refresh and is not a Kindle latency measurement.
- Queue scheduling reduced from 2 s to 0.2 s with immediate slot refill and three
  active chapter slots. Source bandwidth/rate limits still bound transfer speed.
- Hardware validation of 0.3.0 remains pending.

## Version 0.4.0

- Gutenberg search via Gutendex, live Alice EPUB download and native EPUB rendering passed.
- Live Internet Archive search returned public-PDF matches; full Archive downloads remain unverified.
- Hostname-verified HTTPS downloaded and validated the W3C one-page PDF fixture.
- HTTPS redirects discard prior response bodies and do not forward cookies to other hosts.
- Z-Library API protocol reviewed against ZlibraryKO/zlibrary.koplugin; own adapter uses
  rpc.php account login, eapi search and eapi file links. Mock session, rejection and URL
  handling checked. No user account was supplied; live authenticated search/download remains unverified.
- PDFDrive URL returned 403; its card explains that integration is unavailable. No working
  PDFDrive downloader is claimed. The original z-library.bz website returned a browser challenge;
  the account integration allows the reader to enter their current HTTPS server.
- Native UI, chapter boundaries, resume, lighting/contrast, options, toolbar, crop, prefetch,
  download queue and book-browser regression suites pass at 1272x1696.
- Clear search invalidates in-flight callbacks; idle progress causes no recurring screen refresh.
  Progress updates use a bounded fast-refresh region. Actual Kindle flashing remains to be checked.
- Auto-crop fills viewport width and preserves vertical navigation instead of fitting tall pages
  back inside the whole viewport. Crop-width regression passes.
- EPUB uses MuPDF reflow at a fixed 600x800 / 24 em layout so bookmarks remain stable;
  font/layout customization is not implemented. DRM-protected books are not supported.
- Book downloads run in background workers with a 128 MB size cap and 20-minute ceiling;
  quitting the app cancels active book transfers. Manga queue remains persistent.
- Sign-in password is used in memory only; only server/session tokens are saved locally.
  These tokens are not encrypted on Kindle storage. Sign out removes the saved session.

## Version 0.5.0 test candidate

- PDF/EPUB queue persists across exits, retries temporary failures with bounded backoff,
  supports pause/retry/cancel, and preserves partial downloads. Range resume requires
  server validators and matching byte ranges; unsupported servers restart safely.
- Download confirmation shows server-reported size and available space. Unknown sizes
  remain explicitly unknown. Files are limited to 512 MB with a 64 MB free-space reserve.
- Native regression tests cover interrupted/resumed transfers, ignored Range responses,
  invalid ranges, low space, queue recovery, and isolation of per-book reading settings.
- Library Storage sums real book/chapter bytes and reports partial downloads and trash.
  Manga sources do not expose reliable total sizes before downloading.
- Send to Yomigami uses a temporary local HTTP server and session QR code. Native desktop
  integration tests verify exact uploaded PDF bytes, invalid-file rejection, token/origin
  checks, path traversal rejection and overwrite protection. Closing the receiver stops
  its server; sessions expire after 30 minutes. Use only a trusted local Wi-Fi network.
- Live HTTPS PDF probe/download and native QR rendering passed on macOS. Kindle Wi-Fi
  reachability, QR transfer from a phone, and new storage/preferences UI need device checks.

### PDF import entry (2026-09-19)

- PDFs & ebooks now opens the existing local receiver through “Import PDF From Anywhere”.
  Successful startup closes the source menu so Done returns directly to the library.
- Kindle receiver sessions add only their temporary TCP port to INPUT/OUTPUT and remove
  those rules on close; partial setup failure rolls back the first rule.
- macOS runtime checks passed for the menu action, rendered layout, receiver start/stop,
  and mocked Kindle firewall success/failure cleanup. Real HTTP checks passed for exact
  PDF bytes, invalid documents, token/origin/path restrictions and duplicate protection.
- Physical phone-to-Kindle connectivity and firewall behavior remain unverified for this
  change. There is no native AirDrop implementation; use the same-Wi-Fi browser URL/QR.

### Book sources (2026-10-02)

- Removed the inactive PDFDrive option; pdfdrive.webs.nf still returned HTTP 403.
  Reviewed PDFDrive tools, ZlibraryKO's current API implementation, and
  right9code/annas-fetch.koplugin. The latter's mirror scraper was not copied.
- Added the official Open Textbook Library JSON search API, filtering to HTTPS
  direct PDF links. Publisher landing-page entries are excluded. Some result
  pages can therefore be empty; Next continues through the catalog.
- Live native-runtime test: search “algebra”, download College Algebra from its
  publisher, and open the PDF: 6,105,538 bytes, 716 pages. This confirms one sample,
  not availability of every publisher link or unrestricted commercial books.
- Z-Library handles blocked/expired sessions, moved endpoints, structured errors,
  and missing result arrays explicitly. An unavailable login endpoint can fall
  back once to /eapi/user/login; no retry on rate limiting or HTTP 403. Credentials
  are not forwarded to redirected hosts. Authenticated live access remains unverified.
- Anna’s Archive: free search/download uses the phone/computer browser followed
  by existing Wi-Fi import. Automated search returned HTTP 403. Direct book-link
  downloads use the documented member API; a membership secret key is required
  and stored locally. API contract tests passed; no paid account was available
  for an authenticated live test. Challenges are not bypassed.
- Regression checks passed: source menu bounds, API error contracts, login fallback,
  textbook filtering, browser-link validation, Wi-Fi receiver lifecycle and HTTP
  byte-for-byte import. The Kindle has not yet received this October update.

### October reader update (2026-10-02)

- Nine core checks and ten isolated reader suites passed, including a 1272×1696
  EPUB fixture, saved font settings, proportional reflow position, text selection
  callback, persistent highlights/notes and Markdown export.
- Injected file-sync and rename failures preserve the previous state. A missing
  or invalid main file recovers a validated backup; corrupt bytes never replace
  that backup. These simulations do not replace a physical power-loss test.
- Backward navigation prepares the previous page first; tall-page next viewport
  and revisit caching were exercised. Render signatures include reading direction
  and font size. Cache remains bounded to 32 MB.
- Follow/unfollow, refresh, missing-chapter selection, duplicate queue avoidance,
  and source failure preservation passed with a simulated source API. Actual manga
  availability and device/network behavior still require a Kindle check.
- Cover sleep rendering, double-tap toolbar access, and separate refresh intervals
  passed locally. Hardware sleep/wake and touch gesture behavior remain unverified.
- Installer simulations passed: success, bad archive checksum, Lua syntax failure,
  and failed replacement rollback. Existing book and state bytes were preserved.
- `python3 scripts/make_reader_update.py` builds a standalone library updater and
  ZIP without KUAL. It updates only app files and backs up the previous app. It does
  not patch native Home, replace the runtime, change sources or publish a release.
- Deferred: continuous webtoon layout, landscape/two-page spreads, battery-aware
  scheduling, OCR selection, and highlights drawn directly over original pages.

### October 4 reader and publication update

- Twelve isolated reader suites passed, including passcode setup/verification/failure handling and light-grey on-page highlight rendering.
- Highlight checks covered real local PDF text extraction, preserved black lettering, save/reopen, zoom/pan transforms, EPUB reflow relocation and rejection of ambiguous text anchors. The user's PDF is not included in source or test fixtures; the committed suite defaults to original fixtures, with an optional external sample path.
- Five installer cases passed: success, bad checksum, syntax failure, app replacement failure and cover replacement failure.
- Reader/passcode installation logs were read back from the Kindle. The user confirmed the reader functioning; individual passcode behaviors still need physical confirmation.
- The 586 × 880 caption-free cover, highlight candidate package and user book were transferred with byte-for-byte readback verification. Highlight runtime/touch confirmation remains pending.
- Home-screen customization and storage cleanup were device maintenance, not public reader features or files. No device state, keys or personal books are part of publication.
