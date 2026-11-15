# Runtime character atlases

All runtime characters render at scale 1 with 48 × 80 pixel cells and a shared
bottom-center foot anchor at `(24, 72)`.

- `founder-locomotion.png`, `mira-locomotion.png`, `theo-locomotion.png`, and
  `creative-locomotion.png`: 6 columns × 4 rows. Rows are front, back, left, right;
  columns 0–1 are idle and columns 2–5 are walking.
- `mira-seated.png` and `theo-seated.png`: 6 columns × 1 row. Columns 0–1
  are chair-seated idle/blink; 2–5 are typing. No baked furniture or laptop.
- `mira-work.png` and `theo-work.png`: 8 columns × 4 rows. Row 0 columns
  0–1 remain lunch poses and 6–7 approval; row 1 is research and thinking;
  rows 2–3 are delivery. The old cross-legged typing cells 2–5 are superseded.

`mira` is the stable runtime employee ID for the character displayed as Mina.
Rebuild these files from `assets/source/` with
`dev/tools/build_polish_assets.sh`; do not rescale them in a scene.
The seated correction can also be rebuilt independently with
`dev/tools/build_workstation_assets.sh`. It shares one palette, baseline, and
head center across each employee's frames to prevent pose jitter/color flicker.

The measured locomotion export also applies the reviewed eye-only overlays in
`assets/source/web-eye-polish/` to the Founder and Theo front-idle blink.
They preserve the original palette, alpha, frame positions and all other poses.
