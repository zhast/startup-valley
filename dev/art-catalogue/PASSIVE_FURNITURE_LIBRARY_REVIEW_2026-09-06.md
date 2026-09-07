# Passive furniture library — bounded acceptance review

Date: **2026-09-06**\
Scope: **passive art-library deliverables only**. This review does not add a
runtime catalogue entry, default-room placement, interaction, service action,
seated lifecycle, worker behavior, persistence, or gameplay reward.

## Disposition

The existing exact native exports for these five families clear the project’s
bounded art gate (mean at least 2.5/3 and no category below 2/3) when they are
judged as reusable passive objects rather than as complete gameplay stations.
No repaint or regeneration was needed. Their approval proposal therefore points
at the existing reviewed PNGs byte-for-byte and keeps every runtime path null.

| Family | Pixel | Perspective | Silhouette | Layers / anchors | Direction | Placement | Mean | Passive-library result |
|---|---:|---:|---:|---:|---:|---:|---:|---|
| Visitor chair v2 | 3 | 2 | 3 | 3 | 3 | 3 | **2.83** | Pass after shadow-only correction |
| Mobile whiteboard | 3 | 3 | 2 | 3 | 2 | 2 | **2.50** | Pass |
| Rolling storage pedestal | 3 | 3 | 2 | 3 | 2 | 2 | **2.50** | Pass |
| Low bookshelf | 2 | 3 | 2 | 3 | 2 | 3 | **2.50** | Pass |
| Acoustic divider | 2 | 3 | 2 | 3 | 2 | 3 | **2.50** | Pass |

These are deliberately not 3/3 objects. The score-2 limits remain visible and
are part of the accepted identity; approval is not being inferred from test
counts.

## Native review performed for this decision

The following existing evidence was inspected at its stored native resolution,
including the nearest-neighbor 4× details and actual 1280×720 `GameMain`
contexts:

- Visitor chair v2: [preserved v1/v2 comparison](../../game/tests/output/visitor-chair-v2/v1-v2-before-after-4x.png),
  [four corrected native facings](../../game/tests/output/visitor-chair-v2/candidate-contact-sheet-native.png),
  [actual room](../../game/tests/output/visitor-chair-v2/actual-gamemain-contact-sheet-native.png), and
  [seated depth at 4×](../../game/tests/output/visitor-chair-v2/actual-room-seated-contact-sheet-4x.png).
- Mobile whiteboard: [four actual-room facings](../../game/tests/output/mobile-whiteboard/all-four-native.png),
  [South planning face at 4×](../../game/tests/output/mobile-whiteboard/south-planning-4x.png),
  and the [East thin edge at 4×](../../game/tests/output/mobile-whiteboard/east-blank-4x.png).
- Rolling pedestal: [four actual-room facings](../../game/tests/output/rolling-pedestal/all-four-native.png),
  [South drawers at 4×](../../game/tests/output/rolling-pedestal/south-room-4x.png), and
  [East closed side at 4×](../../game/tests/output/rolling-pedestal/east-room-4x.png).
- Low bookshelf: [South books and bin at 4×](../../game/tests/output/low-bookshelf/south-room-4x.png),
  [North rear at 4×](../../game/tests/output/low-bookshelf/north-committed-4x.png),
  [East closed end at 4×](../../game/tests/output/low-bookshelf/east-committed-4x.png), and
  [actual founder depth](../../game/tests/output/low-bookshelf/east-founder-behind-middle-4x.png).
- Acoustic divider: [South broad face at 4×](../../game/tests/output/acoustic-divider/south-room-4x.png),
  [East edge at 4×](../../game/tests/output/acoustic-divider/east-committed-4x.png), and
  [actual founder occlusion](../../game/tests/output/acoustic-divider/founder-behind-middle-4x.png).

The current headless fixture sources were also rerun without producing new
screenshots: visitor chair v2 **105/0**, mobile whiteboard **2,303/0**, rolling
pedestal **2,450/0**, low bookshelf **136/0**, and acoustic divider **66/0**.
Those checks confirm the current geometry and references still agree with the
reviewed evidence; they do not replace the visual inspection.

