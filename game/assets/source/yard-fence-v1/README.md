# Connected courtyard fence

Original built-in ImageGen result `generated-kit.png` contains a post, paired
horizontal rails and a separately drawn north–south rail. The actual retained
prompt supplied the canonical `startup-valley-cozy-pixel-v1` board and current
wooden-chair family as material references. No game sprites were copied from
another game, and no horizontal art is rotated into the vertical view.

`dev/tools/build_yard_fence.mjs` finds the three source alpha bounds, resamples
each once to its declared native size, applies binary alpha, and places the
pieces in a 64×64 runtime atlas. `derivation.json` records exact crops,
registration and input/output hashes. `--verify` checks byte-for-byte output.

`connection-preview.png` is an enlarged component assembly for inspecting joins,
not an in-game capture or a visual approval. The runtime boundary must follow
the actual courtyard navigation floor, with one shared post per vertex and
explicit cardinal connection masks. This adds no new collision or travel rule.
The only opening is the map-declared two-cell Studio return entrance, tied to
the existing interaction and paving. Both terminal posts remain.

The final family was visually approved in exported Godot build
`d23a483542544696`, including foreground feet occlusion, northwest joins and
the open Studio entrance. See `docs/web/assets/world-final/` and
`docs/web/assets/yard-fence-v1/independent-review/` for current evidence. This is
static fence approval; it does not certify every character animation.
