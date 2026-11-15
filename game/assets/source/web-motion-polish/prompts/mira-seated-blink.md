# Mina seated blink — built-in ImageGen

Generated 2026-11-15 with the built-in OpenAI image tool. Input: the original
48×80 cell at column 1 of `runtime/characters/mira-seated.png`.

Prompt:

> Use case: precise-object-edit. Edit target: attached single48×80pixel Mina seated game sprite. Correct ONLY her blink eyes and erroneous pale stripes through her bangs. She should gently close BOTH eyes: two short dark brown curved/straight eyelid strokes at the current pupil heights, with warm skin where the open eyes were. Remove the pale horizontal marks ABOVE her eyes so those pixels become the original dark brown bangs, no stripes or eyebrows through hair. Preserve exact hair silhouette,bun,face shape,neck,greenjacket,whitepants,seatedpose,shoes,allbodypixels and transparent background. Crisp matching pixelart and existing palette. Same exact registration and proportions. Output same48×80canvas or an exactinteger enlargement,no cropping,padding,text,extra characters. Eyes must be visibly CLOSED, calm natural blink not glasses or Xeyes.

Generation session: `01a1e146-9490-71d0-99d4-d5691e91d349`.
Generated artifact: `exec-87efb840-d6e8-4cc3-bcae-35ec9eac5096.png` (971×1619).
The whole generated character was rejected: only the registered eyelid treatment
was retained. Source pixels were point-sampled to the 48×80 grid, moved one pixel
up to the existing eye line, and mapped to the original seated palette. The
erroneous 28 hair pixels were restored from the identical open-idle cell.

The accepted native-resolution source is `../mira-seated-blink-overlay.png`.
`dev/tools/build_workstation_assets.sh` reapplies it after the original export.
