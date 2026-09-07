# Engineering and finance portrait concepts

2026-09-04 09:43 UTC. Two original, intentionally opaque portrait plates;
one initial built-in ImageGen request each. No retries, alpha extraction,
roster changes, hiring logic, worker calls or production UI changes.

## Native result

Both portraits fit the same 64×80 opening used in the earlier specialist
study. Engineering has a clear black-hair/glasses/indigo-jacket identity;
finance has a wavy dark bob, cerulean cardigan and small warm collar accent.
The background is calm parchment. Neither has cropped hair, a painted
checkerboard, a stray frame or baked text. The engineer's face is narrower
than the earlier legal portrait; the finance portrait's facial shading is
quieter at native size. These are distinct identities, not interchangeable
recolors. No corrective retry is justified by the present native evidence.

Root inspected the original outputs, a nearest 4× pair and the full native
1280×720 notebook comparison. The new faces are readable alongside the
earlier legal-B and creative-B crops. All four are concepts; the current rail
opening still requires its separately documented sizing decision before use.

- [Actual notebook comparison](../../game/tests/output/additional-portraits-v1/four-specialists-native.png)
- [Engineering native card](../../game/tests/output/additional-portraits-v1/engineer-card-native.png)
- [Finance native card](../../game/tests/output/additional-portraits-v1/finance-card-native.png)
- [Nearest 4× source pair](../../game/tests/fixtures/character-concepts/additional-v1/pair-4x.png)

## Sources and reproducibility

| Role | Preserved source / adjacent original prompt | Native plate | Palette |
|---|---|---|---:|
| Engineer | [Master](../../game/assets/source/overnight-20260904/characters/engineer-portrait-v1.png), [prompt](../../game/assets/source/overnight-20260904/characters/engineer-portrait-v1.md) | [64×80](../../game/tests/fixtures/character-concepts/additional-v1/engineer-portrait-v1.png) | 31 colors |
| Finance | [Master](../../game/assets/source/overnight-20260904/characters/finance-portrait-v1.png), [prompt](../../game/assets/source/overnight-20260904/characters/finance-portrait-v1.md) | [64×80](../../game/tests/fixtures/character-concepts/additional-v1/finance-portrait-v1.png) | 30 colors |

Originals are 1122×1402 RGB. The [builder](../tools/build_additional_portraits.sh)
uses uniform nearest fitting to 64×80, an undithered ≤32-color palette and no
crop, independent-axis stretch, mask or semantic paint. All six native/pair/4×
outputs reproduced byte-identically in a second execution. Masters are retained.

The [dev capture](../../game/tools/capture_additional_portraits.gd) reuses the
existing real notebook material component over an actual TownRoom, not a
bitmap UI mockup. Its four local card slots are presentation only: it does
not instantiate GameMain or register additional EmployeeRecords. The existing
portrait-study source and its earlier output directories are unchanged.

Headless **47 checks / zero failures**; rendered **57 / zero failures**.
All 5,120 pixels of each of the four native plates match the screenshot exactly;
frames enclose them without scaling or clipping. Label/font fit, opaque alpha,
palette limits and native 1280×720 output are checked. Five PNG captures and
source/native hashes are listed in the [manifest](../../game/tests/output/additional-portraits-v1/manifest.json).

This is a bounded visual review, not runtime approval or proof of character
animation. Standing/walking/seated/tool poses, expressions, availability icons,
and any actual specialist capability remain future work.

```sh
bash dev/tools/build_additional_portraits.sh
STARTUP_VALLEY_NO_WORKER=1 godot --headless --path game --script res://tools/capture_additional_portraits.gd
STARTUP_VALLEY_NO_WORKER=1 godot --path game --fixed-fps 30 --script res://tools/capture_additional_portraits.gd
```
