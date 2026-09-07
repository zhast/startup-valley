# Legal toolkit east attempts — wrong directional identity, retained evidence

**Not an east-view asset approval.** Root's original east brief incorrectly
mapped the open folder's leaves. Independent review caught this before any
production registration. The existing drawing is partly consistent with
**west**, and is being reused there only as a clearly limited candidate.
Original source filenames and prompts remain unchanged for provenance. See
`LAWYER_DIRECTION_IDENTITY_REVIEW.md` for the final per-object decision.

## What was generated

All sources are under `game/assets/source/overnight-20260904/roles/` with
matching `.md` prompts. One initial request and three targeted retries were
used. **The east retry allowance is exhausted; reclassification does not
reset it.** No west request was sent merely to duplicate this drawing.

| Source | Original generated filename | Outcome |
| --- | --- | --- |
| `lawyer-kit-east-v1.png` | `exec-72486886-c958-4a3a-8405-e22d8a5fcb54.png` | RGB1672×941; tapered binder top, opaque checkerboard |
| `lawyer-kit-east-v2.png` | `exec-ad34338f-0b6a-4cc3-9e0a-27366b860a17.png` | RGBA1672×941; parallel edges corrected, binder top too short |
| `lawyer-kit-east-v3.png` | `exec-58b91bbc-9be1-412e-bf87-f26bb6f3ce4c.png` | RGB1672×941; taller rectangular top, alpha lost |
| `lawyer-kit-east-v4.png` | `exec-d3f75665-f173-44f6-aea9-d4b0b1c0495e.png` | RGBA1672×941; clean three-object source, wrong east identity |

For a north-view folder with blank cover left and checklist right, a physical
turn toward east puts blank cover **top** and checklist **bottom**. This
source instead has checklist top and blank bottom, the west leaf order.
Its tabs nevertheless remain on the right rather than the expected west
outer top edge, and its checkbox rows remain screen-upright. Binder near
spines also fit west better. Pen order is not proven to be a new side view.
These are real directional consistency defects, not transparency problems.

## Mechanical export and historical placement study

`build_lawyer_east_kit.sh` retains the original mislabeled attempt as a
diagnostic export, **not as valid E art**. Complete source crops are binder
227×610 at(178,148), folder409×586 at(645,170), cup170×346 at(1325,337).
Uniform point scaling and the shared16-color role palette preserve alpha.
Actual native objects on192×224/pivot(96,160): binder12×32 at(86,71), folder
19×27 at(81,145), cup6×12 at(103,72). Union942 opaque/42,066 transparent;
no component overlap. The binder is2px taller than the nominal12×30 target.

The native `capture_lawyer_east_kit.gd` study placed those objects on an east
desk before the identity error was diagnosed. It still provides useful
**layout failure evidence**, not direction acceptance: a folder covers the
default mouse. Moving the mouse to source X+20 gives actual host bounds
(5,−11,9,6), leaving a gap from the folder and two columns before the outer
edge. The earlier X+22 placement touched the desk rail and was corrected.
The folder itself still crowds the left rim by a pixel; the separate west
reclassification uses an independently reviewed placement, not this recipe.

- [Historical native comparison](../../game/tests/output/lawyer-kit-east/frame2.png)
- [Historical separated-mouse detail](../../game/tests/output/lawyer-kit-east/preferred-mina-4x.png)
- [Recorded layout measurements](../../game/tests/output/lawyer-kit-east/manifest.json)

The layout harness passed37 headless/49 rendered checks, six native frames.
Those checks concern bounds and controls; they did **not** detect the wrong
folder identity. The preserved screenshots' EAST heading is the historical
mistake, not a current acceptance label. No production profile used these
objects. All source and derived images remain staged. East disposition:
**cleanup/missing correct view**, not “four directions complete.”
