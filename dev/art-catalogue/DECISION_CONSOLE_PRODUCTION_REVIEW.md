# Decision console — four-facing production review

September 4, 2026. **PASS for the standing approval/activity station.** The
console is an original code-native Startup Valley assembly using the established
oak, charcoal, Indigo, Cerulean, Vermilion and Chartreuse palette. Its North,
East, South and West views have independent source layers and geometry; no
finished bitmap is rotated or mirrored.

The native
[`actual-room-contact-sheet-native.png`](../../game/tests/output/decision-console-room/actual-room-contact-sheet-native.png)
was captured from the actual office/navigation/editor path. That review caught
and corrected an initially reversed floor-pivot offset before promotion. The
final North view shows the monitor back and maintenance panels, South exposes
the approval controls, and the side elevations preserve their service-side
identity.

| Category | Score | Basis |
|---|---:|---|
| Pixel coherence | 3 | Clean binary alpha, native nearest pixels and restrained palette. |
| Perspective | 3 | All views use the same fixed-camera rise and floor pivot. |
| Silhouette/readability | 2 | Clear console shape at 1×; intentionally simpler than specialist workstations. |
| Layering/anchors | 2 | Four stable layers and exact bounds; ambient activity is currently static. |
| Direction consistency | 3 | Front, rear and side identities match their named service side. |
| Placement | 3 | All four masks, service cells, routes, hit surfaces and transactional rotations pass in the actual room. |

**Mean 2.67; minimum 2.** The family is production-ready as a standing service
station. It does not claim a reaching/pressing character pose or animated screen
frames; those remain separate polish assets.

Evidence: deterministic export `26/0`, pixel/geometry test `221,213/0`, headless
actual-room test `63/0`, native actual-room capture `72/0`. Runtime PNG hashes
are frozen in `game/assets/runtime/office/approval-console-v1/manifest.json`.
