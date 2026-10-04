# Third-party acknowledgments and source locations

Yomigami is independent, but its foundations are shared. Original upstream copyright
and license notices remain applicable. Naming projects here does not imply endorsement.

| Project | Contribution | Source and version | License |
| --- | --- | --- | --- |
| KOReader | Private Kindle device/widget runtime, framebuffer/input/power lifecycle, document interfaces | [v2026.07.1](https://github.com/koreader/koreader/tree/v2026.07.1), commit `9192014d8bd82a91dc1012473be0f238dedfdb54` | AGPL-3.0; component notices retained |
| Rakuyomi | Rust manga source and download engine | [v1.41.6](https://github.com/tachibana-shin/rakuyomi/tree/v1.41.6), commit `c79563b29e18a7c373d780a4af2ce1961b6184a6` | AGPL-3.0 |
| Aidoku Community sources | Bundled source adapters | [Source repository](https://github.com/Aidoku-Community/sources); exact adapter versions/hashes in `assets/sources/manifest.json` | Apache-2.0 / MIT; see `licenses/` |
| ZlibraryKO | Protocol reference for Yomigami’s own Z-Library adapter | [Inspected revision](https://github.com/ZlibraryKO/zlibrary.koplugin/tree/134b3c8d68f143316d81610ac3324a27ed2e82d6) | AGPL-3.0 |
| MuPDF and KOReader base | Native document rendering and FFI support | [KOReader base](https://github.com/koreader/koreader-base), pinned through the KOReader release’s submodule tree; [MuPDF](https://mupdf.com/) | Upstream component licenses, including AGPL |
| LuaJIT, LuaSocket, LuaSec, fonts and other runtime libraries | Language runtime, networking, text and native support | KOReader’s pinned recursive source/build tree | Respective upstream licenses |

`LICENSE` covers new Yomigami application code under AGPL-3.0-or-later. The leafy
launcher artwork, README banner and generated Reader Test are original project assets.
The screenshot gallery uses original fixture pages and sample chapter metadata.

`licenses/` contains the Aidoku adapter license texts. Other runtime notices stay in
the private runtime when the local packaging script assembles it. `runtime-lock.json`
records the official binary input checksums, while `scripts/package.py` and
`docs/runtime.patch` document Yomigami’s runtime changes. The upstream plugin frontends
are not loaded as Yomigami’s application.

The prebuilt release includes a source companion alongside the installer ZIP. See
[RELEASE-SOURCES.md](docs/RELEASE-SOURCES.md) for source trees, dependency archives,
upstream download locations, revisions and build instructions.

Book providers, Gutendex, Gutenberg and Internet Archive are external services, not
bundled catalogs or endorsements. No downloaded manga chapters, user libraries or
commercial ebooks are included in this repository.

October 2026 source work also consulted the current
[ZlibraryKO API](https://github.com/ZlibraryKO/zlibrary.koplugin/blob/main/zlibrary/api.lua)
and reviewed [annas-fetch](https://github.com/right9code/annas-fetch.koplugin).
The Anna adapter uses its [documented member API](https://annas-archive.gl/faq#api),
not the plugin scraper. Open Textbook Library uses its
[official API schema](https://open.umn.edu/opentextbooks/api-docs/library.yml).
Provider APIs and availability are independent of Yomigami.
