# Customer-support portrait concept

Reviewed 2026-09-04 10:14 UTC. **Staged portrait, not a new employee.**

The initial original is intentionally opaque, 1122×1402 RGB, with a clear
headset, glasses and warm ochre cardigan. Uniform nearest export produces a
64×80 plate with 32 colors. No cutout, fake transparency, semantic repaint or
runtime downscaling was used. The source and exact prompt are retained at
`game/assets/source/overnight-20260904/characters/customer-support-portrait-v1.*`.

Root inspected the generated original, nearest 4× native plate and the full
1280×720 notebook composition. The face, glasses and headset remain readable;
the new portrait fits its existing frame without clipped hair, microphone or
shoulders beyond the intentionally cropped chest. The longer Customer support
label fits its native nameplate. Engineering and support share short-hair/
glasses vocabulary, but their outfit, silhouette and headset remain distinct.

The isolated comparison reuses the actual notebook review component and shows
Creative, Engineer, Finance and Customer support at exact 1×. The existing
legal/creative/engineering/finance comparison output is not overwritten.

- 47 headless / 57 rendered checks, zero failures.
- Five native PNGs; every rendered 64×80 plate matches its source bytes.
- Both support export files rebuild byte-identically. Native SHA-256:
  `0258a97851b2369626db8d39406da4b541eb1f470f621bba003ba13b2af3377b`.
- No GameMain/worker/bootstrap/save, new world pose, hiring record, capability,
  live team-rail update or production portrait registration.

[Native notebook comparison](../../game/tests/output/customer-support-portrait-v1/four-specialists-native.png)
· [native portrait](../../game/tests/fixtures/character-concepts/customer-support-v1/portrait.png)
· [source/prompt](../../game/assets/source/overnight-20260904/characters/customer-support-portrait-v1.md)
· [manifest](../../game/tests/output/customer-support-portrait-v1/manifest.json).

```sh
bash dev/tools/build_customer_support_portrait.sh
STARTUP_VALLEY_NO_WORKER=1 godot --path game \
  --script res://tools/capture_additional_portraits.gd -- \
  --portrait-study=customer-support
```

The current live rail's different 66×74 opening and missing full-body/world
animation remain explicit future integration requirements. No retry is justified
by the bounded native portrait review alone.
