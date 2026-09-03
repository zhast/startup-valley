# Visual review loop

Run the real 1280 × 720 renderer, then inspect every PNG in `game/tests/output/visual-review/`:

```sh
godot --path game --script res://tools/capture_visual_review.gd
```

The capture set is intentionally broader than the happy path.

| Capture | Acceptance focus |
| --- | --- |
| `office-hires-0.png` through `office-hires-4.png` | Each hire furnishes a purposeful area; future areas stay visible, empty, and walkable with no blocking overlay. |
| `ui-team-rail.png` | Exploration keeps only the framed portrait column plus day, time, and earned money visible; no work controls occupy the office. |
| `ui-founder-hud.png` | The selected Founder's Ledger title, live clock, movement plaque, and proximity `E · CHAT` ribbon are coherent at runtime scale and remain clear of the team rail. |
| `ui-world-speech.png` | Employee memory appears in a compact parchment speech bubble while custom name and status plaques stay readable and clear of the character. |
| `ui-chat.png` | The open drawer matches the selected notebook mockup: employee dossier, wood tabs, directional founder/employee parchment bubbles, fixed composer, Assign Work footer, and portrait rail. |
| `ui-work.png` | Credential state, custom dropdown, secondary controls, and actions all fit inside the drawer. |
| `ui-journal-active.png` | The custom current-work card, real spend meter, steering controls, event icons, and indigo scrollbar give running work an obvious hierarchy. |
| `ui-journal-approval.png` | The pinned approval card and custom decision buttons are prominent without pushing controls out of view. |
| `ui-completion-memo.png` | A real completed work order creates a compact pinned memo with the employee and artifact; its View action leads to the promotion journal. |
| `ui-journal-promotion.png` | The ribboned delivery card is distinct from approval and has one clear durable-studio action. |
| `ui-studio.png` | Approved files use custom document cards and icons, and are visibly reusable. |
| `ui-studio-empty.png` | An empty Studio uses the custom archive-tray card instead of an unframed placeholder label. |
| `ui-artifact.png` | Read-only delivery content appears inside the custom wooden reader and ruled parchment over a dimmed game. |
| `ui-empty-team.png` | The founder/no-hire state is honest and does not show stale employee data. |
| `ui-off-hours.png` | Availability and queued-work language match the clock. |
| `ui-journal-queued.png` | A queued job cannot be mistaken for active work. |
| `ui-error.png` | Failure copy is visible, bounded, and does not corrupt the next state color. |

Do not accept an asset from its isolated generation preview. Every runtime prop must pass this capture loop at its actual authored scale and placement. The source-of-truth projection rules remain in `game/assets/runtime/office/ASSET_SPEC.md`.
