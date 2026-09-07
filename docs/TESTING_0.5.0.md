# Try Yomigami 0.5.0

This is a device test candidate for the Paperwhite 12 running firmware 5.18.5.0.1.
The public 0.4.0 release remains available while the new features receive hardware checks.

1. Quit Yomigami before installing. Copy `yomigami-update-0.5.0.tar.gz` to Kindle storage
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
   **+ → Send to Yomigami**, scan the QR or type the displayed URL in a browser, and
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
