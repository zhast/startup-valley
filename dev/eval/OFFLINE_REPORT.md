# Offline evaluation report

- Run: 2026-09-02T20:12:01Z
- Result: **8/8 fixtures passed**
- Objective checks: **27 passed**
- Provider calls: **0**

| Fixture | Verified behavior | Checks |
| --- | --- | ---: |
| `new-note` | Guarded write creates exact content and registers an artifact | 3 |
| `exact-edit` | Unique replacement preserves surrounding content and registers the result | 3 |
| `attached-context` | Promoted attachment is present as bounded, read-only reference context | 4 |
| `off-hours-queue` | Work persists as queued with no premature `job.started` event | 4 |
| `missing-attachment` | Missing attachment rejects before work-order creation | 3 |
| `traversal-rejected` | Parent traversal rejects without an escaped file | 3 |
| `studio-write-denied` | Direct studio write rejects without creating a file | 3 |
| `approved-promotion` | Approval copies exact content, clears pending state, and records job/artifact provenance | 4 |

The runner snapshots the studio file tree by path and SHA-256 plus the SQLite studio-file records. All seven fixtures without promotion approval preserved an exact before/after snapshot. The approved-promotion fixture was required to change that snapshot and retain its source work-order and artifact IDs.

Command: `cd harness && npm run eval:offline`
