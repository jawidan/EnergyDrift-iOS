# Branch: ios/firebase-10.0.0

- **Library**: Firebase Analytics (firebase-ios-sdk)
- **Version**: 10.0.0 (exact, via SPM)
- **Category**: analytics
- **Scenarios available**:
  - `idle_baseline` (shared baseline, present on every branch)
  - `event_batch` — log 100 custom events (`Analytics.logEvent("ed_event", ...)`)
    with a small fixed parameter dict
  - `rich_events` — log 50 events, each with 10 parameters (mixed
    strings/ints, deterministic values)
  - `user_properties` — set 20 user properties, then log 50 events
  - `background_sync` — log 100 events, then `Task.sleep` for 60 s inside
    the timed window (captures the deferred upload window by design)
- **Compilation workarounds**: none required.
- **Notes**: This is the only category of branch where the harness is not
  byte-identical to the other branches, per §2 of the spec: it adds
  `FirebaseApp.configure()` to `EnergyDriftApp.swift`'s initializer and a
  placeholder `GoogleService-Info.plist` (see the `TODO` comment in that
  file — drop in the real file from the Firebase console before running a
  session). `FIREBASE_ANALYTICS_COLLECTION_ENABLED` is set to `true` in
  Info.plist so analytics collection is enabled. SPM product dependencies:
  `FirebaseAnalytics` (for `Analytics.logEvent`/`setUserProperty`) and
  `FirebaseCore` (for `FirebaseApp.configure()`), both resolved from the
  single `firebase-ios-sdk` package reference pinned to 10.0.0.
