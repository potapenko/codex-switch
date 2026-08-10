# Swift engineering rules

- Target macOS 14 or later.
- Keep Swift files focused and normally below 300 lines; avoid force unwraps
  and global mutable state.
- SwiftUI describes state only. Process launch, JSON-RPC, persistence, and
  browser opening belong in focused services.
- Use `async`/`await`; main-actor UI state changes stay on the main actor.
- Store only profile metadata and cached, non-secret snapshots in Application
  Support. Authentication is owned by Codex in the corresponding isolated
  Codex profile directory.
- Never log OAuth URLs, tokens, account payloads, or email addresses.
