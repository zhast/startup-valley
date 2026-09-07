# Native floor material study — 2026-09-04

## Decision

Keep the production floor unchanged. Cream terrazzo is the strongest staged alternative for a brighter cozy-tech office; walnut and cork are weaker default choices at their current values/texture density. **None of the three candidates is runtime-approved:** all fail the existing exact opposite-edge floor contract, even though a conspicuous hard seam was not visible in the native room captures.

This is a material-only comparison in actual `GameMain`/`OfficeArchitecture`, after the archive production activation. It is not the earlier, frozen [08:49 regression checkpoint](REGRESSION_CHECKPOINT_0849.md). The current catalogue SHA-256 is `962d47f9fd3867328f3f293351fbb3124e6053f2d156fc20e97ee856cce09319`; the harness proves it and the logical layout remain unchanged during this study.

## Reproducible evidence

- [Dev capture](../../game/tools/capture_native_floor_study.gd) and [headless entry point](../../game/tests/test_native_floor_materials.gd): disposable real GameMain instances, null worker transport, no personal save, no paid/provider calls.
- [Rendered manifest](../../game/tests/output/native-floor-study/manifest.json): **167 checks, zero failures; 3,544,640 actual pixel checks; 16 native 1280×720 captures**, plus four nearest-neighbor comparison contacts.
- [Headless result](../../game/tests/output/native-floor-study/results-headless.json): **64 checks, zero failures**. The headless result contains state/material measurements, not purported renderer evidence.
- [Deterministic rebuild](../../game/tests/output/native-floor-study/rebuild.json): the existing [builder](../tools/build_floor_materials.sh) regenerated all **nine native/repeat/4× files byte-identically** from the preserved sources.
- [Empty office comparison](../../game/tests/output/native-floor-study/comparison-hires-0-office.png), [two-employee office](../../game/tests/output/native-floor-study/comparison-hires-2-office.png), [mature office](../../game/tests/output/native-floor-study/comparison-hires-4-office.png), [open Chat](../../game/tests/output/native-floor-study/comparison-hires-2-chat.png). Contacts are half-size comparisons, not readability acceptance images; individual images linked in the manifest are native size.

Every individual capture was inspected at 1280×720: baseline, terrazzo, walnut and cork at hire stages 0/2/4; all four materials with Mina's Chat open at stage 2. Stage 4 means the mature furniture layout with the supported two-person roster, not fabricated additional employees.

Only `main.room.architecture.floor_art` is overridden, on each local instance. The floor uses the existing 32-pixel logical cells, 128-pixel repeating plate, nearest filtering and global scale 1. Logical floor/walls, furniture, collision, navigation, actors, input/UI composition and production defaults are not modified. Each fixture restores the original floor reference before teardown.

## Source and native contract

Root generated the originals before this study; this task made **zero ImageGen requests**. The existing builder point-resamples the 1254×1254 RGB masters to 128×128 and quantizes without dithering to at most 12 colors. Sources/prompts were retained unchanged:

| Candidate | Preserved source and prompt | Native export | Colors |
|---|---|---|---:|
| Cream terrazzo | [Master](../../game/assets/source/overnight-20260904/materials/cream-terrazzo-floor-v1.png), [prompt](../../game/assets/source/overnight-20260904/materials/cream-terrazzo-floor-v1.md) | [128×128](../../game/tests/fixtures/material-concepts/overnight-v1/cream-terrazzo-floor-v1.png) | 12 |
| Walnut | [Master](../../game/assets/source/overnight-20260904/materials/walnut-floor-v1.png), [prompt](../../game/assets/source/overnight-20260904/materials/walnut-floor-v1.md) | [128×128](../../game/tests/fixtures/material-concepts/overnight-v1/walnut-floor-v1.png) | 8 |
| Warm cork | [Master](../../game/assets/source/overnight-20260904/materials/warm-cork-floor-v1.png), [prompt](../../game/assets/source/overnight-20260904/materials/warm-cork-floor-v1.md) | [128×128](../../game/tests/fixtures/material-concepts/overnight-v1/warm-cork-floor-v1.png) | 7 |

All native floors are fully opaque: no alpha pinholes or baked transparent checkerboards. Lossless imports have no mipmaps; imported RGBA buffers exactly equal raw PNG pixels after format normalization. Native/source hashes are recorded in the rendered manifest; all nine rebuilt output hashes are recorded separately.

The production floor remains SHA-256 `6202478639de33fe7f8b548b49a20dddff6b69b59300300bcc89cfa064f2d0bd` before and after. Normal import sidecars for the staged art were created; no production PNG or JSON was edited.

## Measured fit and seams

`OfficeArchitecture` draws the plate as registered 32×32 regions. Central-aisle samples spanning cell and repeat edges match the requested native plate in every rendered state. Pixels outside logical floor cells stay byte-identical to their corresponding baseline. HUD/rail text-core regions and the opaque Chat paper/body region remain byte-identical, not merely similar.

