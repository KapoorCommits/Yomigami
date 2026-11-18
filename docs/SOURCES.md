# Manga sources — October 11 development bundle

The bundle contains 25 English-capable adapters, including 13 of the 14 requested sources. All 25 loaded in the official Rakuyomi v1.43.4 desktop engine. Loading an adapter does not prove that its website or chapter downloads work.

| Source | Version | Live search check on October 11 |
| --- | --- | --- |
| Weeb Central | 8 | 32 results |
| MangaDex | 14 | 20 results |
| Asura Scans | 19 | Not repeated in this update |
| Flame Comics | 4 | Not repeated in this update |
| Guya | 2 | Not repeated in this update |
| TCB Scans | 6 | Not repeated in this update |
| Magus Manga | 2 | Not repeated in this update |
| Hive Scans | 2 | Not repeated in this update |
| Vortex Scans | 3 | Not repeated in this update |
| Danke fürs Lesen | 3 | Not repeated in this update |
| MangaRead.org | 2 | Not repeated in this update |
| Chikari | 1 | Not repeated in this update |
| EzManga | 2 | Not repeated in this update |
| MangaBat | 9 | Not repeated in this update |
| MangaDemon | 7 | Not repeated in this update |
| MangaNato | 8 | Not repeated in this update |
| Manhuaplus.org | 1 | Not repeated in this update |
| Nyx Scans | 1 | Not repeated in this update |
| MangaFire | 8 | Not repeated in this update |
| MANGA Plus | 6 | Not repeated in this update |
| Comix | 26 | Source returned an error |
| Mangadotnet | 7 | 28 results |
| MangaKatana | 3 | 20 results |
| MangaPill | 2 | 50 results |
| Bato.to | 5 | No results for test query |

## Atsumaru

Atsumaru is **not bundled**. The adapter found in [Yomu](https://github.com/Smexhy/yomu-aidoku-sources) has a [license prohibiting repackaging and redistribution](https://github.com/Smexhy/yomu-aidoku-sources/blob/main/LICENSE). An independently licensed compatible adapter or the author's permission is needed before it can be included. No replacement is silently presented as Atsumaru.

## Install on an existing Kindle

Close Yomigami before each update. Install `Yomigami-Manga-Engine-v1.43.4.zip` first and `Yomigami-Manga-Sources-20261011.zip` second: extract on your computer, copy the extracted contents to Kindle storage, eject USB, then open the corresponding **Update Manga Engine** or **Update Manga Sources** book. The combined October update launcher, when supplied, performs these steps for you before installing the reader.

Existing custom adapters are retained. Previous source files and the engine are backed up separately. Books, bookmarks and source settings are preserved. Manga search continues to query installed sources automatically.

Comix is included but currently fails the live search check. Bato.to loads but returned no titles for the test query. Neither is advertised as working. No new chapter-download or Kindle runtime verification was completed for this bundle.

## Provenance

Modern adapters come from [Aidoku Community](https://github.com/Aidoku-Community/sources). MangaKatana, MangaPill and Bato.to come from the [legacy catalog maintained by Tachibana Shin](https://github.com/tachibana-shin/aidoku-community-sources). Exact download URLs and SHA-256 hashes are recorded in [the manifest](../assets/sources/manifest.json). License texts are in `licenses/`.
