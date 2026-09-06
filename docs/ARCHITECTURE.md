# Architecture and code review

## Requirement and decision

Yomigami is a separate application, not a `.koplugin`, and has no runtime reference
to the user's installed KOReader. It owns library state, navigation, source requests,
settings, and launch lifecycle. A pinned private runtime supplies Kindle input,
framebuffer refresh, fonts/widgets and MuPDF. Upstream application updates cannot
replace those private files. This removes update coupling without rewriting years
of device-specific e-ink and PDF support.

## Origin of the navigation design

The prototype investigated chapter transitions caused by shared KOReader paging hooks.
Rakuyomi wraps reader events and document switching; Yomigami instead owns one-based
page state and explicit chapter boundaries. The investigation did not isolate a single
upstream change as the definitive cause of every reported transition.

## Reviewed source areas

KOReader: entry/bootstrap and data directories; document/PDF/MuPDF adapter;
ReaderUI and paging event integration; widget menus/input/layout; UI event manager;
Kindle detection/PW6 initialization, touch, LIPC/power/suspend, screensavers;
Kindle shell wrapper, framework pause/resume, exit cleanup and updates; build
metadata and native submodule boundaries.

Rakuyomi: repository architecture/build instructions; Lua ReaderUI bridge,
chapter listing/opening, CBZ extension, backend API and Unix process transport;
Rust server bootstrap, listener, router, DTOs; source catalog/install/search;
chapter jobs, polling/cancellation, download results, storage filenames/posters;
SQLite/settings and default catalogs; release assets and macOS tooling.

The checked-out default branches are larger than the pinned shipped releases.
`SOURCE_INVENTORY.csv` inventories tracked files and hashes. Inventory is not a
claim of line-by-line semantic review. All repositories were mapped; the
integration-critical areas above were read in depth. Translation catalogs,
all third-party source runtimes, every plugin and all platform implementations
were not exhaustively reviewed. The base submodule was fetched; all nested
third-party build dependencies were not compiled locally.

## Application boundaries

`navigation.lua`: validated one-based page state, explicit end/start results,
fit-width panning before a page turn. It consumes no KOReader paging events.
`document.lua`: opens native MuPDF documents, counts pages, renders a bounded
viewport, closes native page objects and releases buffers.
`storage.lua`: natural sort, bounded directory traversal without symlink following,
copy-only import and temporary-file/rename JSON writes.
`main.lua`: original library/reader, menu lifecycle, error states, source flows.
`catalog.lua`: version-pinned JSON contract, percent-encoded path components,
loopback HTTP and bounded request timeout.
`sleep.lua`: own overlay and progress save; underlying Kindle powerd handles sleep.
`boot.lua`: initializes private device/widget runtime without upstream application.

At most six cover buffers and one reader viewport are retained. Covers are loaded
lazily per shelf and freed on shelf/document changes. Page turns use partial refresh with a full refresh every six turns and native
swipe animation where supported. The user confirmed smooth page turns on the Kindle.
The reading toolbar provides Library, Options, Hide and Quit; a center tap toggles
its visibility and rerenders to the available viewport.

The Rust source server owns separate SQLite/source/download directories and binds
127.0.0.1:18787. Source changes can still cause independent failures. This design
removes KOReader upgrade coupling, not the need to maintain manga-source adapters.

## Packaging and lifecycle

The runtime starts from `/mnt/us/yomigami/runtime`; `KO_HOME` points to
`/mnt/us/yomigami/data/runtime`. No default plugin frontend is bundled. Runtime
update execution is disabled. Temporary wrapper/framebuffer files and LIPC client
names are namespaced. The launcher's process lock prevents duplicate Yomigami runs.
It starts/stops only its own source-engine child. Kindle framework restoration
remains in the pinned, adapted upstream shell wrapper.

The first-run installer checks a SHA-256 digest, extracts into a fresh staging
directory and moves the complete private app into place. It refuses to replace an
existing installation. Source archives/commits and all modifications remain locally
available for review and corresponding-source preparation before public distribution.

Version 0.2.0 adds reading_features.lua, lighting.lua, requests.lua and downloads.lua.
Network requests use bounded child processes; the UI polls without blocking.
The saved queue limits active chapters to three and pauses scheduling below 512 MB free.
Adapters and hashes are recorded in assets/sources/manifest.json, obtained from
https://aidoku-community.github.io/sources/ . Their upstream source repository is
https://github.com/Aidoku-Community/sources .

## Book discovery (0.4.0)

`books.lua` provides the PDF/EPUB browser; `book_sources.lua` handles Gutendex/Gutenberg,
public Internet Archive metadata and explicit file links. `zlibrary.lua` is an independent
protocol adapter informed by https://github.com/ZlibraryKO/zlibrary.koplugin (AGPL-3.0).
No upstream plugin UI or credential files are packaged. Sign-in stays in the native app.
`book_http.lua` adds CA-chain and DNS SAN hostname verification to LuaSec connections.
Authenticated API redirects are refused; download cookies are scoped to the originating host.
