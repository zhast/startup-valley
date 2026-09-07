# Research bench production review

Date: September 4, 2026\
Runtime asset: `research-bench-v1`\
Character asset: `research-v1`

## Disposition

Accepted production review for the four-facing research station and native
Mina/Theo research-pose capability. The broad ImageGen attempts remain rejected
source references because all three painted checkerboards and returned no alpha.
The integrated pose strips are deterministic native reconstructions from the
accepted locomotion bodies, with separate original handheld-tool pixels.

The authored default placement moved from grid `[29, 6]` to `[29, 8]` after the
actual room validator proved that the taller layered art entered the north wall.
The first evidence pass was rejected because interaction cells were on the same
side as the claimed actor gaze and the animation swapped whole tools. The
corrected profiles put actors opposite their gaze; one stable analyzer now uses
a four-frame scan, and the capture covers Mina and Theo in all four directions.

## Native visual gate

| Category | Score | Evidence |
|---|---:|---|
| Pixel coherence | 2 | Native integer pixels and nearest filtering; geometric shapes are simpler than the earlier painterly office props. |
| Perspective | 2 | Four screen-axis views preserve the room projection; side elevations are intentionally narrow. |
| Silhouette/readability | 3 | South exposes microscope/scanner/samples, North exposes instrument backs, and side screens remain legible. |
| Layering/anchors | 2 | Actual actor contact and direction-specific rear/front occlusion pass; the standing tool motion is deliberately restrained. |
| Direction consistency | 3 | N/E/S/W are separately authored without runtime rotation or mirroring. |
| Placement | 3 | All four profiles validate at a shared room pivot, with walkable interactions and no wall overlap at the default bay. |

Mean: **2.50 / 3**. Minimum: **2 / 3**. Runtime gate: **pass**.

## Evidence and verification

- `game/tests/output/research-bench-production/{north,east,south,west}.png`
- `game/tests/output/research-bench-production/four-facing-contact-sheet.png`
- `game/assets/runtime/characters/research-v1/manifest.json` and eight corrected directional strips
- `test_research_bench_production.gd`: 69 checks, 0 failures, including a real Mina traversal to the production research contact and transition into `WORKING`
- `capture_research_bench_production.gd`: 42 checks, 0 failures; eight employee/facing captures plus distinct sampled motion frames
- `validate_project.gd`: pass after the inward placement correction

## Nonblocking limits

- The research actions intentionally reuse the existing `research` game event;
  no new worker method or external service was added.
- Handheld research motion is a compact four-frame overlay on the stable idle
  body. A future fully redrawn arm/body animation may improve expressiveness,
  but the current strip is native, anchored, directional and readable.
