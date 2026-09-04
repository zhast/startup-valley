# Typography decision previews

Developer-only comparison assets. `capture_typography_options.gd` applies local
overrides to disposable `GameMain` instances with the worker disabled. C has
since been integrated separately into production `GameFonts`, with its Slab
font/license copied unchanged into `assets/fonts/not-jam-slab/`. The historical
preview notes below describe the decision stage, not current runtime status.
See [production acceptance](../../../dev/TYPOGRAPHY_C_AUDIT.md).

The Not Jam faces come from the creator's [font pack](https://not-jam.itch.io/not-jam-font-pack)
and are redistributed under the included CC0 license. The originals are
unchanged. Acquisition date: 2026-09-03.

- Not Jam Slab Serif 11: 22 px headings and HUD values.
- Not Jam Serif 11: 22 px reading text in the serif preview.
- Not Jam Chunky Sans 8: 24 px headings, 16 px HUD and rail labels in B.
- Not Jam UI Condensed 16: 16 px compact labels; also B's reading text.
- Not Jam Mono Clean 8: 16 px monospace role (no code in these chat samples).

Pixel faces use no antialiasing, hinting, mipmaps, subpixel placement, or system
fallback. Sizes are integer multiples of their native design grid, following
the creator's [Godot guidance](https://not-jam.itch.io/not-jam-font-pack/devlog/749049/pixel-fonts-a-godot-tutorial).
The hybrid preview uses the existing bundled Nunito Sans for prose and small
labels. This is a design comparison, not acceptance of new production fonts.

Run with the normal renderer (not headless):

```sh
godot --path game --resolution 1280x720 --fixed-fps 30 --script res://tools/capture_typography_options.gd
```

Outputs: `game/tests/output/typography-options/`.

The primary A/B/C captures contain the same 32-word reply. The `-long-`
captures use the same 81-word reply and keep the transcript at the top.
The 496×800 UI composites contain native-size HUD and sidebar crops, not a
scaled-down full screenshot. Full 1280×720 captures are also retained.

First-render corrections remain fixture-only: B's chunky face clipped narrow
tabs and the Ask button, so compact controls use UI Condensed 16 and all three
HUD values use Chunky 16. Pixel candidates lack ellipsis/em-dash glyphs, so all
three fixtures use identical ASCII punctuation in the helper and placeholder.
Character nameplates are hidden in all options because their direct canvas
drawing bypasses Control font overrides. This comparison covers HUD, rail,
employee header, controls, and conversation text—not the whole typography audit.

Final check: all three options passed 46 sampled layout/glyph/baseline checks.
The long transcript scrolls in A and C; B's condensed body fits more content.
Production integration still needs full Unicode/fallback and all-screen testing.

## Selected direction: C

The user selected C, then flagged the HUD captions bleeding into the bevel.
The original check missed this because Nunito's 14px captions expanded their
20px Label to 23px at y39. The visible Day descender reached y57, beyond the
paper's y55 edge.

The corrected C preview puts captions above values: captions y8/h20 and values
y29/h22, with single-line spacing set to zero. Fonts and the native ledger art
are unchanged. A raster comparison against the blank ledger now verifies that
new text ink stays within the three explicit safe paper cells. Both short- and
long-chat C captures pass with zero pixels outside; the lowest ink is y46.
These remain disposable preview overrides, not a production-wide font switch.
