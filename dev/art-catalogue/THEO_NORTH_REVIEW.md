# Theo north seated/typing — staged native review

Reviewed 2026-09-04 06:18 UTC. **Calibration candidate only; NOT runtime approved or registered.** No image generation is outstanding. This bounded task used built-in ImageGen for one atlas and one targeted alpha-extraction retry. The second permitted retry was not used. No provider jobs, production registry changes, furniture masks, save access, commits or push.

## Identity and source provenance

References inspected before generating:

- `game/assets/source/polish/theo-seated-master.png` — exact seated identity and outfit.
- `game/assets/runtime/characters/theo-seated.png` — native 48×80 south proportions.
- `game/assets/runtime/characters/theo-locomotion.png` — the second row is the existing rear/up-facing view.
- `game/tests/fixtures/furniture-calibration/characters/mira-north-seated-v2-4x.png` and `dev/tools/build_mira_north_calibration.sh` — shared north staging/export precedent, not Theo identity.

**Outfit correction:** Theo's established seated outfit is an orange jacket, white shirt, **olive trousers**, and cream/white sneakers, with curly dark-brown hair and warm brown skin. His trousers are not white. Locomotion includes a cross-body satchel; the existing seated atlas does not, so the generated seated sheet intentionally has no bag.

| Version | Request timing, UTC | Durable project source | Result |
| --- | --- | --- | --- |
| v1 | Start 06:14:16; returned/verified by 06:15:14 | `game/assets/source/overnight-20260904/characters/theo-north-v1.png` | 2172×724 RGB; six rear-facing poses, but an opaque painted checkerboard. Rejected for alpha; retained as provenance. |
| v2 | Retry began after 06:15:14; returned/verified by 06:16:27 | `game/assets/source/overnight-20260904/characters/theo-north-v2.png` | 2172×724 RGBA, genuinely transparent. Used as the mechanical staging source. |

Prompts are retained verbatim in `dev/art-catalogue/prompts/theo-north-v1.md` and `theo-north-v2.md`.

Built-in originals remain at:

- `/Users/zhast/.codex/generated_images/01a069ca-7ec7-7252-827b-8a225a8e6fba/exec-3a2d9a0c-bb9a-4fcc-a239-4f7ef72aa708.png`
- `/Users/zhast/.codex/generated_images/01a069ca-7ec7-7252-827b-8a225a8e6fba/exec-bd0710c4-30fe-42a7-af8d-0e88c6d8ad76.png`

The retry requested background-only extraction. It preserved the canvas dimensions and all six poses, but this is generated extraction, not a guarantee that every opaque source pixel remained identical; edge/highlight differences are visible. No local semantic pixel repainting was performed.

## Reproducible mechanical export

Run `bash dev/tools/build_theo_north_calibration.sh`.

The script follows the existing seated/Mina-north workflow: one shared vertical alpha crop (y130, height456), one scale to a 68px character height, one shared 48-color palette, nearest-neighbor sampling, binary-alpha normalization, native 48×80 cells, and bottom alignment at y72. It registers the upper hair silhouette around x24 rather than centering moving hands. No per-frame vertical scale changes, furniture masks, invented poses, mirroring, bitmap rotation, or runtime scaling are used.

The source's figures are not on an exact six-way grid. Alpha projection measured the actual horizontal bands `(x,width)` as `(54,222)`, `(419,224)`, `(772,244)`, `(1138,242)`, `(1492,248)`, `(1881,242)`. The export uses these separate bands with the same vertical crop/scale, preserving hands in their real transparent gutters. No naive equal-grid export is consumed.

Final files under `game/tests/fixtures/furniture-calibration/characters/`:

- `theo-north-seated-v2.png` — 288×80; six native 48×80 frames.
- `theo-north-seated-v2-4x.png` — 1152×320; exact 4× nearest-neighbor enlargement for edge review.

Native atlas SHA-256: `6f8a7427cb0823e2bedf5ae98a4c4f0c294b3be77430e4a96b3491fa92465ae1`.

## Native inspection and measurements

