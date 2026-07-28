# Swift engineering rules

- Target macOS 14 or later and use native SwiftUI plus narrowly scoped AppKit.
- Keep Swift files focused and normally below 300 lines; avoid force unwraps
  and global mutable state.
- SwiftUI describes state only. Process launch, JSON-RPC, persistence, and
  browser opening belong in focused services.
- Use `async`/`await`; main-actor UI state changes stay on the main actor.
- Every child-process and network-adjacent boundary needs a bounded timeout.
- Store only profile metadata and cached, non-secret snapshots in Application
  Support. Authentication is owned by Codex in the corresponding isolated
  Codex profile directory.
- Default logs must be concise and never include OAuth URLs, tokens, account
  payloads, or email addresses.
