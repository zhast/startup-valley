# Reviewed character motion corrections

These native-resolution source patches preserve the existing character identity,
frame dimensions, foot anchors, and palette. They are extracted from built-in
OpenAI ImageGen treatments rather than whole-atlas replacements.

## Mina seated blink

The original second idle cell left both eyes open and painted 28 pale pixels
through the bangs instead. `mira-seated-blink-overlay.png` restores those hair
pixels and gives the character two closed eyelids. It changes 86 opaque pixels
in that cell only; all alpha, other frames and body pixels remain byte-identical.

The canvas is 288×80. Changed pixels are restricted to global rectangles
`[65,22,15,3]`, `[65,26,6,5]`, and `[74,26,6,5]`.
The [prompt and generation record](prompts/mira-seated-blink.md) describe the
point sampling and palette registration. The standard seated export script
reapplies this overlay after rebuilding the original master.

## Side walk cycles

The four locomotion atlases advanced frames correctly, but their side-view feet
remained spread in nearly the same pose. For example, the Founder's right-facing
foot silhouette was exactly 32 pixels wide in all four frames. New contact and
passing poses now vary between 33, 18, 31 and 16 pixels.

Each `*-walk-overlay.png` replaces only local rows 52–71 of side-facing walking
cells (columns 2–5, atlas rows 2–3). Front/back walks, all idle cells, faces,
eyes, upper bodies and animation timing remain unchanged. The generated sources
were sampled on the native grid, aligned by head center and foot plane, and
mapped to each original palette. Original non-leg colors at the join preserve
hands, jacket edges and bags. No poses were mirrored or painted by code.

`walk-replacement-mask.png` clears those two strips before compositing the
accepted source pixels, so transparent gaps actually remove the old spread
legs. Reapply with:

```sh
bash dev/tools/apply_character_motion.sh founder \
  game/assets/runtime/characters/founder-locomotion.png \
  game/assets/runtime/characters/founder-locomotion.png
```

The operation is idempotent. `build_locomotion_assets.sh` includes it for the
three original master exports; Creative uses the same helper directly.
`manifest.json` records the exact source registrations, generation IDs and
decoded before/after hashes. Prompts are retained in `prompts/`.
