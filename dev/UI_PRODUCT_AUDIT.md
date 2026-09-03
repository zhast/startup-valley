# Startup Valley UI product audit

This audit treats the 1280 × 720 vertical slice as one player journey rather
than a collection of individually attractive panels. It verifies the office,
team rail, employee drawer, connection flow, bounded chat, work orders,
Activity, approvals, deliveries, Studio, artifact reader, and failure recovery.

The 21 original review states remain covered. Six isolation and edge-case
fixtures expand the current run to 27 captures: long chat, chat-to-assignment,
active-job read-only chat, keyboard focus, dismissed notification, and first-run
connection. Every capture creates a new `GameMain`; fixtures never share job,
clock, employee, notification, or worker state.

## Runbook

Use the real renderer for screenshots:

```sh
godot --path game --script res://tools/capture_visual_review.gd
dev/tools/build_ui_product_audit.sh
```

The ignored output is written to:

- `game/tests/output/visual-review/*.png`
- `game/tests/output/ui-product-audit/contact-sheet.png`

Run the deterministic checks separately:

```sh
godot --headless --path game --import
godot --headless --path game --script res://tools/validate_project.gd
godot --headless --path game --script res://tests/run_all.gd
```

## Findings and acceptance

Coordinates are in the authored 1280 × 720 viewport. “Drawer” is
`x = 782–1149`; “rail” is `x = 1150–1279`.

| ID | Priority | Baseline evidence | Implemented correction | Acceptance result |
| --- | --- | --- | --- | --- |
| UI-01 | P0 | Drawer, HUD, status plaques, and reader used Tiny5 at 9–15 px and body copy at 14 px (`ui-chat`, drawer and rail). | Tiny5 is restricted to display text at 18 px or larger. Nunito Sans is 16 px for body copy and 14 px for metadata. Automated traversal rejects smaller text. | Pass: typography test and all 27 captures at 100% scale. |
| UI-02 | P0 | The 832 × 576 office at `(32, 70)` floated in a black debug canvas with a cyan outline (`office-hires-0` through `4`). | A native 1280 × 720 landscaped campus is now the world ground plane. The normalized 832 × 576 office cutaway sits at `(0, 72)` without an outline or black margins. | Pass: full-screen texture assertion; office-stage captures expose no black backdrop. |
| UI-03 | P0 | `Send`, `Assign Work`, and two separate update composers had overlapping meaning (`ui-chat`, `ui-work`, `ui-journal-active`). | Chat says “Conversation only — no tools or files,” emits only `chat.send`, and exposes a contextual **Create work order** after a reply. Assign confirms tools/files/budget and emits only `job.start`. Activity alone emits `job.steer`. | Pass: signal-routing tests and chat/assignment/active-chat captures. |
| UI-04 | P0 | Queued employees could read as working; worker errors replaced job state; completion notices leaked into later screenshots (`ui-journal-queued`, `ui-error`). | One precedence model now resolves attention → running → queued → schedule → available. Connectivity is a separate rail badge and Settings affordance. Every screenshot uses a fresh fixture. | Pass: queued/working exclusion test and isolated duplicate-state captures. |
| UI-05 | P1 | OpenRouter credentials occupied employee work-order space (`ui-work`, drawer). | A one-time **Connect AI** parchment screen owns key setup; Settings reopens it. Assign contains only the work order and its consequence. | Pass: `ui-connect.png` and `ui-work.png`. |
| UI-06 | P1 | `Work`, `Journal`, and `Files` obscured the product model while Files called itself Studio. | Tabs are **Chat, Assign, Activity, Studio** and all four fit without scroll arrows. | Pass: exact tab-title test and 40 px tab-target assertion. |
| UI-07 | P1 | A token-shaped meter looked like fake job progress and raw token detail dominated the card. | The meter is labeled **AI spend today** with cost; raw token totals are secondary **Usage details** text. | Pass: active and queued Activity captures. |
| UI-08 | P1 | Employee rail states were whole baked bitmaps, making selection, status, and future hires brittle. | Rail heading, employee card, portrait frame, name plaque, selected border, status icon, and attention badge are independent runtime components. | Pass: modular texture/selection tests and rail captures. |
| UI-09 | P1 | Artifact files displayed literal Markdown markers in a heavy modal. | The reader parses headings, paragraphs, lists, and fenced code into a single scrolling notebook surface with a 44 px close target. | Pass: Markdown assertion and `ui-artifact.png`. |
| UI-10 | P1 | Completion banners remained across unrelated tabs and fixtures. | Completion is a six-second parchment toast; the rail keeps durable attention until review. Viewing, promotion, employee removal, and fixture reset clear the toast. | Pass: lifecycle test and `ui-notification-dismissed.png`. |
| UI-11 | P2 | Stage-four detail accumulated on the right while the left remained visually quiet; mixed filtering softened the room. | The archive moved left, the campus carries detail outside the room, runtime art uses nearest sampling, and the room shell is exported at its exact display size. | Pass: office-stage captures and exact texture-size validation. |
| UI-12 | P2 | The title and movement instructions read as permanent prototype chrome. | The title plaque is removed. The movement plaque is onboarding-only and fades permanently after the first movement input. | Pass: HUD test and `ui-founder-hud.png`. |

## Interaction contract

| Surface | Player expectation | Allowed worker method |
| --- | --- | --- |
| Chat | Think aloud with one teammate; no tools or files. | `chat.send` |
| Create work order | Convert the latest bounded discussion into an editable local draft. | None until confirmation |
| Assign | Confirm a substantial job that can use tools, create files, and spend the configured budget. | `job.start` |
| Activity | Review events, approve, steer, cancel, and inspect usage for the one active job. | `job.steer`, approval, cancellation, artifact methods |
| Studio | Reopen durable files explicitly added from completed jobs. | Guarded Studio/artifact reads |

The worker protocol, persistence model, bounded Pi sessions, and stdio JSONL
boundary are unchanged.

## Visual acceptance checklist

- The office and campus cover the viewport beneath UI at all times.
- The 130 px team rail remains visible; the 368 px drawer overlays the world.
- Persistent HUD contains day, time, and money only.
- Essential parchment text uses a tested 4.5:1 color pair and status never relies
  on color alone.
- Chat is read-only while the selected employee owns an active work order and
  links directly to Activity.
- Assign switches to **Queue for 13:30** or **Queue for 08:00** outside work hours.
- All primary controls and tabs have at least a 40 px target; focus remains visible.
- No fixture inherits a prior toast, error, promotion, worker, or job state.
- World sprites and raster UI use nearest sampling; Nunito Sans remains antialiased.

## Raster provenance

`campus-surround-master.png` was generated as an original Startup Valley source
master with the built-in image generation model, using the existing office shell
only as a projection, palette, and lighting reference. It was cropped to a native
1280 × 720 runtime ground plane by `dev/tools/build_polish_assets.sh`. The office
shell was normalized from its preserved source master to exactly 832 × 576.

Source prompt:

> Create an original 16:9 cozy-tech pixel-art landscaped Silicon Valley campus
> surround for the provided Startup Valley office cutaway. Match its oblique
> orthographic projection, warm daylight, crisp pixel density, and walnut,
> charcoal, cream, Indigo, Cerulean, restrained Vermilion, and Chartreuse palette.
> Compose calm paths, hedges, trees, planters, and a small water edge around an
> empty central footprint, with denser detail toward the outer and right edges.
> No UI, text, logos, characters, building, frame, black background, watermark,
> or copied franchise elements.
