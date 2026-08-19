# Receipt 002 — Codex Account Status

- Node type: leaf
- Status: complete
- Batch ID: `codex-switch-migration-002`
- Contract basis: `codex-switch.account-status@12`
- Migration basis: `bootstrap.legacy-spec-migration@2`
- Read when: verifying or resuming after Batch 002.
- Do not read when: Batch 002 provenance is not needed.
- Maximum size: 100 physical lines.

## Source revision

- `docs/specs/features/codex-account-status.md` — pre-migration SHA-256
  `9d17cf8e9d7164a5e0c1658a21a0239d57be09de8fa39bd226840241d63e9679`;
  disposition `contract`, retained as the canonical parent path.

## Reconciled basis

The source was Active at revision 12 and internally consistent. No semantic
delta, product fork, or missing authority was found. Ten children separate
independently selectable responsibilities while preserving every source rule,
the exact four historical deltas, privacy boundaries, and released behavior.

## Validation

- Source drift: checked before mutation.
- Legacy normative-item coverage: 88 of 88, with no omission.
- Created or updated nodes: 32–89 physical lines, all within the limit.
- Markdown tree: valid with one root, 21 declared nodes, and 44 links.
- Corpus coverage: 16 of 17 current non-migration Markdown paths mapped;
  account card is the sole residual, with zero duplicates or unknown mappings.
- JSON routing state: absent before and after this batch.
- Product implementation and protected account-card source: unchanged.

## Next

Batch 003 will reconcile the account-card contract without reopening completed
Batch 002 source bodies.
