# Security policy

This is alpha software. Only the latest published source version receives fixes.

If GitHub private vulnerability reporting is enabled, use **Security → Report a
vulnerability**. Otherwise, open an issue requesting a private reporting channel
without including exploit details, credentials, private download URLs or device logs.

Yomigami stores reading state on Kindle storage. Optional Z-Library sign-in stores
session tokens locally without encryption; passwords are not intentionally persisted.
Sign out removes the saved session. Treat a copy of the data directory as private.

Remote catalogs and content providers are external services. Do not place private
credentials in source URLs or public bug reports. Third-party documents are parsed by
the pinned native runtime, which must be updated as upstream security fixes become available.
