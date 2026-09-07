# Terrazzo V4 — bounded bright-office candidate

2026-09-04 11:29 UTC. **Staged optional material; production wood unchanged.**
V4 is materially calmer than V3 at native size. Its short sparse chips remove the
long scratched/stitch-like chains, and no obvious pale border moat or hard tile
grid appears in the empty or mature room. Repeated pairs remain detectable on
inspection; this is not a claim of an infinitely nonrepeating floor.

This is original118, **the third and final targeted retry** of the existing
terrazzo series. Its initial-plus-three allowance is exhausted. This review made
no image/provider calls, further export corrections or production changes.

## Nine actual-room comparisons

All nine1280×720 images were inspected individually at native size, plus the
V4 native room repeat crop and nearest4× tile. Same frozen physical actors,
layout, camera and UI; only the disposable instance's floor texture changes.

| Scene | Default wood | Frozen V3 unified | V4 unified candidate |
|---|---|---|---|
| Founder-only | [Native](../../game/tests/output/terrazzo-v4-review/baseline-hires-0-office.png) | [Native](../../game/tests/output/terrazzo-v4-review/terrazzo-v3-unified-hires-0-office.png) | [Native](../../game/tests/output/terrazzo-v4-review/terrazzo-v4-unified-hires-0-office.png) |
| Mature office | [Native](../../game/tests/output/terrazzo-v4-review/baseline-hires-4-office.png) | [Native](../../game/tests/output/terrazzo-v4-review/terrazzo-v3-unified-hires-4-office.png) | [Native](../../game/tests/output/terrazzo-v4-review/terrazzo-v4-unified-hires-4-office.png) |
| Mature Chat | [Native](../../game/tests/output/terrazzo-v4-review/baseline-hires-4-chat.png) | [Native](../../game/tests/output/terrazzo-v4-review/terrazzo-v3-unified-hires-4-chat.png) | [Native](../../game/tests/output/terrazzo-v4-review/terrazzo-v4-unified-hires-4-chat.png) |

### Observations

- **Improved repeat, bounded pass:** empty V4 floor at`x384–768,y192–448`
  has sparse short chips instead of V3's dense directional chains. The128px
  repetition still exists, but does not announce a broad rectangular border.
  This conclusion comes from native room/crop review, not0/0edge metrics alone.
- **Material identity, polish limit:** some chips are1px dots or2–3px stepped
  marks. At4× their small recurring shapes are clear; at1× they read as subtle
  speckles rather than rich stone fragments. Keep the restrained optional-theme
  interpretation, not a detailed photoreal terrazzo claim.
- **Room character, subjective choice:** V4 is brighter and cleaner, but wood's
  plank rhythm better reinforces the existing cozy workshop theme. Furniture
  has stronger dark separation against V4; the large central space also feels
  more blank. Nothing in this comparison warrants replacing the default.
- **Actors, bounded pass with retained limit:** founder`x548–575,y558–626`,
  Mina`x356–381,y526–592` and Theo`x740–766,y526–592` remain readable. Dark
  outlines separate well, while cream/white footwear is closer to the light
  floor value. Existing outlines/shadows help in these fixed idle poses; this
  static review is not new walking/seated-shadow acceptance.
- **UI, pass:** Chat paper at`x820–1100,y210–560` retains its warm field and
  wooden boundary against the lighter room. Tested opaque Chat/HUD/rail regions
  are byte-identical across floor variants. No typography, portrait or control
  recoloring is needed for this candidate. No new visual clipping was observed.

Material rubric (direction consistency becomes **repeat consistency**):

| Category | Score | Reason |
|---|---:|---|
| Pixel coherence | 2 | Native compact chips; deliberately simple speckled material. |
| Perspective | 3 | Flat screen-axis plane without baked horizon or lighting plane. |
| Actor/material readability | 2 | Clear dark contours; pale footwear remains the limit. |
| Native registration/layers | 3 | Exact1× samples and opaque UI preservation. |
| Repeat consistency | 2 | No obvious moat/grid at1×; repeated motifs still detectable. |
| Placement | 3 | Only validated floor cells change; architecture/navigation fixed. |

