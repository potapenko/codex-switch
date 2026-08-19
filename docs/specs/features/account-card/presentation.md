# Account Card Presentation

- Node type: leaf
- Status: Active
- Contract: `codex-switch.account-card@5`
- Clause: `ACARD-PRESENTATION-1`
- Read when: card hierarchy, grouping, sizing, or design evidence is in scope.
- Do not read when: removal confirmation or refresh execution alone is in scope.
- Maximum size: 100 physical lines.

## ACARD-PRESENTATION-1 — Hierarchy

- Each account is one compact, system-adaptive rounded surface. The surface
  uses native SwiftUI material and a restrained semantic stroke; it must remain
  legible in light and dark appearances and must not hardcode a white theme.
- The heading keeps the account label on one middle-truncated line, followed
  by a quiet plan capsule when a plan exists, a fixed manual-refresh slot, and
  a trailing trash-symbol button.
- When a snapshot exists, the first divided section pairs the existing
  text-bearing remaining-percentage badge with its reset date and time. The
  badge may add a small determinate ring for faster scanning, but the percentage
  text and existing availability colour bands remain authoritative.
- A second divided section pairs the earned-reset badge, when returned, with
  the existing whole-minute **Updated** text. Missing quota, credits, reset
  time, error, cached, sign-in-required, and signing-in states retain their
  existing product meaning and actions.
- Non-control card space remains a valid native list drag area. Card styling
  must not change list order, row measurement, the surrounding list, popover
  sizing, header, footer, settings, or refresh presentation.

The selected ImageGen reference at
`artifacts/ui-redesign/pass-1/generated-references/account-card-reference.png`
is design evidence for hierarchy, grouping, and action priority only. Its
fixed white palette, sample values, scale, and raster appearance are not
product requirements.

List geometry and quota meaning depend on [Profile list and popover](../codex-account-status/profile-list-and-popover.md)
and [Quota and reset display](../codex-account-status/quota-and-reset-display.md).
