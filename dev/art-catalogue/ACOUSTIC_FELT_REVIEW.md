# Acoustic felt material — initial native study

2026-09-04 10:37 UTC. **Material candidate only; no acoustic-divider geometry,
four-view export, room placement or runtime approval yet.**

One new built-in ImageGen original after the frozen113-source catalogue:
`game/assets/source/overnight-20260904/materials/indigo-acoustic-felt-v1.png`,
1254×1254 RGB. Exact prompt and provenance are beside it. No targeted retries.
The source is deliberately an opaque fill, not a failed furniture cutout.

`dev/tools/build_acoustic_felt.sh` uses point sampling to32×32 with a six-color
palette and no dithering. It also produces exact8× viewing, a96×96 three-by-three
repeat and an88×56 tiled panel with enlarged diagnostic copies. These six
derivatives rebuild byte-identically and are not six generated originals.

Native tile:1,024 opaque pixels. Histogram:

| Color | Pixels |
| --- | --- |
| `#4A5884` | 857 |
| `#44527C` | 122 |
| `#606988` | 31 |
| `#3C4A72` | 12 |
| `#3F4F80` | 1 |
| `#7A8094` | 1 |

Native PNG SHA-256:
`67c7eecdb48a48da0850bbaadbda7b06a39dbc9a7e747d71abc3b1471884e9c7`.

Root inspected source, tile8×, repeat4× and panel8×. The point-sampled palette is
quiet and avoids the long repeating scratches of the rejected terrazzo study.
It is subdued blue fabric-like noise rather than strongly resolved wool fibers;
that is appropriate to a small panel but still needs actual-room review.
Opposite edge samples differ at8/32 X and5/32 Y positions. This is **not an exact
edge-matched tile**; stochastic material can tolerate differing adjacent texels,
but no seamlessness or visual-repeat acceptance is claimed without the intended
panel in the room. Do not repaint edge pixels or globally recolor merely to make
an arithmetic metric pass.

The proposed consumer is a separately constructed screen-aligned acoustic panel
with real thickness, physical feet and registered native layers. Its source
material does not imply four generated views. Existing office wood, UI skin,
catalogue runtime status and all gameplay remain untouched.
