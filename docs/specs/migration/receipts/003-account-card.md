# Receipt 003 — Account Card

- Node type: leaf
- Status: complete
- Batch ID: `codex-switch-migration-003`
- Contract basis: `codex-switch.account-card@5`
- Migration basis: `bootstrap.legacy-spec-migration@2`
- Read when: verifying Batch 003 or final migration completion.
- Do not read when: account-card provenance and migration status are not needed.
- Maximum size: 100 physical lines.

## Source revision

- `docs/specs/features/account-card.md` — pre-migration SHA-256
  `90756ff2a2e5c22bd231af4ecb2b055d1102add2504da0c486cd43f81a3bdd5a`;
  disposition `contract`, retained as the canonical parent path.

## Reconciled basis

The source was Active at revision 5 and internally consistent. Exact precedence
keeps account data, state, ordering, refresh, authentication, persistence, and
popover geometry under `codex-account-status@12`. No semantic delta, product
fork, or missing authority was found.

## Validation

- Source drift: checked before mutation.
- Legacy normative-item coverage: 62 of 62, with no omission.
- Goal, precedence, design-evidence limit, and five deltas: represented.
- Created or updated account-card nodes: 22–71 lines, all within the limit.
- Markdown tree: valid with one root, 32 declared nodes, and 68 links.
- Complete coverage: 25 of 25 non-migration Markdown paths mapped, with zero
  missing, duplicate, or unknown mappings across three batches.
- Final census: 25 non-migration documents, 6,978 words, 1,052 lines, and zero
  oversized documents.
- JSON routing state: absent before and after this batch.
- Product implementation: unchanged.

## Terminal state

All five legacy sources have terminal dispositions, every Active contract is
reachable, and no deferred migration item remains.
