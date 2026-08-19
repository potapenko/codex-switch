# Receipt 001 — Root, Distribution, and Template

- Node type: leaf
- Status: complete
- Batch ID: `codex-switch-migration-001`
- Contract basis: `bootstrap.legacy-spec-migration@2`
- Routing basis: `bootstrap.legacy-migration-routing@2`
- Read when: verifying or resuming after Batch 001.
- Do not read when: Batch 001 provenance is not needed.
- Maximum size: 100 physical lines.

## Source revisions

- `docs/specs/index.md` — pre-migration SHA-256
  `79653b62bf2d3914375bb6988842b46df3055385a649aa71167f6a115eb69f1b`;
  disposition `superseded` with forwarding link.
- `docs/specs/features/direct-distribution.md` — pre-migration SHA-256
  `22734112252863d1b8657323a2b5e9cd4b70fc16d7129bb4af92fa2501ea1988`;
  disposition `contract` with preserved meaning.
- `docs/specs/templates/feature-spec.md` — pre-migration SHA-256
  `f2e878b3604f2bdb772c4fa44f8dbaea717e90ebb1e9cc8222770eea7335aa2d`;
  disposition `resource` with no product authority.

## Semantic disposition

No product discrepancy was found. The legacy distribution contract remains
the intended and conservatively legacy-released behavior. Changes are limited
to Markdown routing, metadata, stable clause labels, and authoring guidance.

## Validation

- Source drift: checked before mutation.
- Markdown tree: valid with one root, eight declared nodes, and a 100-line
  maximum; every created or updated node is within the limit.
- Markdown links and root reachability: valid.
- Corpus coverage: three mapped, two deferred to named batches, with no
  duplicate or unknown source mapping.
- JSON routing state: absent before and after this batch.
- Product implementation: unchanged.

## Next

Batch 002 will reconcile the Codex account-status contract and preserve its
account lifecycle, refresh, quota/reset, local-data, and privacy boundaries.
