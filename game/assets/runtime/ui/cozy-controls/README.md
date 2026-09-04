# Quiet notebook controls

One generated slim walnut button master replaces the flat layout-proof controls.
The existing outer notebook, portraits, header and parchment are reused. Inputs,
focus, cards and scroll tracks remain deliberately quiet code-native shapes;
they do not need separate illustrated assets. All text stays live in Godot.

- Master: `game/assets/source/ui-redesign/slim-control-master.png`.
- Exact built-in ImageGen prompt: `game/assets/source/ui-redesign/PROMPTS.md`.
- Rebuild: `PATH=/opt/homebrew/bin:$PATH bash dev/tools/build_ui_redesign_assets.sh`.
- Layout proof before generation: `game/tests/output/ui-redesign/layout-proof/`.

## Runtime contract

| Family | Native size | Slicing and content |
| --- | --- | --- |
| Secondary/primary/danger × four states | 96×48 | 6px protected corners; 12px horizontal and 8px vertical text insets |
| Slider thumb × three states | 24×24 | Native fixed size; derived from the exact same six-pixel frame corners |
| Chevron and close | 16×16 | Code-authored pixel glyphs; centered in controls of at least 44px height |

All PNGs have binary alpha, no mipmaps, nearest sampling and lossless import.
Controls expand by nine-slicing, never by whole-image scaling. All button states
have identical geometry and alpha. Focus is a separate two-pixel indigo outline,
not the success color. Hover and pressed states change the quiet interior fill;
button-down feedback is immediate and release settles in 80ms without scaling.

The generated master had an opaque checkerboard outside the silhouette, despite
the transparent-background request. Normalization crops the frame at
`1550×675+112+106`, samples to 96×48, and removes only near-white neutral exterior
pixels. The warm center is standardized to flat cream; all semantic variants
are derived from that one frame with exact center-color replacement. This also
prevents state-to-state corner wobble. The slider is assembled from the same
corners and straight edges, with two code-authored grip marks. No checkerboard
pixels survive in runtime assets.

Palette: charcoal `#151515`, cream `#FFF4DF`, walnut frame, Vermilion `#FA4616`,
Indigo `#354B98` focus, pale-danger `#FCE5D7`, disabled `#DED7C9`.
Pressed primary uses `#F94A1D` before the 0.94 button-down tint; the final ink
contrast stays above 4.5:1. The first darker press color failed the rendered
foundation gate and was corrected before acceptance.

Acceptance: native text stays inside content insets, texture margins never cut
corners, alpha matches between states, runtime resizing preserves source corners,
all visible states have readable ink, and a second build produces identical PNG
hashes. The master and normalized runtime files are separate; the original is
retained unchanged.
