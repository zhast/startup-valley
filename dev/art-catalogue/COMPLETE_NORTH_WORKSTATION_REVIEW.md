# Complete North workstation — native lifecycle review

September 4, 2026. **PASS at the production threshold.** The North assembly was
reviewed at native 1280×720 through approach, seated idle, typing, quiet
thinking, failure rest, recovery and departure for Mina and Theo.

The accepted evidence is in
[`game/tests/output/complete-north-workstation/`](../../game/tests/output/complete-north-workstation/).
The chair is deliberately a rear support while the desktop front owns lower-body
occlusion. Both employee silhouettes stay readable, the physical feet remain on
the logical work cell, and failure/leave transitions do not leave a standing
torso embedded in the workstation.

| Category | Score | Review basis |
|---|---:|---|
| Pixel coherence | 2 | Native nearest pixels; source detail and work pose density differ slightly. |
| Perspective | 3 | Desk, monitor and rear chair share one North-facing projection. |
| Silhouette/readability | 2 | Readable at 1×, though hands are intentionally mostly hidden. |
| Layering/anchors | 3 | Rear chair and front desk consistently bracket the seated actor. |
| Direction consistency | 3 | All authored components and poses face North. |
| Placement | 2 | Reviewed paths and reservations pass; contact remains a practical inferred seat rather than a bespoke mount animation. |

**Mean 2.50; minimum 2.** This meets the required visual gate while recording
the abrupt source swap between locomotion and seated art as remaining polish.

Automated evidence: headless `2747/0` and native `2831/0`, each with 194 physics
ticks and 228 rendered frames. The production copy is hash-locked by
`test_reviewed_workstation_production.gd` and is also shown through ordinary
`GameMain` in
[`production-north.png`](../../game/tests/output/reviewed-workstations-production/production-north.png).
