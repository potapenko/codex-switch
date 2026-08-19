# CodexSwitch Specifications

- Node type: root
- Status: Active
- Revision: `codex-switch.spec-root@1`
- Read when: selecting CodexSwitch product behavior, release, or migration contracts.
- Do not read when: the task is proven unrelated to CodexSwitch product behavior.
- Maximum size: 100 physical lines.

This is the canonical Markdown entrypoint for CodexSwitch product contracts.
Branch summaries navigate only; the selected contract and its explicit
dependencies define the applicable behavior.

## Product domains

- [Feature contracts](features/README.md) — account status, account-card, and
  direct-distribution behavior.

## Migration state

- [Legacy specification migration](migration/README.md) — bounded batches,
  source dispositions, receipts, and remaining work.

## Authoring resource

- [Feature specification template](templates/feature-spec.md) — a
  non-normative starting structure for new contracts.

## Traversal

Choose the smallest matching feature node and follow only its explicit
dependencies. Product implementation, tests, and runtime do not replace the
selected Markdown contract.