Mean **2.5**, local bounded staged review, **not runtime admission**. The earlier
V3 repeat failure remains true and is not overwritten by this result. Parent/user
theme selection and any future dynamic review are separate acceptance decisions.

## Source and normalization facts

The [source/export review](TERRAZZO_V4_SOURCE_REVIEW.md) contains the frozen
normalization proof and exact derivative inventory. Source is1254×1254 opaqueRGB,
SHA256`9527d36fd99e864e14cba0589b4b3bb74e5c836094b96d59a01f80cb07de5953`.
The builder uniformly point-resizes the full source to128×128, then uses the
existing12-color budget (11actual), existing global material palette (8actual),
and separate global`#E3DCCF → #EAE4D7` merge (7actual).

The merge changes14,813 base pixels and no other pixels. No edge-only painting,
source crop, stitched border or runtime scale is involved. Raw/normalized/unified
files are all preserved; the room uses only the explicitly named unified file:

`res://tests/fixtures/material-concepts/terrazzo-v4/cream-terrazzo-floor-v4-unified-base.png`

Its SHA256 is
`ed48b4cd1a1605e80a28d42f75a92e3059bb5abfeb37b162f1800d7469a865fc`.

| Native file | Colors | Opposite-edge mismatch X/Y | Top8 nonbase | Interior112×112 nonbase |
|---|---:|---:|---:|---:|
| V3 unified |7|0/0|5.9570%|11.4716%|
| V4 unified |7|0/0|2.7344%|2.7663%|

V4 has449 nonbase pixels overall (2.7405%). These are descriptive density
measurements, not visual acceptance thresholds. Both versions satisfy exact
edge matching even though their in-room repeat quality differs substantially.

## Verification and limits

- New [capture helper](../../game/tools/capture_terrazzo_v4_review.gd) and
  [test entry](../../game/tests/test_terrazzo_v4_review.gd) only. Existing floor
  helpers, all previous reports/images and production files are unchanged.
- **53 headless checks /0 failures**; **112 native checks /0 failures**,
  1,843,017 pixel comparisons; nine states and15PNGs (nine native rooms,
  three native repeat crops, three nearest half-size overview sheets).
- All three imports are opaque128×128 and decoded RGBA matches the native file.
  Lossless import, no mipmaps,1×nearest architecture; sampled actual floor across
  32px cells and128px repeats matches the tile. No black pinholes or alpha issue.
- Physical actor positions, layout, navigation, placements and prop count remain
  identical. Nonfloor architecture and sampled opaque UI ink/paper compare
  exactly with each same-state wood baseline. Source/default hashes are checked
  before/after, and each instance restores its default floor before teardown.
- Worker is replaced with the existing null transport before GameMain enters the
  tree. No process, pipe, personal save, actual credential or provider is used.
  Credential-ready is only the inherited fixture's local UI projection for Chat.
- Stage4 means mature props with the two supported employees, not new specialist
  hiring. **No movie, real input, motion, fullscreen or universal gameplay claim**
  follows from this intentionally bounded static comparison.

[Manifest](../../game/tests/output/terrazzo-v4-review/manifest.json),
[headless result](../../game/tests/output/terrazzo-v4-review/results-headless.json),
[native room repeat](../../game/tests/output/terrazzo-v4-review/terrazzo-v4-unified-repeat-native.png),
[4× tile](../../game/tests/fixtures/material-concepts/terrazzo-v4/cream-terrazzo-floor-v4-unified-base-4x.png).

```sh
godot --headless --path game --fixed-fps 30 --script res://tests/test_terrazzo_v4_review.gd
godot --path game --fixed-fps 30 --script res://tests/test_terrazzo_v4_review.gd
```

Recommendation: keep V4 as the reviewed optional bright-theme candidate and keep
wood in production. Do not begin another terrazzo generation or reset this
series' exhausted retry allowance. No catalogue or default-floor change was made.
