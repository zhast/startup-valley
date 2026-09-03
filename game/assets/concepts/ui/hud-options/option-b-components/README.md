# Option B component masters

Source masters and a proof sheet for the selected **Founder's Ledger** HUD. The
reference image for every generation was
`../option-b-founders-ledger.png`. Runtime-sized, transparent, text-free copies
live at `../../../../runtime/ui/founders-ledger/`.

## Generation

Mode: built-in ImageGen, reference-image generation. Each component was generated
separately so it can be positioned, layered, and made interactive in Godot.

### Ledger HUD frame

```text
Use case: stylized-concept
Asset type: production game UI component master for Godot nine-patch slicing
Input image: Image 1 is the exact style and shape reference; reproduce only its top-center day/time/money ledger component.
Primary request: Create one isolated, text-free Founder's Ledger HUD frame: a slim horizontal warm-walnut frame containing a single ivory parchment ledger surface divided into three readable cells, with a subtle center book seam, two small dark iron binder rings, four corner rivets, lightly aged paper edges, and faint stitched/dotted separators. The cells will receive live native Godot text.
Style/medium: crisp handcrafted 2D pixel art, hard pixel clusters, cozy farming-sim readability, front-facing orthographic game UI asset.
Composition: one wide horizontal component centered with generous transparent padding; approximately 6:1 width-to-height; symmetrical and clean for nine-patch use.
Color palette: warm ivory parchment, walnut, honey edge highlights, charcoal hardware, restrained #FA4616 and #354B98 only as tiny material accents.
Text: none.
Constraints: genuinely transparent background with alpha; no checkerboard; no words, letters, numbers, icons, logos, watermark, people, scenery, shadows detached from the component, or extra assets. Preserve square pixel-art edges and a clean silhouette.
```

### Title plaque

```text
Use case: stylized-concept
Asset type: production game UI component master for Godot
Input image: Image 1 is the exact style reference; reproduce only its upper-left Startup Valley title plaque without any lettering.
Primary request: Create one isolated blank title plaque in the Founder's Ledger style: a slim horizontal warm-walnut outer frame, inset ivory parchment name surface, subtle honey-gold bevel, four tiny dark metal corner rivets, lightly worn paper and wood grain. Native Godot text will be placed in the empty center.
Style/medium: crisp handcrafted 2D pixel art, hard pixel clusters, cozy game UI, front-facing orthographic.
Composition: one centered horizontal plaque with generous transparent padding; approximately 4:1 width-to-height; balanced inner text-safe area.
Color palette: warm ivory parchment, walnut, honey highlights, charcoal hardware.
Text: none.
Constraints: genuinely transparent background with alpha; no checkerboard; no words, letters, numbers, icons, logos, watermark, people, scenery, extra tabs, or extra assets. Clean silhouette suitable for a TextureRect and nine-patch slicing.
```

### Notification memo

```text
Use case: stylized-concept
Asset type: production game UI notification component master for Godot
Input image: Image 1 is the exact style and shape reference; reproduce only its upper-left pinned job-completion memo without text or icons.
Primary request: Create one isolated blank notification memo: a warm ivory parchment card with softly irregular hand-cut edges, subtle paper mottling, a small round brass pushpin centered at the top, delicate amber edge shading, and generous empty space for a native heading, detail line, optional status icon, and text-link button.
Style/medium: crisp handcrafted 2D pixel art, hard pixel clusters, cozy game UI, front-facing orthographic.
Composition: one centered horizontal memo card with transparent padding; approximately 2.3:1 width-to-height; no wood outer frame; calm readable hierarchy implied only by blank space.
Color palette: aged ivory, pale honey, walnut-brown edge shadow, small brass pin.
Text: none.
Constraints: genuinely transparent background with alpha; no checkerboard; no words, letters, numbers, checkmarks, status icons, buttons, logos, watermark, people, scenery, tape, extra papers, or extra assets. Clean isolated silhouette.
```

### Interaction prompt

```text
Use case: stylized-concept
Asset type: production game UI interaction-prompt component master for Godot
Input image: Image 1 is the exact style and shape reference; reproduce only its small speech-ribbon interaction prompt beside Mina, without lettering.
Primary request: Create one isolated blank interaction prompt: compact warm ivory parchment speech ribbon with a short right-pointing tail, a thin walnut outline, tiny honey bevel, subtle paper grain, and enough clear center space for a native keycap and action label.
Style/medium: crisp handcrafted 2D pixel art, hard pixel clusters, cozy game UI, front-facing orthographic.
Composition: one centered horizontal bubble with generous transparent padding; approximately 2.5:1 width-to-height including the right tail; strong clean silhouette at small game scale.
Color palette: aged ivory, walnut outline, honey highlight, charcoal micro-shadow.
Text: none.
Constraints: genuinely transparent background with alpha; no checkerboard; no words, letters, numbers, keycap, icons, logos, watermark, people, scenery, extra bubbles, or extra assets.
```

### Movement plaque

```text
Use case: stylized-concept
Asset type: production game UI movement-hint component master for Godot
Input image: Image 1 is the exact style and shape reference; reproduce only its bottom-center movement label without text.
Primary request: Create one isolated blank movement-hint plaque: a narrow horizontal warm ivory parchment inset inside a slim walnut frame, four tiny dark metal corner rivets, honey-gold bevel, subtle paper and wood wear, and a wide clear text-safe center for native Godot controls text.
Style/medium: crisp handcrafted 2D pixel art, hard pixel clusters, cozy farming-sim game UI, front-facing orthographic.
Composition: one centered horizontal plaque with generous transparent padding; approximately 5:1 width-to-height; slightly slimmer and lighter than the title plaque.
Color palette: aged ivory parchment, warm walnut, honey highlights, charcoal hardware.
Text: none.
Constraints: genuinely transparent background with alpha; no checkerboard; no words, letters, numbers, icons, logos, watermark, people, scenery, extra tabs, or extra assets. Clean isolated silhouette suitable for a TextureRect and nine-patch slicing.
```
