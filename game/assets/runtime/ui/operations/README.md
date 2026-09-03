# Operations UI texture kit

Text-free runtime components for real worker states inside the notebook drawer,
artifact reader, chat transcript, Studio file list, and in-world employee labels.
Godot renders all changing copy, values, progress, and interactions over these
textures.

The kit is organized as reusable families rather than screen-sized bitmaps:

- Journal: active-work, approval, delivery, token-meter, activity-row, and
  eight semantic event icons.
- Artifact and Studio: document reader, paper, close control, file cards,
  document/folder/delivery icons, and empty archive tray.
- Controls: primary and secondary interaction states, dropdown, selected row,
  keyboard focus ring, attention badge, and vertical/horizontal scrollbars.
- Conversation and world: founder/employee/system bubbles, speech bubble,
  nameplate, status plaque, attention pin, and availability light.

Import with lossless compression, filtering disabled, and mipmaps disabled.
The texture centers are intentionally quiet and stretch-friendly. Keep live text
inside the `OperationsSkin` content margins; do not bake runtime data into art.

High-resolution ImageGen source sheets are retained at
`assets/concepts/ui/operations-components/masters/`. They were generated in
built-in ImageGen mode using the approved notebook component sheet as the style
reference, then alpha-cleaned, cropped, and reduced with nearest-neighbor
sampling.
