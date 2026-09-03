# Visual review loop

Run the real 1280 × 720 renderer, then inspect every PNG in `game/tests/output/visual-review/`:

```sh
godot --path game --script res://tools/capture_visual_review.gd
```

The capture set is intentionally broader than the happy path. Every image now
uses an isolated `GameMain` fixture; the original 21 states remain and six
product-coherence states bring the run to 27. See `dev/UI_PRODUCT_AUDIT.md` for
the annotated findings and contact-sheet command.

| Capture | Acceptance focus |
| --- | --- |
| `office-hires-0.png` through `office-hires-4.png` | Each hire furnishes a purposeful area; future areas stay visible, empty, and walkable with no blocking overlay. |
| `ui-team-rail.png` | Exploration keeps only the framed portrait column plus day, time, and earned money visible; no work controls occupy the office. |
| `ui-founder-hud.png` | The selected Founder's Ledger title, live clock, movement plaque, and proximity `E · CHAT` ribbon are coherent at runtime scale and remain clear of the team rail. |
| `ui-world-speech.png` | Employee memory appears in a compact parchment speech bubble while custom name and status plaques stay readable and clear of the character. |
| `ui-chat.png` | The notebook drawer distinguishes no-tools conversation from the contextual Create work order action. |
| `ui-chat-long.png` | Long bounded history scrolls without clipping the fixed composer. |
| `ui-chat-to-assignment.png` | The latest six messages become an editable local work-order draft. |
| `ui-chat-active-readonly.png` | Active work makes Chat read-only and routes updates to Activity. |
| `ui-work.png` | Assign contains the work-order controls and a clear tools/files/budget consequence. |
| `ui-keyboard-focus.png` | Focus is visible and the focused control remains within the drawer. |
| `ui-journal-active.png` | Activity owns steering, spend, usage, event icons, and live state. |
| `ui-journal-approval.png` | The pinned approval card and custom decision buttons are prominent without pushing controls out of view. |
| `ui-completion-memo.png` | A real completed work order creates a compact pinned memo with the employee and artifact; its View action leads to the promotion journal. |
| `ui-journal-promotion.png` | The ribboned delivery card is distinct from approval and has one clear durable-studio action. |
| `ui-notification-dismissed.png` | Reviewing or clearing a delivery leaves no stale toast. |
| `ui-studio.png` | Approved files use custom document cards and icons, and are visibly reusable. |
| `ui-studio-empty.png` | An empty Studio uses the custom archive-tray card instead of an unframed placeholder label. |
| `ui-artifact.png` | Read-only delivery content appears inside the custom wooden reader and ruled parchment over a dimmed game. |
| `ui-empty-team.png` | The founder/no-hire state is honest and does not show stale employee data. |
| `ui-off-hours.png` | Availability and queued-work language match the clock. |
| `ui-journal-queued.png` | A queued job cannot be mistaken for active work. |
| `ui-connect.png` | First-run connection is separate from employee Assign. |
| `ui-error.png` | Connectivity remains a global rail state and does not replace job meaning. |

Do not accept an asset from its isolated generation preview. Every runtime prop must pass this capture loop at its actual authored scale and placement. The source-of-truth projection rules remain in `game/assets/runtime/office/ASSET_SPEC.md`.

For movement, temporal feedback, depth, pixel sampling, and the prioritized next
asset batch, run the complementary audit in `dev/POLISH_AUDIT.md`. Its world and
UI movie suites do not replace these 21 static layout states.