All six frames were inspected at 100% and exact 4× nearest scale. There are 10,203 opaque and 12,837 fully transparent pixels, **zero intermediate-alpha pixels**, and 45 colors including transparency. All six complete frame hashes are distinct. No opaque checkerboard, desk, chair, keyboard, floor or cast shadow remains.

| Frame | Intended purpose | Opaque bounds `(x,y,w,h)` | Upper-28px head bounds | Foot baseline |
| --- | --- | --- | --- | --- |
| 0 | Seated idle A | 7,4,33,68 | 10,4,28,24 | 72 |
| 1 | Seated idle B | 7,4,33,68 | 10,4,28,24 | 72 |
| 2 | Typing A | 6,4,36,68 | 10,4,28,24 | 72 |
| 3 | Typing B | 6,4,36,68 | 10,4,28,24 | 72 |
| 4 | Typing C | 6,4,37,68 | 11,4,27,24 | 72 |
| 5 | Typing D | 6,4,36,68 | 10,4,28,24 | 72 |

All frames have the same first opaque row y4 and last opaque row y71; the top row and all eight bottom rows are transparent. Horizontal silhouettes remain at least five pixels inside their cell edges. The head center is x24 in integer registration; the odd-width head in frame4 has a half-pixel geometric-center difference, as in the Mina precedent.

For comparison, the current south-seated Theo is 29–30px wide and 67–68px tall, and the current rear locomotion frames are 29×67. North seated idle is 33px wide and typing reaches 36–37px because the elbows/hands extend sideways. Do not compensate by shrinking these new frames at runtime.

## Sitting and hand landmarks — calibration guidance, not approved geometry

Approximate native visual landmarks read from the atlas:

- Hair begins y4, with the rear curls/ears down to about y30.
- Jacket collar/shoulders are around y30–35; jacket hem around y51–54.
- The broad seated trouser/hip shape lies approximately y52–62, with shortened bent lower legs below it.
- Sneakers occupy roughly y63–71; logical bottom-center foot anchor remains `(24,72)`.
- In typing frames, hands appear beside the shoulders at approximately y31–38, near x6–11 and x36–42. These are high hands, so desk surface contact must be checked explicitly.

These visual ranges must not be substituted for collision cells, seat sockets, or exact hand contact metadata. The root north workstation/chair assembly must establish actual seated support and desktop alignment without moving the logical navigation feet.

## Disposition and remaining gates

- **Identity and orientation:** all frames show the real rear of Theo's curly hair and orange jacket, olive trousers and light sneakers. No front face or mirrored south sprite. No satchel is added.
- **Pose:** broad hips and short legs read as compact sitting, but the sheet alone cannot prove support by the chair or correct knee/foot depth. Actual chair/desk compositing is required.
- **Hand motion risk:** idle arms are down, while typing arms rise noticeably toward shoulder level. The four typing frames alternate small hand positions, but the idle-to-typing transition may read as a shrug if the desk contact is too low. This is a concrete assembly/animation check, not evidence of smooth motion merely because frame hashes differ.
- **Rear shoe risk:** visible light shoe tops/lace-like highlights remain prominent from behind. Compare them against the game's slightly overhead rear locomotion view in the composite; request a targeted rear-foot correction if they read as front-facing shoes.
- **Pixel stability:** head top and baseline are fixed. Native orange-jacket silhouette is clear, but curly hair highlights vary between frames; animation cadence still needs in-room review for flicker.
- **No enablement:** `CharacterArt`, production furniture data and runtime capability lists were not changed. These are test fixtures only.

Provisional still-image scores: pixel coherence2, projection2, silhouette/readability3, atlas anchors3, within-atlas direction consistency3. **Placement/layering and motion are unscored pending the actual north workstation assembly.** No overall acceptance mean or runtime-ready claim is justified yet.

Next action: preview all six frames with the actual north chair and desk layers at native scale, inspect hand contact, seated support, rear shoes, idle/typing transitions and silhouette collision with furniture; only then decide on approval or the one remaining permitted targeted retry.
