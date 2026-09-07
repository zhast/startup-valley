# Acoustic divider — bounded next prototype

2026-09-04. Dev-only, physical passive furniture study. No production catalogue,
layout, saves, worker actions, character sockets or UI skin changes. This is a
new code-native construction using one generated material, not four generated
furniture images. Existing whiteboard/pedestal and their evidence stay frozen.

## Physical model to validate before drawing

- Fixed room camera and32px floor cells; native192×224 canvas with pivot(96,160).
- Double-sided fabric panel88px wide,6px thick,56px vertical face. Lower face
  edge8px above its local ground, upper edge64px. This is a modest shoulder-height
  divider beside the approximately68px standing characters, not a tall wall.
- Broad N/S visible near face `(-44,-61,88,56)`: near thickness edge is y+3,
  hence top3−64=−61 and bottom3−8=−5. Top plane `(-44,-67,88,6)` uses the far
  edge at−3−64. Front/back are genuinely double-sided fabric; N/S may share a
  geometrically identical projection if that equivalence is explicitly recorded.
- E/W panel has only its6px edge visible: ground-axis extent−44…44 combined
  with vertical height gives `(-3,-108,6,144)`. This long silhouette is88px
  ground-axis depth plus56px elevation, not a144px-high wall. The near end begins
  at y44−64=−20; explicitly differentiate the top/near-end plane there.
- Two freestanding flat feet fit the96×32 broad floor rectangle
  `(-48,-16,96,32)`, exchanged to32×96 for E/W. Three occupied cells broad,
  or three lengthwise narrow. No caster or chair imagery is borrowed.
- All silhouettes/feet must fit these declared limits. No extra outline pixels
  may silently escape the floor or canvas. Draw actual native rounded/stepped
  foot caps and a restrained warm-oak or charcoal frame; no diagonal-isometric
  legs. Keep fixed screen-upper-left lighting.
- Neither side has a service action or standing-viewpoint requirement. This
  panel simply partitions furniture areas; ordinary floor reachability still
  applies. Do not invent an interaction cell, employee gaze or usable work point.

## Art and layers

Generated32×32/6-color felt lives at
`game/tests/fixtures/furniture-calibration/acoustic-felt-v1/felt.png`.
Use the original pixels tiled into the rectangular fabric interior; no semantic
repainting, random tile jitter, runtime scaling or rotated texture. Its repeat
quality is unapproved until actual-room viewing. Source/prompts and measured
limits: [felt review](ACOUSTIC_FELT_REVIEW.md).

Register full-canvas rear-foot/support, panel/frame/material and front-foot
layers at the same floor pivot. Empty layers may remain explicitly empty.
Do not add a cast-shadow claim unless a separate actual shadow is authored and
reviewed. Retain raw independent whole/part exports and true transparent padding.
If N/S or E/W images are physically equivalent, say so rather than presenting
duplicates as separately generated or asymmetrical variants.

## Bounded proof and acceptance

1. Independent geometry arithmetic and whole/layer reconstruction, exact alpha,
   declared bounds, material-source identity, native sampling and fixed light.
2. Fresh worker-disabled actual room; clear comparison with employees, oak desk,
   approved archive and walking in front/behind. Inspect all four1× views and4×
   details, especially edge readability and whether the panel looks too tall.
3. Instance-only passive profile using already-tested explicit decorative
   admission, if feasible without changing frozen production code. Validate
   floor/wall/visual overlap and navigation; actual R/commit/undo once, not a new
   giant combinatorial suite. No serialized production registration.
4. Score all six art categories, no category below2 and mean at least2.5 for
   this isolated prototype. Repeat seams, skeletal feet, or vague E/W identity
   are real reasons to withhold art acceptance despite passing geometry.

This replaces the catalogue's untested160px-rise proposal only if native evidence
supports the new model; preserve that old proposal in history. Catalogue slots
remain missing/planned until actual native exports and review exist.
