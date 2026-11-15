# Reviewed front-idle blink overlays

These two native-resolution RGBA overlays correct only the Founder and Theo
front-idle blink (column 1, row 0) of the 48×80 locomotion atlases.
`dev/tools/build_locomotion_assets.sh` applies them after the original measured
source export. Do not replace an entire atlas with a generated candidate.

The built-in OpenAI image tool generated the eye treatments on 2026-11-15.
The full candidates drifted outside the requested eyes and were rejected as
whole-atlas replacements. Only the registered eye regions were retained,
nearest-neighbor normalized, and remapped to each original character's existing
skin/ink palette. No alpha, silhouette, feet, other frames or animation timings
changed. Founder: 49 changed pixels. Theo: 69 changed pixels.

- [Founder generation prompt](../../../../docs/web/assets/asset-audit/prompts/founder-eyes-v1.md)
- [Theo generation prompt](../../../../docs/web/assets/asset-audit/prompts/theo-eyes-v1.md)
- [Review and native-rendered evidence](../../../../docs/web/asset-audit.md)
- `manifest.json` records the permitted rectangles and frame contract.

Original tool outputs (retained by the built-in tool, not runtime assets):
`exec-db01b8c2-6a24-4924-a2f0-47fb717d2b53.png` and
`exec-4440dd1b-931d-4f1a-8ee2-84c6863d3deb.png` in generation session
`01a1e141-b332-7001-8b53-6317a3b8a502`.
