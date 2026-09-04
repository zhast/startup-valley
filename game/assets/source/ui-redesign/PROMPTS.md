# UI redesign component provenance

## Slim control frame — built-in ImageGen

Master: `slim-control-master.png` (1774×887).
SHA-256: `b8175b9f480c639c413474069fb5663c7a72040b27433e3bdd1812f95bb23710`.
The runtime build keeps the master unchanged and fixes its baked exterior matte.

Reference: `game/tests/output/ui-redesign/layout-proof/chat.png`, real Godot
layout with corrected fonts. This is a style reference, not an edit target.
The typography/layout proof was inspected before generating this component.

Exact prompt:

> Use case: stylized-concept. Asset type: a single reusable game UI button-frame master for Startup Valley. The attached image is a STYLE REFERENCE only: preserve its cozy walnut and parchment material language, but do not reproduce its screen, text, portraits, office, or layout. Generate ONE empty, front-facing horizontal button, aspect ratio 2:1, centered and filling most of a transparent canvas. The intended runtime size is 96 by 48 pixels; render a clean enlarged pixel-art master with aligned square pixels, not a photograph. The button has a very slim warm walnut outer edge, a subtle upper-left amber bevel and lower-right dark bevel, and a large perfectly quiet pale cream parchment center. The edge consumes only 4 runtime pixels on each side, with 4-pixel stepped corners. Thin, restrained wood grain belongs only inside the edge. No thick picture frame, rivets, screws, decorative ornaments, notches, symbols, lettering, shadows outside the silhouette, glow, gradients across the center, perspective or tilt. The entire center must be flat light cream, suitable for live dark text. Keep opposing edges straight, parallel and symmetric so the button can be nine-sliced without distortions. Transparent outside the button; actual alpha, no checkerboard. Original Startup Valley art, not copied game assets. Output only the single blank button asset, no labels or presentation board.

Runtime normalization, dimensions, alpha, slice margins and state derivation are
documented in `game/assets/runtime/ui/cozy-controls/README.md`.
