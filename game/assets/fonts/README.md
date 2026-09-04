# Bundled UI typography

Runtime fonts are local and deterministic. Approved direction C is implemented
by `game/ui/game_fonts.gd` and `cozy_ui.gd`, without preview overrides:

- Not Jam Slab Serif11 at native22: controlled display headings and HUD values.
- Nunito Sans550 at16: prose/inputs; at18: document reading.
- Nunito Sans600 at14: secondary metadata; at16: popup menus.
- Nunito Sans700 at20: section headings and financial summaries; at16: actions,
  tabs and employee identity labels.
- Genuine Nunito italic550 and bold italic700 masters for rich emphasis.
- JetBrains Mono450 at16: source and code.

Slab has no antialiasing, hinting, mipmaps or subpixel positioning. Nunito stays
antialiased; world art stays nearest filtered. Font families never change to
fit a width. Controlled Slab headings with unsupported characters deliberately
use Nunito as a whole label; paths always use Nunito rather than Slab.

The unchanged Slab font and CC0 license come from the creator's
[Not Jam font pack](https://not-jam.itch.io/not-jam-font-pack). Nunito and
JetBrains retain their adjacent OFL licenses. Nunito variable wrappers use the
supported `weight` axis rather than synthetic bolding.

## Bundled dynamic-text coverage

Nunito/Mono include local Noto Sans, CJK, Symbols2 and monochrome Emoji fallbacks.
Original names, paths and document text are never rewritten to ASCII escapes.
All fonts disable operating-system fallback. This covers the tested accented
Latin, Greek/Cyrillic, Japanese, Simplified/Traditional Chinese, Hangul, arrow
and emoji cases; it is not a claim of complete Unicode or localized UI support.

Godot's Label minimum size includes the largest unused fallback metrics.
`GameFonts._static_init()` aligns fallback ascent/descent at UI sizes14–24 to
Nunito's line boxes without scaling glyph outlines or changing advances. Tests
verify mixed-script rendered bounds as well as normal Latin spacing.

Unmodified sources fetched2026-09-03, licenses beside their font files:

- [Noto CJK Sans Regular](https://github.com/notofonts/noto-cjk/tree/main/Sans/OTF/SimplifiedChinese)
- [Noto Sans](https://github.com/google/fonts/tree/main/ofl/notosans)
- [Noto Symbols2](https://github.com/google/fonts/tree/main/ofl/notosanssymbols2)
- [Noto Emoji](https://github.com/google/fonts/tree/main/ofl/notoemoji)

## Retained Whop experiment provenance

These files are preserved for historical comparison, not selected production
roles:

- Acid Grotesk Medium500: brand, screen and employee headings at24–28px.
- Inter Regular400: prose and inputs at16–18px.
- Inter Medium500: secondary metadata at14px and menus at16px.
- Inter Semibold600: actions/rail/tabs at16–18px and all HUD values at24px.
- Actual Inter Italic and Semibold Italic: rich-text emphasis, without synthetic slant.
- JetBrains Mono450: source code only.

The shared role wrappers use static Whop OTFs, with no synthetic weight or
variable-axis dependence. They enable antialiasing and disable system fallback;
world textures retain nearest filtering. Acid uses its default double-storey
a/g and high ascenders. See `acid-grotesk/PERMISSION.md` for the owner's explicit
Whop authorization, and `inter/OFL.txt` for Inter's license.

Source: [Whop brand guide](https://brand.whop.com/), typeface archive fetched
2026-09-03. Archive SHA256:
`576a1520cd3b28c18f9102373a4a4ad6b094d724345cf1bd996b443524a2f297`.

Unmodified historical file SHA256 values:

| File | SHA256 |
| --- | --- |
| FFF-AcidGrotesk-Medium.otf | f8c2d965a3bf01db447348f99430d15736ad9351e312c8839ef7e06c319f422b |
| Inter-Regular.otf | d4f2b9e148059a15f014cb0f0b8fea8cd11bfa447dd483bedf1b0adc0e2ba799 |
| Inter-Medium.otf | 6c222ed2c3660524dd0c14fb745e00fee65c5361ab28f60fba6730bf4e648763 |
| Inter-SemiBold.otf | 0a4d30778fa2dc239368d90fd854b88b27e7ede737450da72686a90eca66f02c |
| Inter-Italic.otf | 3bdf49f72ad2f2959a2619ceef700784504f6d17f502e2e2bc6edce5d43ca631 |
| Inter-SemiBoldItalic.otf | a350102650a86612efa66e0291315dba24be43e1f3716359c17d365376bea11e |

## Retained historical fonts

Tiny5 remains for historical comparisons only. Nunito's wrappers and real
italic master are now selected production roles again.

Additional source files fetched 2026-09-03 from the Google Fonts OFL collection:

- [Nunito Sans](https://github.com/google/fonts/tree/main/ofl/nunitosans):
  `NunitoSans-Italic[YTLC,opsz,wdth,wght].ttf`, SHA256
  `d9d5db18f3c11221a4fbb553cbc709391c1179964c7eaa4466ef43c78aa4492f`.
- [JetBrains Mono](https://github.com/google/fonts/tree/main/ofl/jetbrainsmono):
  `JetBrainsMono[wght].ttf`, SHA256
  `48715a42ec242c21e9f02692891e147d022299a52e48d5e413e1a942193ffeda`.

All historical licenses remain alongside their fonts.
