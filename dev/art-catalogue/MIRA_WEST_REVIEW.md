# Mina west seated/typing — staged native review

Reviewed 2026-09-04 06:19 UTC. **Native calibration candidate only; not runtime approved or registered.** No ImageGen request remains in flight. Production code and north/east source or fixture assets were not changed.

## Generation and provenance

The imagegen skill's built-in workflow supplied one original atlas and one targeted alpha-extraction edit. There was no CLI/API fallback, mirrored raster, manual pose painting, worker call, save change, commit or push. One permitted targeted retry remains unused because a usable native candidate was obtained.

References were inspected before prompting: row 2 (zero-based) of `game/assets/runtime/characters/mira-locomotion.png` for the existing west/left profile; `game/assets/source/polish/mira-seated-master.png` for Mina's identity; and `game/assets/source/overnight-20260904/characters/mira-east-v3.png` for the accepted-as-candidate upright torso, compact forearms and bent seated legs. The west figures are newly generated left-facing drawings, not a bitmap flip of the east art or its light.

| Attempt | Source under `game/assets/source/overnight-20260904/characters/` | Actual output | Disposition |
| --- | --- | --- | --- |
| v1 | `mira-west-v1.png` | 2172×724 RGB, opaque painted checkerboard | Pose reference only; alpha rejected |
| v2 | `mira-west-v2.png` | 2172×724 RGBA, genuine alpha | Staged native source |

Prompts: `dev/art-catalogue/prompts/mira-west-v1.md` and `mira-west-v2.md`.

Original built-in results remain under `/Users/zhast/.codex/generated_images/01a069ca-1fee-7e63-af23-27e16b028df6/` as `exec-067dbf91-2834-46ac-b1a0-4a9e5392b196.png` and `exec-6acd5365-c055-4af8-8349-d20bfbbc19b3.png`. The project copies above are the durable deliverables.

## Export and evidence

Run `bash dev/tools/build_mira_west_calibration.sh`. This follows the existing seated exporter: one shared vertical crop y116/height532, point normalization to 68px body height, shared 48-color palette, binary alpha and integer head registration. Measured contiguous source alpha bands are `(40,253),(398,253),(765,252),(1133,255),(1491,255),(1847,253)` as x,width. Equal source-width cells are not presumed. Head registration shifts are −3px for frames 0–4 and −4px for frame 5; no limb pixels are repainted or rescaled independently.

Evidence in `game/tests/fixtures/furniture-calibration/characters/`:

- `mira-west-seated-v2.png`: native 288×80 atlas, six 48×80 cells, 2 idle followed by 4 typing frames.
- `mira-west-seated-v2-4x.png`: exact 1152×320 nearest enlargement; all six frames inspected.
- `mira-west-seated-v2-paper-4x.png`: diagnostic-only pale underlay, used to expose stray islands and matte fringes; not an export for runtime use.
- `mira-west-frame0-8x.png` and `mira-west-frame1-8x.png`: exact single-frame nearest enlargements for anatomy and second-idle forearm inspection.

Final native SHA-256: `c71d136b7468df7dde0d5d9ef87d073471a8a1a4a975dcc9e25ca6cc4fc2c14f`.

The native atlas has 46 colors including transparency, 6,658 fully opaque pixels and 16,382 fully transparent pixels; no intermediate alpha values. All six pixel hashes differ. No sprite touches a cell edge: every frame retains at least 4px left/top, 11px right and 8px bottom transparent padding.

| Frames (zero-based) | Opaque bounds x,y,width,height | Head-region bounds x,y,width,height |
| --- | --- | --- |
| 0 | 5,4,32,68 | 13,4,22,24 |
| 1–2 | 5,4,32,68 | 14,4,21,24 |
| 3–4 | 4,4,33,68 | 13,4,22,24 |
| 5 | 4,4,32,68 | 13,4,22,24 |

The integer head-registration center is x24 for every frame. Odd-width head silhouettes in frames 1–2 produce a half-pixel geometric center difference; that and small hair/face variations must be checked in motion. Top opaque row y4 and last opaque row y71 are fixed.

## Landmarks for west socket calibration

Coordinates are individual native-cell pixels. Bounds above are measured; anatomical landmarks below are visual estimates from native/8× evidence with about ±1px uncertainty.

| Landmark | Native coordinate/region | Interpretation |
| --- | --- | --- |
| Head registration | x24, top y4 | Same inherited head reference as east/north |
| Shoulder | approximately (26,35) | Upper cardigan below neck |
| Near elbow | approximately (27,47) | Bent beside torso, not a standing hanging arm |
| Hand contact band | x10–21, y43–49; neutral near (16,47) | Leftward compact forearms, small typing alternation |
| Hip/seat center | approximately (25,53) | Rear end of left-projecting thigh |
| Seat support underside | x16–28 near y55 | Chair supports the hips/thigh, not the shoe origin |
| Knee bend | approximately (11,54) | Forward-left thigh ends above vertical lower leg |
| Ankle | approximately (11,66) | Above the left-pointing shoe |
| Shoe ground contact | x4–15, final opaque row y71 | Feet naturally project left of hips |
| Export pivot | (24,72) | Cell convention; **not the literal center of the visible shoes** |

As with east, an explicit chair socket/render offset is required. Do not shift the shoes to the center of the cell or change navigation feet to manufacture apparent calibration.

## Visual disposition and remaining acceptance

- The left profile keeps Mina's high bun/gold tie, long dark hair, olive cardigan, cream trousers and brown shoes. No desk, chair, tool, floor or shadow is baked into the export.
- Upright torso, horizontal thigh and bent knee/vertical lower leg read as seated; there is no stretched standing-foot silhouette.
- The large transparent source has colored edge speckles. The shared native point/palette/binary-alpha normalization yields no visible red/green fringe on the inspected pale underlay. Keep the master for any subsequent targeted correction rather than painting over pixels.
- A small orange/brown detail in v1's second idle near the forearm/chest was inspected at native and 8×. At native it reads as the far hand/arm edge, not a distinct held prop; it has not been manually removed. If motion makes this flicker, request an explicit ImageGen pose cleanup.
- Light remains concentrated on upper-left hair and skin; west is not a horizontal reversal of east highlights. Small inter-frame hair/face changes remain and are not equivalent to authored smooth motion.

Provisional scores: pixel coherence 2, projection 3, silhouette/readability 3, atlas anchors 2, within-atlas direction consistency 3. **Placement/layering is unscored** until the actual west chair/desk composite is inspected. No overall runtime acceptance mean or compatibility claim is made.

Next: review the six frames at native scale against the west workstation and chair, checking hand contact, seat underside support, idle→typing→standing, limb occlusion and loop seam. Only register a west pose set after that review passes. The bounded task ends at this staged candidate; unused retries are not spent speculatively.
