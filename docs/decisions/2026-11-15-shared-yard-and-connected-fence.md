# Share native yard modules and connect the actual boundary

The starter studio and courtyard now use the same 32px lawn/paving system and
restrained planting. The courtyard boundary is a low wooden fence assembled
from native post and rail modules. This replaces the estate-like background,
repeated vertical hedge stamps and porous boundary rejected during playtest.

## Geometry and source rules

- Every module uses the existing 32px lattice, unit runtime scale and nearest
  sampling. Lawn is one contiguous 128px repeat made of sixteen 32px cells;
  paving is a shared 32px cell. Planting uses registered ground anchors.
- Lawn and hedge source images are original OpenAI ImageGen results, retained
  with prompts, references and deterministic normalization in
  `game/assets/source/modular-yard/`. Paving is an unchanged crop of existing
  `campus-surround.png`; its older provenance is not claimed as new generation.
- The fence source is a separate original ImageGen kit referenced to the
  canonical style board and wooden chairs. One post, paired horizontal rails
  and a separately drawn north–south rail are cropped/resized once into a
  64px atlas. Horizontal art is not rotated into another camera direction.
  Source, prompt and transform are in `game/assets/source/yard-fence-v1/`;
  `dev/tools/build_yard_fence.mjs --verify` checks reproducible output bytes.
- `YardFence` derives 82 exposed edges from the existing 373-cell courtyard
  floor. The registered Studio opening omits exactly two south edges at
  x480–544, y640, leaving 80 rails and 81 shared posts. Both gate terminals
  remain; there is no center post or rail across the opening.
- The gate is tied to the existing return interaction and paving. It is not a
  new walkable outdoor region. The fence adds no collision, navigation, save
  state or travel rule; it visualizes the already bounded space.

New maps must register their modules, ground anchors, actual boundary and exit
semantics. A decorative gap cannot invent travel. Keep geometry checks and
visual admission complementary: neither establishes the other's correctness.

## Current evidence and limits

Approved browser build: **`d23a483542544696`**. Runtime fingerprint:
`5e8afa18aa826a0883d0af6506aa47c96e9d405c7766fe86befe7d474c882ebd`.

The parent used the existing background Codex in-app browser to inspect the
starter studio, full office, courtyard front/northwest and Mina invitation.
The current frame [manifest](../web/assets/world-final/capture-manifest.json)
binds exact images and build identity. The front view shows intentional
lower-leg foreground occlusion with the face/torso clear; the northwest view
shows connected rear/side rails and the actor in front of the rear boundary.
The Studio opening remains visible and aligned with the actual return.

An [independent review](../web/assets/yard-fence-v1/independent-review/README.md)
compared these actual browser images and audited the exact seven-file runtime
delta. All 170 selected worker/web/protocol/navigation/actor files match the
prior clean-journey inventory. Removing new gate metadata leaves the prior
courtyard floor, paving, props and interaction data deeply equal. Independent
reachability confirms the boundary does not cut legal center-to-center paths.

Validation: **752** headless fence checks, **17** map-admission tests and **9**
component route checks passed; the separate geometry probe also passed. All
**75** root tooling tests and the map release gate passed at admission. The
three map reviews and two new atlas reviews are approved and hash-bound.
The prior **914-check** clean journeys apply to unchanged gameplay through
the documented delta; no new full journey on the fence runtime is claimed.

Old vertical-stamp, porous-boundary and sealed-fence screenshots stay rejected.
The first sealed fence looked connected but covered the existing return; its
replacement was not accepted until the explicit two-cell gate was visible.
Current static approval is limited to the recorded composition and poses,
not all animation cycles, platforms or possible furnishing arrangements.

## Non-disruptive verification

The owner explicitly prohibited further windowed Godot demos. These current
checks use headless Godot and the existing background in-app browser. Do not
launch native capture windows, activate other browser profiles or control the
OS. Old native component captures retain only their historical source scope.
Final export identity, full asset gate and packaging are tracked by the root
handoff; this decision does not declare the whole demo goal complete.
