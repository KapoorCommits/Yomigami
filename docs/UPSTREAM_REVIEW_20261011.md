# Rakuyomi review — October 11, 2026

Compared Yomigami's pinned v1.41.6 engine with [Rakuyomi v1.43.4](https://github.com/tachibana-shin/rakuyomi/releases/tag/v1.43.4), using the upstream [comparison](https://github.com/tachibana-shin/rakuyomi/compare/v1.41.6...v1.43.4).

| Upstream change | Relevance to Yomigami |
| --- | --- |
| Apply cookies.json to WASM image requests (#340) | Relevant to image downloads when a source needs an existing cookie. Included by updating the engine. |
| Initialize process_page_image on lazy source startup (#342) | Relevant to adapters that process images. Included by updating the engine. |
| Reload Aidoku source when settings change (#371) | Relevant to source-language/settings changes. Included by updating the engine. |
| Reconnect Wi-Fi before retrying source lists (#341) | Rakuyomi frontend-specific; Yomigami has its own request UI and reports failed requests. No plugin UI copied. |
| Chapter read-state sync and empty chapter selection (#357, #356) | Yomigami owns progress and deduplicated download queues; no Rakuyomi reader state is shared. |
| Source-list close button / custom dialogs (#377, #375) | Different UI implementation; Yomigami close behavior is covered by its reader suites. |
| Optional black reader background (#372) | Yomigami already has a global light/dark toggle. |
| Cookie-bot migration and cold-start optimization (#380, v1.43.4) | Hosted Telegram service; not Yomigami's page-rendering path. |

The update does not import KOReader ReaderUI or Rakuyomi's chapter-turn callbacks. Kindle Home modifications are outside this update.
