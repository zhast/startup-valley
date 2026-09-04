# Acid Grotesk provenance

Source: the typeface download linked by [Whop's official brand guide](https://brand.whop.com/), retrieved 2026-09-03.

The project owner confirmed they work for Whop and have permission to use these
fonts for Startup Valley. This records that project-specific authorization; it
does not relicense Acid Grotesk as open source or grant third parties font rights.

Only the unmodified static `FFF-AcidGrotesk-Medium.otf` is bundled. The archive's
trial-named variable font is not used. No font outlines have been modified.

Whop specifies double-storey **a** and **g**, and high ascenders. Inspection of
the supplied static font's OpenType feature labels confirms those are its
defaults. The display wrapper explicitly disables `ss01` (single-storey a),
`ss02`/`ss03` (neogrotesk g), and `ss12` (low ascenders), using numeric OpenType
tags so Godot's friendly-name aliases cannot change their interpretation.

SHA256: `f8c2d965a3bf01db447348f99430d15736ad9351e312c8839ef7e06c319f422b`.
