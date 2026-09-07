# Passive service library native review — 2026-09-06

## Disposition

`water_station` v2, `printer_scanner_station` v1, and `resource_cart` v1 pass the agent-native gate for the passive art library. This is art approval only. None is registered in the production furniture catalogue or default layout, and no dispensing, printing, scanning, cart movement, transaction, worker, hire, role pose, service backend, or interaction is claimed.

The complete water-station-v1 fixture and actual-room evidence remain preserved as rejected history. Direct native review found its tall, narrow, featureless blue reservoir readable as a chimney rather than an office water bottle. V2 changes only that reservoir to a supported broad stepped jug with transparent shoulder corners, short collar/neck and fixed-camera highlight. Base elevation, footprint-derived top plane, contact geometry, canvas, pivot, masks and layer contract are unchanged.

All three are deterministic typed-GDScript constructions using reviewed native oak or powdercoat materials. No generated raster, provider call, readable text, logo, fake metric, fake balance, baked actor, transformed finished bitmap, or new source-attempt batch was used.

## Visual scores

Scores come from direct inspection of the native and nearest-neighbour 4× candidate sheets plus actual GameMain base/approach sheets.

| Family | Pixel | Perspective | Silhouette | Layers / anchor | Direction | Placement | Mean | Minimum |
| --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| Water / tea station v2 | 3 | 2 | 2 | 3 | 2 | 3 | 2.50 | 2 |
| Printer / scanner station v1 | 3 | 2 | 2 | 3 | 2 | 3 | 2.50 | 2 |
| Open resource cart v1 | 3 | 2 | 2 | 3 | 3 | 3 | 2.67 | 2 |

Perspective is deliberately bounded at 2/3. Every facing has the full 2×1 or 1×2 occupied-floor rectangle translated upward as a top plane and a separately measured path to floor contact, but the construction is a restrained orthographic floor-axis extrusion rather than an embellished isometric prop. Fixed upper-left highlights and lower/right shading stay screen-stable. N/E/S/W are independent declarations with distinct rear, service-front and end identities; no view is a rotated or mirrored finished raster.

The water station now reads through a broad shouldered blue reservoir, neutral dispenser body, copper kettle, three cups and front taps. Its accepted limitation is a deliberately simple flat reservoir and opaque appliance-side identity; there is no translucent-fluid simulation, glow, flow animation or active water service. The printer reads through a raised scanner lid, dark device aperture, static paper/output tray and powdercoat cabinet. Its restrained ends and rear are coherent but intentionally plain. The cart reads through two physically separated open trays, four caster cues, an oriented handle and neutral supply blocks; the open-air interval remains visible in every view. The printer's static paper cue was explicitly added to all four facings before the accepted export.

## Measured dimensions

The planned canvas, pivot, sprite offset, occupied masks, one-cell approach clearance and two exact 32×32 collision shapes are retained. “Projected rise” includes screen-projected footprint depth and is recorded separately from the vertical feature envelope.

| Family | Canvas | Pivot | Offset | Base elevation | Authored vertical feature rise | N/S top depth | E/W top depth | Observed maximum projected rise | Planned feature envelope |
| --- | --- | --- | --- | ---: | ---: | ---: | ---: | ---: | ---: |
| `water_station` v2 | 160×240 | 80,176 | 0,-56 | 40px | 80px | 32px | 64px | 143px | 112px |
| `printer_scanner_station` | 160×208 | 80,144 | 0,-40 | 32px | 62px | 32px | 64px | 118px | 80px |
| `resource_cart` | 160×208 | 80,144 | 0,-40 | 72px | 88px | 32px | 64px | 136px | 80px |

The resource cart's 88px handle feature is an explicit measured revision above the original 80px feature estimate, inside the unchanged 160×208 canvas and protected padding. Its collision, pivot and scale do not change. Maximum design bounds are 144px, 126px and 152px respectively when each authored feature rise is combined with the worst-case 64px E/W footprint depth; accepted pixels remain below those bounds.

## Structural and actual-room evidence

- Deterministic exporter: 120 checks, 0 failures.
- Structural/placement suite: 719 checks, 0 failures. It verifies full footprint-derived top planes, camera-front contact where solid, the cart's true open-air tray gap, binary alpha, zero hidden RGB, exact reconstruction, byte-exact rebuild, fixed canvas/pivot, distinct authored views, original masks, owner-scoped admission, wall/corner rejection, all 37 preserved water-v1 files, and no runtime/service action.
- Actual GameMain: three fresh native macOS processes, one family per process, each 196 checks and 0 failures. Each family result records 190 checks before its own result-file close. The aggregate verifies 106 checks and 588/0 source invocation checks.
- Native viewport: 1280×720. Common safe pivot: grid [12,13]. Each facing has two exact 32×32 collision shapes, one safe adjacent approach cell, atomic wall/corner rejection, alpha-aware visible-surface picking, and no action target.

Measured actor/prop overlap is evidence, not a quality threshold:

| Family | North (prop in front) | East | South (actor in front) | West |
| --- | ---: | ---: | ---: | ---: |
| Water station v2 | 1,363px | 0px | 1,242px | 0px |
| Printer station | 763px | 0px | 1,242px | 0px |
| Resource cart | 883px | 21px actor-front | 870px | 57px actor-front |

North is `actor_behind_structure`, South is `actor_in_front_of_structure`, and E/W bracket the actor between rear/front layer depths. The standing founder is only a route, scale, gaze, contact, and occlusion/depth probe. It is not a service pose or evidence of an implemented action.

## Evidence paths

- `game/tests/fixtures/furniture-calibration/{water-station-v2,printer-scanner-station-v1,resource-cart-v1}/manifest.json`
- `game/tests/output/{water-station-v2,printer-scanner-station-v1,resource-cart-v1}/candidate-contact-sheet-{native,4x}.png`
- `game/tests/output/{water-station-v2,printer-scanner-station-v1,resource-cart-v1}/actual-room-{base,approach}-contact-sheet-native.png`
- `game/tests/output/{water-station-v2,printer-scanner-station-v1,resource-cart-v1}/actual-room-approach-contact-sheet-4x.png`
- `game/tests/output/{water-station-v2,printer-scanner-station-v1,resource-cart-v1}/actual-room-results.json`
- `game/tests/fixtures/furniture-calibration/water-station-v1/manifest.json` and `game/tests/output/water-station-v1/actual-room-results.json` (rejected water-v1 history)
- `game/tests/output/passive-service-library/native-invocation-*.json`
- `game/tests/output/passive-service-library/actual-room-isolated-aggregate-results.json`

The proposed family registrations bind approved art only to the reviewed whole PNGs, declare all three required native layers, keep approved/runtime/default-layout paths separate, and retain runtime paths/evidence as null with empty runtime exports.
