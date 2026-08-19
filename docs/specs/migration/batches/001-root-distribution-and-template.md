# Batch 001 — Root, Distribution, and Template

- Node type: leaf
- Status: complete
- Batch ID: `codex-switch-migration-001`
- Change mode: Reconcile
- Source count: 3
- Source words: below 12,000
- Read when: reviewing Batch 001 sources, dispositions, targets, or status.
- Do not read when: another migration batch is active.
- Maximum size: 100 physical lines.

## Sources and dispositions

- [Legacy index](../../index.md) — `superseded`; retained as a compatibility
  forwarder to the canonical root. Source SHA-256 before migration:
  `79653b62bf2d3914375bb6988842b46df3055385a649aa71167f6a115eb69f1b`.
- [Direct distribution](../../features/direct-distribution.md) — `contract`;
  retained in place as a bounded Active leaf. Source SHA-256 before migration:
  `22734112252863d1b8657323a2b5e9cd4b70fc16d7129bb4af92fa2501ea1988`.
- [Feature template](../../templates/feature-spec.md) — `resource`; retained in
  place as non-normative authoring guidance. Source SHA-256 before migration:
  `f2e878b3604f2bdb772c4fa44f8dbaea717e90ebb1e9cc8222770eea7335aa2d`.

## Targets

- [Canonical specification root](../../README.md)
- [Feature branch](../../features/README.md)
- Batch receipt: `../receipts/001-root-distribution-and-template.md`

## Protected meaning

Public artifacts, signing, notarization, verification, release timeouts,
secret privacy, preview labeling, and non-destructive release behavior remain
unchanged. This batch changes no product implementation or observable behavior.

## Next

Batch 002 selects only `features/codex-account-status.md` and splits it at
independently selectable account responsibilities.
