# Warm wooden chair family

The starter studio uses a plain oak chair with a small cream cushion. It replaces the narrow corporate/caster chair without moving the actors' hips, hands, work cells or seated layer cuts. The same six native modules serve desks and all collaboration-table chairs.

Source: built-in OpenAI ImageGen, output `01a1e146-9490-71d0-99d4-d5691e91d349/exec-7c6977b3-bf04-43fe-b2fb-f2c62aa4ad9e.png`. `prompt.txt` is the exact request. Inputs were `original-four-views.png` (edit/registration target), `scale-reference.png` (same-scale character/ground reference), and the canonical `dev/art-catalogue/style-reference-board.png` (`startup-valley-cozy-pixel-v1`). The original runtime modules are retained in `previous-runtime`; the original combined views are geometry references, not generated replacement art.

`generated-four-views.png` is the untouched output. Fixed object crops are declared in `game/tools/build_task_chair.gd`. Each becomes a32×58 nearest sample, binary alpha with zero hidden RGB, inside the unchanged96×160 canvas. The first tall-back candidate is retained in `first-tall-candidate`; its back reached too close to Mina's bun. Only the upper29 sample rows are shortened to14 at source y85. The cushion and legs remain unchanged at y99–127. Final visible extent is32×43, including projected foot depth. This partial normalization is deliberate; the whole occupied assembly was never scaled.

The side near-frame module copies rows109–159 from the corresponding whole chair. It replaces the former near-arm layer while keeping its historical node name, depth and offset. No generated people, desk or background pixels are retained.

Rebuild/verify (no window):

```
godot --headless --path game --script res://tools/build_task_chair.gd -- --verify
```

Use `--apply` only when intentionally installing these source bytes. `update_shared_chair_profiles.gd` emits the collaboration layer/bounds candidate; the catalogue retains all existing cells, slots and actor anchors. The only desk-bound change is south's measured visual/hit union `[-48,-71,96,87]`, because the shorter back no longer paints the former upper9px. It changes no collision cells.

See `technical-validation.json`, the hash-bound `task-chair-v3` runtime review, and `docs/decisions/2026-11-15-wooden-chair-family.md`. Runtime PNGs are an art replacement, not a code-generated redraw. The builder only crops, resamples, registers and splits the retained ImageGen output.
