# Try Yomigami 0.5.0

This is a device test candidate for the Paperwhite 12 running firmware 5.18.5.0.1.
The public 0.4.0 release remains available while the new features receive hardware checks.

1. Quit Yomigami before installing. Copy `yomigami-update-0.5.0-rc1.tar.gz` to Kindle storage
   and `Update Yomigami 0.5.0.sh` into `documents`. Disconnect USB and open the update book.
   The updater backs up app data/settings and keeps the library.
2. In the library, choose **+ → Storage**. Check book sizes and the manga chapter total.
   Deleting a book moves it to Recently deleted; permanently deleting it there frees space.
3. Open a book and change crop, contrast, direction or zoom. Open another book, then
   return to the first: each should retain its own settings. Manga chapters share settings
   within their series. Lighting and dark mode remain global.
4. Start a PDF/EPUB download. The confirmation shows size when the server supplies it.
   **+ → Book downloads** shows progress and offers pause, retry and cancel. Interrupt
   Wi-Fi and reconnect: temporary failures retry automatically, up to six attempts.
   Quitting saves the queue for the next launch. Servers without safe range support
   restart from the beginning; unknown source sizes cannot be predicted.
5. Connect the Kindle and phone/computer to the same trusted Wi-Fi. Open
   **PDFs → Import PDF From Anywhere** (also available under **+ → Send to Yomigami**), scan the QR or type the displayed URL in a browser, and
   select PDF, EPUB or CBZ files. Keep the Kindle transfer screen open until finished.
   Select **Done · Return to library** to see the uploaded books.

Wi-Fi transfer stays on the local network and uses HTTP with a temporary session token.
Closing the screen, sleeping or quitting stops the receiver; sessions expire after
30 minutes. Guest Wi-Fi/client isolation may prevent devices from reaching each other.
Uploads are limited to 512 MB each, validate book contents, and never overwrite an
existing filename. Interrupted phone uploads must be sent again.

Desktop checks passed for transfer recovery, per-book settings, storage, QR display
and real HTTP uploads. Phone-to-Kindle reachability and these new device flows still
need hardware confirmation.

## October reader candidate

Build with `python3 scripts/make_reader_update.py`. The result is
`dist/Yomigami-October-Reader-Update.zip`, for an existing Yomigami installation.
Extract its two folders into Kindle storage, unplug USB, and open **Update Yomigami
Reader** in the native library. KUAL is not required. Close Yomigami first.

Check an EPUB at two font sizes and after reopening, a tall manga page forward and
back, and Options → Text, notes & controls. Hold a text page, select an excerpt in
its text view, save a highlight and note, then export Markdown. Follow a manga from
its chapter screen and check Library → + → Followed series. Finally verify cover
sleep/wake, tap zones, double-tap toolbar access and both refresh categories.

No public release or successful device validation is implied by the local ZIP.
