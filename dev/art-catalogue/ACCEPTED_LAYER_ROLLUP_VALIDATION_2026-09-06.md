# Accepted required-layer rollup validation

Date: **2026-09-06**

The catalogue validator now requires an accepted family's required semantic
layer rollups to match its exact family lifecycle:

- an `approved` passive-library family requires every direction and every
  `required: true` layer to be `approved`;
- a `runtime_integrated` family requires every direction and every
  `required: true` layer to be `runtime_integrated`;
- optional future or ambient layers (`required: false`) remain outside this
  gate and may truthfully stay planned.

This prevents four approved views from coexisting with stale
`native_review_required` family-layer labels, while preserving the distinction
between passive art approval and runtime installation.

The self-test uses a normalized in-memory accepted catalogue, then proves
targeted rejection for the former `broadleaf_planter` and
`creative_design_kit` stale passive rollups and for a deliberately downgraded
required runtime desk layer. A separate positive case leaves the optional
mobile-whiteboard shadow planned.

Current catalogue verification after the shared metadata normalization:
**30,623 checks / 0 errors and 107 self-tests**, 42 families / 168 directions,
132 passive-library views plus 36 runtime-integrated views. This change does
not alter the catalogue, art, runtime data, worker, saved state, or approval
scores.
