# Reader guide

This describes the latest development source. The published 0.4.0 installer predates many of these features.

## Highlights and notes

Hold a page in an EPUB or text-based PDF. In the text viewer, hold and drag to select a passage, then choose **Save highlight** or **Add note to highlight**. The reader shades the selected words light grey on the original page. Selection currently happens in the text viewer, not by dragging directly on the rendered PDF.

Open **Options → Text, notes & controls → Highlights & notes** to read entries, edit notes, jump to a passage, delete entries, or export Markdown. Exports live in `yomigami/data/exports`. Earlier excerpt-only entries remain available without on-page shading. Ambiguous text anchors are not painted in a potentially incorrect location. Scans without a text layer support page notes but not OCR selection.

## Wi-Fi import

Use **PDFs → Import PDF From Anywhere**, or **Library → + → Send to Yomigami**. Connect the sending device to the same trusted Wi-Fi, scan the QR code or type the exact displayed URL, and select PDF, EPUB or CBZ files. Keep the receiving screen open until completion, then return to the library.

Transfers use HTTP with a temporary session token, expire after 30 minutes, and stop on closing the transfer screen, sleeping or quitting. Uploads are limited to 512 MB each and never overwrite an existing filename. Guest networks may isolate devices. This is a browser upload, not AirDrop; interrupted uploads must be resent.

## Storage and downloads

**Library → + → Storage** shows book and manga storage use. Moving an item to Recently deleted retains its bytes until permanent deletion. Back up anything you want to keep before emptying trash.

Manga and PDF/EPUB downloads have persistent queues. PDF/EPUB resume requires server support; otherwise retry starts over. Downloads stop when the app closes and can continue after reopening. Follow a manga from its chapter screen, then use **+ → Followed series** to check for missing chapters and choose downloads.

## Passcode

Use **Options → Passcode** to enable, change or disable a 4–8 digit code. The current code is required before changing or disabling it. Five incorrect attempts trigger a 30-second delay. A salted PBKDF2-SHA256 verifier is stored, not the code itself.

The lock protects app startup, not files on USB or an already-open app after sleep. If you forget it, quit Yomigami and remove only `yomigami/data/passcode.json` over USB. That resets the interface lock without deleting books or progress.

## Reading settings

Crop, contrast, direction and zoom are saved per book or manga series. EPUB font size uses the actual reader viewport. Reflow preserves reading position approximately. Brightness, warmth and theme stay global.

Options also provides separate manga/text refresh intervals, tap zones, optional pre-rendering and a book-cover sleep screen. In whole-page-forward mode, double-tap to reveal the toolbar.

## Tighter page fit (October 11 development update)

Open **Options → Fit width ▾ → Edge-to-edge**. This removes detected blank borders and fills the screen width, with a tiny safety allowance around content. Selectable PDF text is also included in the crop bounds so faint text is not removed simply because the preview missed it. The setting is remembered for each book or series.

If a page is taller than the screen, turn or swipe to see its lower part before the next page. No content is deliberately discarded to force a full-screen shape. A watermark or printing mark near an edge can leave some blank space because the reader preserves it. Choose **Fit page** with **Auto-crop off** to see the entire original page at once.

Diagonal swipes now work like horizontal swipes. The hardware page transition also covers scrolling within a tall page. Scheduled full refreshes still briefly flash to clear ghosting; they intentionally do not animate.

Page turns refresh before saving progress. Small reading-position checkpoints are written after 250 milliseconds of inactivity, avoiding a rewrite of the entire library state on every turn. They are recovered at startup and folded into the main state when leaving a book, quitting or suspending. An unexpected loss of power during that short interval can lose the most recent turn, while the last durable save and backup remain available. Pre-rendering starts after a short idle interval and yields between pages. Physical animation smoothness still needs confirmation on the Kindle.

## Clear the download queue

In manga **Downloads**, choose **Cancel all** to stop active and waiting chapters, or **Clear failed & queued** to remove failed, waiting and cancelled entries. Completed books are kept. Clearing does not stop active jobs: use Cancel all first if you want an empty unfinished queue.

PDF/EPUB downloads have the same controls under **Cancel all / Clear failed & queued**. Cancelled book transfers remove their partial files. Manga cleanup removes known incomplete chapter archives; source-engine image caches are not erased indiscriminately. Each bulk action asks for confirmation.

Download screens perform one full refresh when opened, then update only as progress changes. Background screens do not draw over menus.

## Search, new chapters and quick highlights (November 12)

Manga search puts exact titles first within the results returned by the sources, then phrase matches, all-word matches and broader matches. The clear icon sits inside the search field without a square border and clears the results as well as the query.

Online manga already downloaded into your library automatically check for new chapters while Yomigami is running. Checks start shortly after launch and run at most once per series every six hours. Opening the online chapter list also detects new chapters immediately. New chapters enter Downloads and join the library once their download completes. Normal pause, storage and download rules still apply. This does not wake a sleeping Kindle or run after quitting Yomigami.

The first successful check uses the highest downloaded chapter number to avoid downloading the whole missing back catalogue. Without usable chapter numbers, that check establishes a baseline and later unseen chapter IDs are added. To turn this off for a series, open Library → + → Followed series / Check updates, select the series and switch Auto-download new chapters off.

In a text-based PDF or EPUB, double-tap a paragraph to save a grey highlight directly on the page. Crop, zoom and scroll position are accounted for. Paragraph boundaries are inferred from line spacing and indentation; use Select text for precise selection in complex layouts. Repeated double-taps do not create duplicate highlights. Image-only scans have no selectable text and need OCR before this can work. Manga keeps immediate page taps; text books wait briefly to distinguish a single tap from a double tap.

## Weekly chapter schedule (November 16 update)

Automatic library checks default to Sunday at 10 PM and Monday at 6 PM, India time (UTC+05:30). Select the weekly schedule or the previous six-hour interval in Library → + → Followed series / Check updates → Automatic download schedule.

Checks run in the background while Yomigami is running. If a slot was missed, the latest due check catches up after reopening. Successful checks are recorded per series so they do not repeat during that slot; failed checks retry no more often than every 15 minutes. Only eligible library series are checked. Existing pause, disk-space, duplicate prevention and per-series opt-out rules still apply.

This update does not install a system service, wake a sleeping Kindle, turn Wi-Fi on automatically, or run after the app exits. Wake alarms, unattended Wi-Fi and independent engine startup still require hardware integration and validation. A weekly UI timer alone must not be described as an always-running scheduler.
