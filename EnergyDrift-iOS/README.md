# Branch: ios/alamofire-5.11.0

- **Library**: Alamofire
- **Version**: 5.11.0 (exact, via SPM)
- **Category**: networking
- **Scenarios available**:
  - `idle_baseline` (shared baseline, present on every branch)
  - `sequential_get_small` — 50 sequential GETs of `/json/small`
  - `sequential_get_large` — 10 sequential GETs of `/json/large`
  - `post_batch` — 50 sequential POSTs to `/post` with a 1 KB JSON body
  - `concurrent_get` — 20 concurrent GETs of `/json/standard` via a task group
  - `image_download` — 10 sequential downloads of `/image/medium` as raw data
- **Compilation workarounds**: none required.
- **Notes**: Requests are issued via `AF.request(URLRequest)` bridged from
  Alamofire's completion-handler API (`.responseData`) to `async`/`await`
  with `withCheckedThrowingContinuation`, since native `async` support was
  not yet part of Alamofire's public API at this pinned version. The same
  bridging is used across all Alamofire branches for consistency. All
  requests set `URLRequest.cachePolicy = .reloadIgnoringLocalCacheData` and
  `setUp()` clears `URLCache.shared` so every request hits the mock server.
