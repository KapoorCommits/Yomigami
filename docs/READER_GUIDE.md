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
