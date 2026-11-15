# Modular yard evidence

The shared 32px terrain is visually approved in exported Godot build
`d23a483542544696`. Current in-app captures are retained in
[`../world-final/`](../world-final/capture-manifest.json); the original reports
in this directory remain component evidence for their source manifests.
No windowed Godot test was launched for these records or the new browser review.

- `terrain-geometry.json`: 407 headless checks, no failures. Covers the real
  studio threshold, unchanged courtyard coordinates/bounds, all five placed
  prop anchors, legal saved destinations, unblocked boundary cells, and sparse
  planting groups without long vertical stamp chains.
- `routes.json`: 9 headless checks, no failures. The actual player follows
  routes around real desk/planter collision in scene components using the
  retained furnishing fixture. This is not a freshly earned gameplay journey.
- `source-manifest.json`: exact tested source/art and report hashes.

Additional checks at this component checkpoint passed: 15 map-admission tests, 29 starter-office
checks, `run_all.gd`, `validate_project.gd`, both preview gates, and byte-exact
atlas regeneration. These older counts are not the final fence test counts.
The old giant garden and earlier grass/hedge crops were rejected. Do not use
their historical native captures as approval for this composition.

`rejected-vertical-stamps.jpg` is the actual first in-app terrain candidate.
The main agent confirmed the quieter lawn but rejected its staircase-like side
hedges. Current map data replaces these with sparse, staggered shrub groups;
the final courtyard additionally uses a connected wooden boundary with a
registered two-cell opening at the existing Studio return.

The three current map reviews and the terrain/fence atlas reviews are now
approved. The final [independent fence review](../yard-fence-v1/independent-review/README.md)
records 752 fence checks, 17 map tests, 9 component routes and the exact
seven-file delta from the prior clean-journey runtime. Its final fingerprint is
`5e8afa18aa826a0883d0af6506aa47c96e9d405c7766fe86befe7d474c882ebd`.
Existing floor, movement bounds, props and interaction coordinates are unchanged.
Current static approval does not claim every animation or final package acceptance.
