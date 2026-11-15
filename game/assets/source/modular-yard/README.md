# Modular village yard

This family replaces the monolithic estate-like garden with shared native
terrain modules for the starter studio and courtyard. It is not a room painting.
The atlas is 192×192: sixteen 32px lawn cells form one contiguous 128px repeat,
one 32px stone cell, and three transparent 64px hedge canvases. Every runtime
placement uses the common 32px grid at scale 1 with nearest filtering.

`grass-generated.png` and `hedges-generated.png` are original built-in OpenAI
ImageGen results, retained with the exact prompts. Both requests used the
canonical `startup-valley-cozy-pixel-v1` board and an existing-art crop as an edit
reference. The source crop rectangles, generation identifiers, content hashes,
and complete normalization are in `derivation.json`. Paving is an unchanged
32px crop of the pre-existing `campus-surround.png`; its older origin is not
claimed as part of these generations.

Rebuild from the repository root with a local Sharp installation:

```sh
node dev/tools/build_village_terrain.mjs
node dev/tools/build_village_terrain.mjs --verify
```

`SHARP_MODULE` may point to an existing Sharp module. The verify command is
read-only and compares every output byte. Normalization uses nearest-neighbor
sampling, one alpha threshold for all hedge pixels, and fixed shared ground
pivots. It does not repaint silhouettes or place pre-rendered actors.

The earlier direct grass/hedge crops were rejected for repeating patches and
mechanical stripes. They are references, not approved runtime art. Current
geometry and route checks pass. The final terrain was visually approved in
exported Godot build `d23a483542544696`; retained current captures and their
hashes are in `docs/web/assets/world-final/` and the runtime/map review records.

The first in-app candidate confirmed the new lawn was quieter but rejected
vertical rows of the low, wide shrubs: their silhouettes left gaps that looked
like repeated buttons. The current maps use sparse, staggered horizontal shrub
groups declared in `terrain_plantings`. No vertical stretching, rotation, new
pixels or hidden collision were introduced for that composition correction.
The courtyard's physical boundary is communicated by the separately registered
connected wooden fence; these sparse shrubs remain decoration.
