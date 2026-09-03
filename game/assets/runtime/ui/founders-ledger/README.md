# Founder's Ledger HUD texture kit

Text-free runtime textures for the selected Option B HUD direction. Godot must
render all changing copy, values, icons, focus states, and actions as native UI
over these images.

| Texture | Authored size | Intended content | Text-safe region |
| --- | ---: | --- | --- |
| `ledger-hud-frame.png` | 408×68 | day, time, money | day `16,12–140,56`; time `180,12–280,56`; money `294,12–392,56` |
| `title-plaque.png` | 224×56 | company/game title | `18,12–206,44` |
| `notification-memo.png` | 230×100 | completion heading, artifact summary, view action | `18,22–212,86` |
| `interaction-prompt.png` | 130×52 | keycap and contextual action | `12,10–106,42` |
| `movement-plaque.png` | 240×48 | movement controls hint | `18,10–222,38` |

Coordinates are in runtime-texture pixels as `left,top–right,bottom`. Treat the
ledger, memo, and interaction prompt as fixed-proportion textures: their binder,
irregular edges, and speech tail should not stretch. The title and movement
plaques may use nine-patch margins of 18 px horizontally and 12 px vertically.

Import with lossless compression, filtering disabled, and mipmaps disabled.
Scale by whole-number UI factors whenever possible. The high-resolution source
masters are retained at
`assets/concepts/ui/hud-options/option-b-components/masters/`.

The source art was generated with built-in ImageGen in reference-image mode,
using the selected full-screen mockup. Generated white/checker mats were removed
mechanically, the silhouettes were trimmed, and runtime copies were reduced with
nearest-neighbor sampling.
