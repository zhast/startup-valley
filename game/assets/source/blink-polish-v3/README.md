# Standing blink corrections

The runtime remains a 288×320 atlas of 48×80 cells. The correction changes
Mina's front/left/right closed-eye cells and Founder's front closed-eye cell.
All open cells, walk frames, back views, alpha and feet remain unchanged.

Both treatments used the built-in OpenAI ImageGen tool, with the canonical
`startup-valley-cozy-pixel-v1` board attached. Exact requests are `prompt.txt`
(Mina) and `founder-theo-prompt.txt` (paired reference). Raw outputs are retained.

| Output | Generation session / artifact | Retained scope |
| --- | --- | --- |
| generated-blinks.png | 01a1e146-9490-71d0-99d4-d5691e91d349 / exec-a03f0622-032b-4eb7-b9d4-0fa59799c3fe.png | Four small eyelid/skin patches; Mina's original open-cell bangs restore the erroneous forehead bars. |
| generated-founder-theo.png | 01a1e146-9490-71d0-99d4-d5691e91d349 / exec-419d6b6c-9e84-4f39-9f84-5bedd7517b48.png | Two Founder eye patches only. Theo was generated for comparison but rejected as unnecessary: his existing lid is already one dark row. |

`game/tools/build_standing_blinks.gd` records exact source crop coordinates,
nearest sampling, original-palette mapping and alpha preservation. Run it
headlessly for candidates or with `-- --apply` for runtime outputs. It also
rebuilds the tiny transparent overlays. `dev/tools/build_locomotion_assets.sh`
applies them after the previously reviewed gait corrections.

The entire generated characters were rejected; they are not replacement bodies.
The `*-before.png` files preserve the accepted gait/base state for reproducible
comparison. Earlier source history remains in the archived side-walk reviews.

Separate code correction: `IdleBlink` selects the closed cell for120ms every4s,
with stable per-person phase offsets. The old two-cell1.5fps loop held the eyes
closed for667ms every1.33s. This timing fix is not image generation.

See `docs/web/assets/blink-polish-v3/README.md` for native evidence and limits.