The existing [architecture regression](../../game/tests/test_office_architecture.gd) requires the first and last row/column to match exactly. These measurements deliberately **record candidate failures instead of weakening that production guard**:

| Material | Differing left/right edge rows, of 128 | Differing top/bottom columns, of 128 | Mean linear luminance | X/Y wrap discontinuity relative to ordinary adjacent pixels |
|---|---:|---:|---:|---:|
| Production baseline | 0 | 0 | 0.379 | 0 / 0 |
| Cream terrazzo | 33 | 23 | 0.792 | 0.89 / 0.99 |
| Walnut | 7 | 75 | 0.101 | 0.47 / 0.96 |
| Warm cork | 78 | 88 | 0.398 | 1.16 / 1.01 |

An edge mismatch does not itself prove an ugly visible seam: for these plates, mean wrap differences are generally comparable to normal internal pixel differences. Native review found repeated texture motifs, especially in cork, but not an obvious continuous bright/dark line every 128 pixels. Acceptance still requires a deliberate edge-cleanup export and rerun of the unchanged exact-wrap guard; simply treating the prompt's “seamless” wording as proof would be incorrect.

## Native visual findings

| Priority | Evidence and native coordinates | Finding | Disposition |
|---|---|---|---|
| P1 | All three alternative room captures; floor bounds approximately `(32,96)`–`(1120,672)` | Candidate opposite edges fail the established floor contract. | Normalize selected existing material and re-export, then recapture. No automatic activation. |
| P1 | [Walnut, mature office](../../game/tests/output/native-floor-study/walnut-floor-hires-4-office.png): Mina `(356,526)`–`(381,592)`, Theo `(740,526)`–`(766,592)`, desks near `(285,211)` and `(605,211)` | Brown hair, dark shoes, chair silhouettes and desk legs lose separation against the dark brown field. Parchment cards separate well, but world objects read worse than baseline. | Do not select this export as the default. A later lighter-value version needs a fresh whole-room comparison; do not compensate by secretly recoloring actors. |
| P2 | [Cork, empty office](../../game/tests/output/native-floor-study/warm-cork-floor-hires-0-office.png): central clear field `(320,120)`–`(960,480)` | Dense, orange-gold mottling reads busier/sandier than a quiet matte office floor; repeated clusters are particularly obvious with no furniture. | Keep as concept/cleanup. Reduce texture contrast and repetition before another candidate review. |
| P2 | [Terrazzo, mature office](../../game/tests/output/native-floor-study/cream-terrazzo-floor-hires-4-office.png): open aisle `(420,300)`–`(830,500)`; Mina's shoes/card near `(355,578)`–`(399,638)` | Strong dark-silhouette separation and brighter tech-office identity. Pale footwear and light name-card paper have less material contrast against the nearly white floor; borders/text remain readable. Sparse flecks can look confetti-like across the founder-only expanse. | Best candidate to refine, not approved. Fix wrap, then review moving feet/shadows and the bright paper/floor relationship without changing the approved UI. |
| Pass, bounded | All four [Chat variants](../../game/tests/output/native-floor-study/comparison-hires-2-chat.png), actual individual files in manifest | No new clipping, label collision, black gap, filter blur, or typography change was found from the floor override. World coordinates and architecture silhouettes stay fixed. | Reuse existing UI and geometry. This finding is scoped to the fixed captured states. |

The baseline remains the most balanced current floor: sufficiently light for dark bodies, visually restrained, and already edge-normalized. Terrazzo is the clearest alternative aesthetic—not a claim that the present bright export is finished.

### Silhouette diagnostic, not a text contrast certification

At the fixed stage-2 front-idle positions, median source-outline-to-underlying-floor contrast was:

| Material | Founder | Mina | Theo | Theo outline samples below 1.5, of 262 |
|---|---:|---:|---:|---:|
| Baseline | 6.58 | 7.04 | 6.14 | 16 |
| Terrazzo | 14.26 | 13.50 | 11.81 | 2 |
| Walnut | 2.73 | 2.54 | 2.12 | 57 |
| Cork | 6.75 | 7.39 | 6.14 | 14 |

This samples opaque source silhouette pixels beside transparent pixels against the corresponding floor locations. It is useful evidence for walnut's lost dark-body separation, but it ignores live shadows, neighboring props, movement and local scene lighting; it is neither WCAG nor a complete perceptual-readability score.

## Re-run

From the repository root, with the available Godot executable on PATH:

```sh
STARTUP_VALLEY_NO_WORKER=1 godot --headless --path game --fixed-fps 60 --script res://tests/test_native_floor_materials.gd
STARTUP_VALLEY_NO_WORKER=1 godot --path game --fixed-fps 60 --script res://tools/capture_native_floor_study.gd
```

The provider-free fixture substitutes the null transport before `_ready`; credential-ready is only an explicit local UI projection to prevent onboarding from contaminating comparison images. This study does not access credentials, run jobs, read/write personal saves, simulate paid evaluation, or approve a floor. Actors and the clock are frozen: walking shimmer, moving foot shadows, all UI states and fullscreen scaling remain outside this small static material study.
