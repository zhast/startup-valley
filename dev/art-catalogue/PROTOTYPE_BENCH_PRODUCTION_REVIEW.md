# Prototype bench — four-facing production review

September 4, 2026. **PASS for the standing shared fabrication station.** The
bench is an original code-native assembly, not a rotated legacy bitmap. Its
South face exposes a compact printer, cutting/test surface and color-coded
tools; North shows the service back and cable rail; East and West are distinct
side elevations.

The native
[`actual-room-contact-sheet-native.png`](../../game/tests/output/prototype-bench-room/actual-room-contact-sheet-native.png)
uses the actual office floor, navigation and transactional rotation path.

| Category | Score | Basis |
|---|---:|---|
| Pixel coherence | 3 | Binary alpha, native nearest sampling, established palette. |
| Perspective | 3 | Consistent fixed-camera rise and `(96,240)` floor pivot. |
| Silhouette/readability | 2 | Strong bench/machine silhouette; intentionally compact tool detail. |
| Layering/anchors | 2 | Shadow, rear, front and tools are separable; no dedicated actor hand-contact pose yet. |
| Direction consistency | 3 | Public tool face, service rear and two side elevations remain distinct. |
| Placement | 3 | Four masks, aisles, routes and real room rotations pass. |

**Mean 2.67; minimum 2.** This closes the base shared prototype bench. It does
not close the separate profession-specific host kits or reaching/using poses.

Evidence: export `25/0`, deterministic pixel test `245,777/0`, room headless
`39/0`, room native `48/0`. Runtime hashes are frozen in the adjacent manifest.
