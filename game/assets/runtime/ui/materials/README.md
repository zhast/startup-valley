# Native notebook material parts

These are narrow production component parts, not whole-screen mockups. Text
stays live using the selected C typography. Build with
`bash dev/tools/build_ui_material_assets.sh` from the repository root.

- Quiet controls and notebook tabs: **96×48**, six-pixel protected corners.
  Quiet controls reuse the existing slim walnut master. Tabs open into their
  page; Vermilion is a selection rule, not a full action-colored face.
- Card, dialogue, inset field, read-only field, popup and selection: **48×48**,
  six-pixel slices. Shared stepped corners and top-left light; fields invert
  the edge/shadow to read as editable wells. Calm solid centers keep ink clear.
- Focus: **48×48**, hollow indigo stepped outline. Inset, never expanded beyond
  the click target. A six-pixel slice protects the corner turn.
- Vertical track/thumb: **12×24**; horizontal: **24×12**. Three-pixel slices
  preserve end caps and grip. Slider fill uses an indigo inlay; its existing
  native **24×24** control thumb is retained.
- Document: **24×28**; folder: **32×24**; check marks and Close: **16×16**.
  These are native pixel glyphs, not shrunken large decorated art. Close ink is
  inside an independently sized **44×44** minimum interaction target.

Every image uses binary transparency and lossless import without mipmaps.
Controls use nearest filtering and never change scale/geometry on hover/press.
The material metadata (`cozy_family`, `cozy_material`) records purpose for
tests; it does not by itself prove visual quality. Native production specimens
and actual input tests remain required.

Source: existing Startup Valley slim-control master plus manually authored
pixel edges/glyphs in the builder. No generated text, external art, or new font.
