# Directional furniture calibration fixtures

Development-only generated art candidates. Not registered by the production furniture catalogue.

- `desk-south-v2.png`, `desk-north-v2.png`, `desk-east-v3.png`, `desk-west-v3.png`: mechanically normalized from the independently drawn ImageGen sources using `dev/tools/build_directional_calibration.sh`.
- Shared proposed desk canvas:192×224; footprint/sort pivot:(96,160).
- Physical width:96px. South/north footprint:3×1 logical32px cells. The visible contact bottom is16px south of the pivot, not falsely labeled the pivot itself.
- Alpha threshold50%, point resampling, palette limit48, one shared crop before any layer split. No raster rotation/mirroring or perspective manipulation.
- Intended east/west footprints are1×3 cells, with a32×96 tabletop. Their4px outside cable trays are registered separately from the32px-wide body. Native four-view room evidence: `game/tests/output/furniture-rotations/`.
- Character and chair sub-studies have their own builder/review files under `dev/tools/` and `dev/art-catalogue/`. They remain independent candidates, not an accepted assembly.
- Status: **cleanup required, not runtime-ready**. Measured tabletop depth/rise does not match the intended geometry: N2 top96×27/rise41, S2 top96×29/rise37, E3 top32×96/rise34, W3 top32×94/rise34. The target elevation is32px. Alpha bounds and canvas size alone did not detect this. See `dev/art-catalogue/NORTH_SOCKET_REVIEW.md`.
- `modular_desk_geometry.gd` is a separate dev-only alternative: native code owns exact top/leg geometry and generated32×32 material tiles provide the finish. It does not rotate or repaint these failed whole-prop images. Its placeholder seat references are not production sockets; supported north/south assembly studies use the real logical work cells.
- Final layers, role decor, supported seated/standing transitions, collision integration and runtime approval remain outstanding. A clean component or test fixture must not be mistaken for an approved assembled workstation.
