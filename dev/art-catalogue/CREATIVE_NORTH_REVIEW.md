# Creative/designer north toolkit — staged native candidate

**One initial ImageGen call produced genuine alpha; no retries were needed.** Three independently reusable groups—flat pen tablet/stylus, color-swatch fan, and rear-facing camera—now have checked native exports. This is a staged north-only candidate, not an approved runtime toolkit or a claim of four-direction availability.

## Provenance

- Built-in ImageGen only. Request started **2026-09-04 07:35:38 UTC**, returned in35.8 seconds; source alpha and workspace copy verified by **07:36:42 UTC**. No provider jobs, CLI Image API, paid external service, worker, save or credential access.
- Prompt: `dev/art-catalogue/prompts/creative-north-v1.md`.
- Source: `game/assets/source/overnight-20260904/roles/creative-north-v1.png`, **1672×940 RGBA**. Original generated output remains at the path recorded in the prompt.
- Viewed native/enlarged north computer and legal toolkit references before prompting. They informed the fixed-camera/material brief; none was an edit target or copied into this newly generated source.
- North-use here means the operator sits screen-down and looks up. The tablet lies flat in screen-aligned axes; the camera's rear display faces the operator, its lens points away/up. It is not a generic front-facing camera icon rotated into place.

## Mechanical export and actual sizes

```sh
bash dev/tools/build_creative_north_calibration.sh
STARTUP_VALLEY_NO_WORKER=1 /private/tmp/startup-valley-godot/Godot.app/Contents/MacOS/Godot --headless --path game --script res://tests/test_creative_north_kit.gd
```

The exporter preserves complete object aspect ratios using one uniform point scale per reusable group. It uses the shared16-color `role-material-palette.svg`; native alpha is preserved separately and restored after palette mapping, with exact alpha comparison. No independent-axis stretching, rotation, mirror, source repaint, manufactured mask or semantic correction occurs.

| Object | Measured source alpha50% bounds `[x,y,w,h]` | Native opaque bounds `[x,y,w,h]` | Opaque pixels |
| --- | --- | --- | --- |
| Tablet + resting stylus | `[72,240,707,455]` | `[83,127,24,15]` |338 |
| Swatch fan | `[837,336,336,348]` | `[58,128,12,12]` |95 |
| Camera | `[1219,273,378,369]` | `[124,119,12,12]` |130 |

All components have the same **192×224 registered canvas and pivot(96,160)**. Each independently exports into `game/tests/fixtures/furniture-calibration/roles/`:

- `creative-north-v1-tablet.png`
- `creative-north-v1-swatches.png`
- `creative-north-v1-camera.png`
- `creative-north-v1.png` — exact disjoint union
- `creative-north-v1-4x.png` and `creative-north-v1-paper-4x.png` — nearest review enlargements

The swatch fan is square in the actual generated source. Its12×12 export deliberately differs from the approximate12×8 brief instead of flattening the fan. Tablet height rounds to15 rather than16 under uniform24px-width scaling. All three complete visible boxes lie inside the96×32 north tabletop rectangle `[48,112,96,32]` on the registered host canvas. This is a conservative geometric fit, not a tested character/tool reach or final room composition.

## Native review

The generated source,192×224 union and768×896 nearest4× pale-underlay export were viewed. The palette is compatible with the current charcoal devices, blue drawing surface, cream papers and restrained Whop accents. The source has three clean alpha-connected groups and no desk, chair, actor, floor, opaque checkerboard, watermark or text.

At native size the tablet is the strongest silhouette. Its stylus becomes a subtle dark bar along the lower rim; it is not as distinct as in the source master, so this export must not be presented as a polished animated pen or separately graspable stylus. The swatches read as a tiny multicolor fan with paper edges, not legible swatch labels. The camera's rear screen and raised viewfinder are visible, but its miniature controls simplify heavily at12px. These are honest small-object readability limits, not failures concealed by enlargement.

Provisional native-only scores: pixel coherence3/3, perspective2/3, silhouette/readability2/3, registered layers/anchors3/3. Cross-direction consistency and actual room/actor placement are **not assessed**; therefore no complete acceptance mean is claimed. Before runtime approval, inspect the toolkit on an actual desk with the native character, test visual contact/occlusion and compare any separately authored E/S/W variants. Keep the existing assets active until those gates pass.

## Validation

- Focused provider-free headless test: **25 checks, 0 failures**, repeat run green. Durable result: `game/tests/output/creative-north-kit/results.json`.
- Native union: **563 opaque /42,445 transparent pixels**, three disjoint objects, binary0/255 alpha, **16 opaque palette colors +transparent**.
- Every native component uses the shared palette; its alpha bounds and counts match the table. Exact component union reproduces all43,008 RGBA pixels of the combined canvas with no overlap or missing source-export pixels.
- Alpha restoration during palette remap passes exact image comparison for every component. Repeated exports produce identical hashes. Shell syntax and owned-file diff checks pass.
- No renderer was launched; native-room composition is the next bounded review. No runtime registry/catalogue, production script or save changed.

```text
93d3295cf53f652397ea664cf457600852ca9cefbc1f36c88c0f9e619f28ffc0 source creative-north-v1.png
7389c9a5a3af85e3cc6896b7ae2170e2c1f9323f7c07924ff63664497b85f12f native creative-north-v1.png
```
