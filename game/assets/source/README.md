# Polish asset masters

This directory contains the source masters used by
`dev/tools/build_polish_assets.sh`. Godot ignores the directory through
`.gdignore`; only the normalized files under `assets/runtime/` ship in the
game.

The `polish/` images are original Startup Valley ImageGen outputs made from the
project's existing character and office sheets as identity, palette, lighting,
and projection references. The `office-masters/` images preserve the original
approved prop canvases that preceded native-size normalization. Exact briefs
and prompts live in `dev/POLISH_AUDIT.md`.

Run the build from the repository root with ImageMagick 7 installed:

```sh
dev/tools/build_polish_assets.sh
```

The script removes generated outer backgrounds, cuts exact grids, applies one
shared scale per sheet, quantizes the palette, aligns the documented anchors,
and writes RGBA PNGs with nearest-neighbor sampling. Generated masters must
never be referenced directly by runtime scenes.
