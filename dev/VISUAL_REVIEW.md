# Visual review loop

Run the real 1280 × 720 renderer, then inspect every PNG in `game/tests/output/visual-review/`:

```sh
/private/tmp/anthropod-godot-4.7.2/Godot.app/Contents/MacOS/Godot \
  --path game \
  --script res://tools/capture_visual_review.gd
```

The capture set is intentionally broader than the happy path.

| Capture | Acceptance focus |
| --- | --- |
| `office-hires-0.png` through `office-hires-4.png` | Each hire furnishes a purposeful area; future areas stay visible, empty, and walkable with no blocking overlay. |
| `ui-team-rail.png` | Exploration keeps only the framed portrait column plus day, time, and earned money visible; no work controls occupy the office. |
| `ui-chat.png` | The open drawer matches the selected notebook mockup: employee dossier, wood tabs, ruled conversation bubbles, fixed composer, Assign Work footer, and portrait rail. |
| `ui-work.png` | Credential state, work-order controls, and actions all fit inside the drawer. |
| `ui-journal-active.png` | Running state, usage, steering, and event stream have an obvious hierarchy. |
| `ui-journal-approval.png` | The blocking decision is prominent without pushing controls out of view. |
| `ui-journal-promotion.png` | Completed work is distinct from approval and has one clear durable-studio action. |
| `ui-studio.png` | Approved files are legible and visibly reusable. |
| `ui-artifact.png` | Read-only delivery content appears in a focused, dismissible modal over a dimmed game. |
| `ui-empty-team.png` | The founder/no-hire state is honest and does not show stale employee data. |
| `ui-off-hours.png` | Availability and queued-work language match the clock. |
| `ui-journal-queued.png` | A queued job cannot be mistaken for active work. |
| `ui-error.png` | Failure copy is visible, bounded, and does not corrupt the next state color. |

Do not accept an asset from its isolated generation preview. Every runtime prop must pass this capture loop at its actual authored scale and placement. The source-of-truth projection rules remain in `game/assets/runtime/office/ASSET_SPEC.md`.
