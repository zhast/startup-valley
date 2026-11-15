# Asset audit status — November 15, 2026

The standing-eye and blink-timing repairs have passed native review; the next
art work is modest, cute furniture with coherent proportions. This page distinguishes generated pixels, runtime composition fixes
and open findings. A reviewed PNG does not prove every animation using it is
correct. See [the generation and review workflow](ASSET_WORKFLOW.md).

## Current findings and repair status

| Finding | Evidence and action | Status |
| --- | --- | --- |
| Mina's standing blink painted pale bars through her bangs while her pupils stayed open | Corrected front/left/right closed-eye regions, preserving open eyes, body, alpha and walks. [Current review](../dev/art-catalogue/runtime-reviews/mira-standing-blink-v3.json). | Native review passed |
| Founder's front closed eyes read as dark blocks | Replaced the thick closed-eye blocks with registered thin eyelids. [Current review](../dev/art-catalogue/runtime-reviews/founder-standing-blink-v3.json). Theo's existing one-pixel eyelids required no new pixels. | Native review passed |
| Blinks looked like prolonged face flicker | Replaced the 667ms/50%-duty loop with a 120ms closure every 4 seconds, offset by character. Blocked input no longer freezes Founder with closed eyes. | Native timing checks passed |
| Full visual consistency of future maps | New shared-world manifests and a map gate require matching camera, scale, material treatment, modular props and actual-engine review. Existing snapshots are explicitly not visual approvals. | Framework under validation |

## Reported furniture consistency issue

The owner reports that chairs, desks and phone booths feel inconsistently
sized/scaled. A separate furniture-quality audit is comparing the actual
Godot-rendered families beside the same reference characters, with native
scale, canvas padding, ground pivots, perspective and occupied poses recorded.
Current map visual approvals stay pending that assessment. Do not treat an
existing geometry contract as proof that these proportions look coherent.

The [native furniture audit](FURNITURE_SCALE_AUDIT.md) now confirms mixed ground
registration, inconsistent usable seat proportions, and an oversized booth
with an inadequate one-cell footprint. Its 39 fixture checks validate capture
and measurements, **not visual quality**. Corrections are in progress: the
standalone café pair/booth and the occupied office-chair family have separate
owners. The booth correction must preserve saved furniture and ownership.

## Generated art already integrated

Seven runtime PNGs contain accepted generated corrections. The newer standing
eye pass revises two of those existing character sheets; it does not replace
their identities or bodies. These are bounded overlays, not seven entirely
regenerated assets. Original generation outputs, prompts, transforms and
hash-bound reviews are retained in the repository. The final byte-stable
native eye playback passes 196 checks; the broader pose review covers all four
characters and supported facings. See [blink evidence](web/assets/blink-polish-v3/README.md).

| Original problem | Generated change | Review / visual evidence |
| --- | --- | --- |
| Side-walk legs appeared stuck | Founder lower-body walk overlay; now also corrected front eyelids | [Current combined review](../dev/art-catalogue/runtime-reviews/founder-standing-blink-v3.json), [walking frames](web/assets/playtest-polish-founder-walk.png) |
| Same side-walk issue | Mina lower-body walk overlay; now also corrected standing eyelids | [Current combined review](../dev/art-catalogue/runtime-reviews/mira-standing-blink-v3.json), [walking frames](web/assets/playtest-polish-Mina-walk.png) |
| Same side-walk issue | Theo lower-body walk overlay | [Review](../dev/art-catalogue/runtime-reviews/theo-side-walk-v2.json), [rendered frames](web/assets/playtest-polish-theo-contact.png) |
| Same side-walk issue | Creative lower-body walk overlay | [Review](../dev/art-catalogue/runtime-reviews/creative-side-walk-v2.json), [rendered frames](web/assets/playtest-polish-creative-contact.png) |
| Pale marks through Mina's seated bangs | Seated closed-eye overlay; 86 changed pixels | [Review](../dev/art-catalogue/runtime-reviews/mira-seated-blink-v2.json), [rendered frames](web/assets/playtest-polish-Mina-blink.png). Standing eyes and timing now have their own verified repair above. |
| Coffee machine front was hard to recognize | South-facing espresso panel; recomposed panel and whole-machine PNGs | [Review](../dev/art-catalogue/runtime-reviews/coffee-south-front-v2.json), [native detail](web/assets/coffee-front-review/south-front-detail.png). Other facings were not regenerated. |

![Regenerated walking frames](web/assets/playtest-polish-founder-walk.png)

![Coffee front in the actual room](web/assets/coffee-front-review/south-front-detail.png)

## Fixed through code or placement

| Finding | Change |
| --- | --- |
| Chair back disappeared behind north-facing seated characters | Facing-specific lower-body/chair/head depth composition. [Decision and evidence](decisions/2026-11-15-seated-chair-depth.md). |
| Creative used the wrong portrait | Correct character crop/selection; no new generated PNG. |
| Mina arrival could overlap furniture | Navigation and painted-bounds placement checks, deterministic clear-floor search, and a safe portrait-introduction fallback. |
| Theo hover paper covered his name/face | Derive callout bounds from the actual rendered target, protect the actor/nameplate and other world UI; 57 native regression checks passed. |
| Cursor lifecycle and stale hover feedback | Clear native cursor ownership and hover state at the relevant transitions; no generated cursor artwork in this change. |

The frozen inventory contains 804 legacy runtime PNGs. That count is **not**
804 artistic approvals. Defects can still exist in unchanged legacy images.
Keep this list current when a reported issue is reproduced, repaired and
verified, and retain the evidence for the exact accepted scope.
