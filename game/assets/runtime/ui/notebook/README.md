# Notebook UI texture kit

Runtime nine-patch and frame textures for the employee drawer. The reusable
kit was generated from the selected notebook mockup, alpha-extracted, sliced,
and reduced to the game's authored UI scale. Godot renders real controls over
these textures.

The narrow team rail is the exception: its four state textures are measured
crops of the approved reference so the visible roster matches it pixel for
pixel. Transparent native buttons and status overlays remain interactive over
the texture. The source reference is retained at
`assets/concepts/ui/team-drawer-options/notebook-sidebar-reference.png`.

The source atlas is retained at
`assets/concepts/ui/team-drawer-options/notebook-ui-texture-atlas.png`.

Visual constraints used for generation:

- match the reference's handcrafted walnut, amber bevels, aged ivory paper,
  vermilion tabs, indigo action plate, iron rings, and metal rivets;
- use crisp front-facing pixel art suitable for nine-patch slicing;
- include no text, characters, icons, logos, or scene background.