## Family findings and retained limits

### Visitor chair v2

The chair is a coherent one-cell guest seat with four independently authored
screen-axis views. It is visibly distinct from the rolling task chair, has a
stable common pivot, and its rear/body/front layering works with the existing
Mina scale probe. V1's broad dithered/solid floor field read as a suspended
basket between the legs and is preserved as rejected history. The [v2
shadow-only review](VISITOR_CHAIR_V2_REVIEW_2026-09-06.md) replaces only that
layer with small down-right marks at the existing support points. Every chair
structure pixel, projection and geometry record remains v1-exact. The broad
orthogonal cushion planes remain visibly simple, so perspective stays 2/3.

This approval covers the **exact v2 bare chair art**. The contact probe is not a new
seated animation, `Sit` action, reservation policy, or lifecycle. Accordingly,
the proposed library record does not make actor-pose review a prerequisite and
does not bind the optional contact socket to runtime.

### Mobile whiteboard

The wide front/rear projections, supports, tray and casters read consistently;
the optional South planning insert remains legible and does not leak through
the North rear. The honest 4px East/West board edge can read as a tall post, and
the caster blocks remain schematic. Those are silhouette/direction limits, not
grounds for falsely widening the side view or rotating the South raster.

The approved library object is the reusable **blank board**. The V3 planning
face remains an optional reviewed insert, not the only usable base and not a
writing interaction. Its later canonical decorative-profile evidence is
recorded in [the passive integration review](PASSIVE_FURNITURE_INTEGRATION_REVIEW.md),
but no runtime admission follows here.

### Rolling storage pedestal

The one-cell, desk-height shell reads clearly beside 48×80 actors. South’s two
drawers, pulls, divider and blue tab remain legible; the generated inset and
code-native rim do not form a broken double border. North and side views are
intentionally austere and do not pretend that the drawer front is visible on
hidden faces. Casters and side seams remain minimal.

This is side storage, **not under-desk storage**, and approval adds no storage
action. The later canonical decorative-profile proof supplements the original
disposable-room placement evidence without changing the retained 2/3 placement
score.

### Low bookshelf

South’s books, horizontal stack and resource bin are readable at native size.
North is an honest plain rear; East and West are byte-identical closed ends,
not four claimed drawings. The side silhouette can read as a low cabinet and
the frame/plinth remains plain, but the physical projection and actor depth are
sound.

The failed **88×24** generated-target contract remains failed: the 2140×735
source would uniformly become 88×30 and the strict export remains absent. The
accepted South assembly uses the unchanged source-preserving **70×24** row
centered inside the unchanged 88×24 dark bay, with visible 9px gutters. This is
not relabeled as a successful 88×24 generation, crop, or nonuniform scale.

### Acoustic divider

The broad indigo felt face is quiet at native size, with no visible tile moat or
dominant stripe. The thin projection is physically honest but still pole-like,
and the feet/frame remain schematic. North and South are byte-identical, as are
East and West; these are declared physical symmetry pairs, not four generated
drawings or a rotated broad-face bitmap.

The first local review’s 1/3 silhouette concern is preserved as history. The
parent’s later native review accepted that same limitation as nonblocking at
2/3, producing the bounded 2.5 mean above. Nothing in this decision invents an
interaction, acoustic simulation, runtime profile, or production placement.

## Registration boundary

The companion [registration proposal](passive-furniture-library-registration.json)
contains five complete family objects and exact existing layer/composite
descriptors. `approved_art_path` refers only to reviewed native whole exports;
all `runtime_art_path` values and runtime registration fields remain null or
absent. `production_status: approved` means **approved for the dev art
library**, not shipped in the office.

The current validator intentionally blocks approved lifecycle states for its
special symmetric-art-study branch. That guard should not be deleted or
weakened by flipping `runtime_approved`. A narrowly scoped contract is proposed
separately in [PASSIVE_LIBRARY_VALIDATOR_PROPOSAL.md](PASSIVE_LIBRARY_VALIDATOR_PROPOSAL.md).
