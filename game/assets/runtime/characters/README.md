# Runtime character atlases

All runtime characters render at scale 1 with 48 × 80 pixel cells and a shared
bottom-center foot anchor at `(24, 72)`.

- `founder-locomotion.png`, `mira-locomotion.png`, and
  `theo-locomotion.png`: 6 columns × 4 rows. Rows are front, back, left, right;
  columns 0–1 are idle and columns 2–5 are walking.
- `mira-work.png` and `theo-work.png`: 8 columns × 4 rows. Row 0 is seated,
  typing, and approval; row 1 is research and thinking; rows 2–3 are the four
  delivery directions.

`mira` is the stable runtime employee ID for the character displayed as Mina.
Rebuild these files from `assets/source/` with
`dev/tools/build_polish_assets.sh`; do not rescale them in a scene.
