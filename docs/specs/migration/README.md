# Legacy Specification Migration

- Node type: root
- Migration ID: `codex-switch-legacy-spec-migration`
- Status: complete
- Change mode: Reconcile; Discover only for missing or conflicting authority
- Approved by: user, 2026-08-19
- Source specification root: `docs/specs`
- Maximum sources per batch: 3
- Maximum source words per batch: 12,000
- Read when: starting, resuming, reviewing, or completing this migration.
- Do not read when: the task is outside the legacy specification migration.
- Maximum size: 100 physical lines.

## Contract Change Envelope

- Authorized outcome: convert all five legacy Markdown documents into a
  bounded linked specification tree.
- Authorized domains: specification routing and faithful contract structure.
- Protected domains: account lifecycle, privacy, refresh, quota/reset,
  account removal, accessibility, distribution, and release provenance.
- Product implementation authorization: forbidden.
- Allowed delta: navigation, metadata, stable clause IDs, semantic splitting,
  and Markdown migration evidence without behavior changes.
- Forbidden delta: product code, behavior, credentials, global configuration,
  tests, Xcode settings, or unrelated files.

## Corpus baseline

- Documents: 5
- Words: 5,446
- Lines: 693
- Declared nodes before migration: 0
- Oversized legacy contracts: 2
- JSON specification state: none

## Batches

- [001 — root, distribution, and template](batches/001-root-distribution-and-template.md)
  — complete; three sources dispositioned.
  [Receipt 001](receipts/001-root-distribution-and-template.md) records hashes,
  semantic disposition, and checkpoint validation.
- [002 — Codex account status](batches/002-codex-account-status.md) — complete;
  one 400-line source split by responsibility.
  [Receipt 002](receipts/002-codex-account-status.md) records fidelity and
  checkpoint validation.
- [003 — account card](batches/003-account-card.md) — complete; one 218-line
  source split by responsibility.
  [Receipt 003](receipts/003-account-card.md) records fidelity and terminal
  corpus validation.

## Resume

Read this root, the current batch, its latest receipt, and only that batch's
linked sources and direct dependencies. Do not reload completed source bodies.

## Completion

All five legacy sources have terminal dispositions. Every Active contract is
reachable from the canonical root, all declared nodes are within 100 lines,
coverage and links resolve, and no JSON routing state exists.
