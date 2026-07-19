# Branch: ios/sdwebimage-5.18.0

- **Library**: SDWebImage
- **Version**: 5.18.0 (exact, via SPM)
- **Category**: image_loading
- **Scenarios available**:
  - `idle_baseline` (shared baseline, present on every branch)
  - `cold_load` — clear memory + disk caches, then load a fixed 20-image list
    (mixing `/image/small`, `/image/medium`, `/image/large` with `?id=1..20`
    cache-busting query strings) sequentially through SDWebImage
  - `warm_load` — clear caches, pre-load the 20-image list once (untimed),
    then re-load the same 20 URLs (expected cache hits)
  - `concurrent_load` — clear caches, then start all 20 loads concurrently
    via a task group; `run()` returns when all complete
  - `large_images` — clear caches, then load 5 distinct `/image/large`
    (1 MB) URLs sequentially
- **Compilation workarounds**: none required.
- **Notes**: Images are loaded via `SDWebImageManager.shared.loadImage(with:options:progress:completed:)`,
  bridged from SDWebImage's completion-handler API to `async`/`await` with
  `withCheckedThrowingContinuation`, since SDWebImage does not expose a
  native `async` API. The same bridging is used across all SDWebImage
  branches for consistency. `bytesTransferred` sums the `data` byte count
  reported by the completion handler (0 for cache hits, since no bytes
  cross the network). Caches are cleared via `SDImageCache.shared.clearMemory()`
  and `clearDisk(onCompletion:)` in `setUp()`.
