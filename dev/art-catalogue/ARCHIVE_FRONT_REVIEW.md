# Archive: separate service-south insert

2026-09-04 08:13 UTC. **Staged native front, not a production replacement.**

The new archive supplies an independently registered front texture instead of
another complete cabinet with a conflicting roof angle. Actual cabinet floor
and elevation remain the exact code-native96×32 footprint/64px rise. The
larger32px-deep roof now matches the office grid; the legacy roof was much
shallower. This first material comparison deliberately retains the shared oak
top; a quieter charcoal finish and true rear/end faces are next.

## Source and export

- Built-in ImageGen, one initial call, **zero retries**.
- Original1572×1001 master: `game/assets/source/overnight-20260904/kits/archive-service-south-insert-v1.png`.
- Exact prompt beside it, including source output filename. The old archive
  was identity/style reference, the flat diagram a layout constraint.
- Rebuild: `bash dev/tools/build_archive_south_insert.sh`.
- Actual front crop1478×902 at(46,51); uniform point resize to88×54.
- Exact insert canvas88×56 has one transparent row above/below; it is not
  stretched to the nominal aspect. Parent charcoal supplies those two rows.
- Registered192×288/pivot(96,224) places the insert at(52,180), the exact
  south socketRect(-44,-44,88,56). Every layer keeps the same anchor.
- Native palette uses23 opaque colors from24 authored swatches plus alpha;
 4752opaque/176transparent pixels, zero intermediate alpha or hidden RGB.
  Initial generic32-color quantization dulled the tiny lamps; explicit
  material/Whop swatches preserve the small green and orange accents.

The source did not obey exact26px compartment widths or requested locker
stacking. It has two tall left lockers, document display, prototype display,
and three lower drawers. These remain coherent and legible after **uniform**
normalization; no false exact-grid claim or semantic manual repaint is made.

## Native review

`game/tools/capture_archive_front.gd` compares legacy, bare exact volume, and
the new insert in the actual approved TownRoom. Seven native1280×720 stills
and seven nearest4× crops cover unoccupied, both employee scale references,
south service approach and rear occlusion. Main inspected six native screens
and the unoccupied4× detail; the remaining Theo scale still is generated and
covered by source/render tests, not claimed individually inspected.

The source reads as file storage and finished work at native size. All4752
opaque front pixels render at their expected unscaled coordinates in the
three unoccluded checks. The front sits within its charcoal carcass without
an unregistered seam. Actors in front correctly cover the doors; actors
behind are largely hidden by the64px rise. This is honest depth, not a
whole-cabinet sorting exception.

Test results: **19 headless/112 rendered checks, zero failures**; fourteen
PNGs. Three exported PNGs rebuild with identical SHA-256 hashes. Source master
unchanged. No movie required for this static-face/scale study. No personal
save, worker, provider, dependency, or runtime catalogue change.

Evidence: `game/tests/output/archive-front/manifest.json`, `unoccupied.png`,
`unoccupied-4x.png`, `mira-service-south.png`, `theo-behind.png`.

## Acceptance and remaining gates

For the **south insert alone**: pixel coherence3, flat perspective3,
silhouette/readability3, layering/anchor3, cross-view identity1, placement2;
mean2.5 but a category below2 means **not a complete-family pass**. The other
faces, suitable top finish, actual rotation/interaction/placement integration
and final office composition remain required. The three comparison actors
are native sprite depth references, not new Studio click/navigation proof.

Do not label the bare N/E/W volumes as three authored archive faces. A rear
panel and distinct locker-end/display-end finishes should attach separately;
`set_service_insert` must continue rejecting the front texture on other sides.
