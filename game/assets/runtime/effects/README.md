# Runtime polish effects

These transparent atlases are deliberately small and render at scale 1:

- `world-state-vfx.png`: 4 × 6 cells at 24 × 24. Rows are thinking, typing,
  research, approval, completion, and failure. Work VFX are selected only from
  real `WorkerEventRecord` events.
- `ambient-office.png`: 4 × 5 cells at 32 × 32. Rows are coffee, monitor,
  research, prototype, and archive ambience.
- `character-shadows.png`: three 32 × 16 standing, walking, and seated contact
  shadows.
- `office-unlock.png`: six 64 × 64 furniture-arrival frames; the final frame is
  fully clear.

Source masters and the deterministic normalizer live in `assets/source/` and
`dev/tools/build_polish_assets.sh`.
