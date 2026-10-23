---
name: verify-startup-valley
description: Drive the Startup Valley Godot game through a headless SubViewport and save PNG proof of the real Company Journey buttons. Use when a tycoon or journey change needs a player-level check with the real worker, or when a flow needs screenshot evidence.
---

# Verify Startup Valley

The Godot game presents `journey.tycoon`. The harness in `harness/` is authoritative. This skill boots `game/world/main.tscn` inside a SubViewport, clicks the real buttons, and writes PNGs. It does not call a model, the network, or a credential.

Rules and prices live in `docs/TYCOON_DESIGN.md`. Player steps live in `features/` beside this file. Do not restate them here.

## Launch

Godot 4.7.2 is `/home/box/.local/bin/godot` (`godot` on PATH). Node 22 is `/home/box/.local/node22/bin`. `res://` is rooted at `game/`, so a script outside `game/` is passed as an absolute `--script` path. `--path game` still loads the project, and `preload("res://...")` resolves.

From the repo root, after the harness build in Doctor:

```bash
export PATH=/home/box/.local/node22/bin:/home/box/.local/bin:$PATH
export STARTUP_VALLEY_IGNORE_HOST_CREDENTIALS=1
SV_PROOF_DIR=/workspace/sv-proof/round-32 \
  xvfb-run -a -s "-screen 0 1280x720x24" \
  godot --path game --script /workspace/startup-valley/.cursor/skills/verify-startup-valley/capture_journey.gd
```

Do not add `--headless`. The SubViewport texture is blank without a display. `xvfb-run` is that display. Do not use `res://../.cursor/...`.

If Godot rejects the absolute script, copy the helper to `/tmp/capture_journey.gd` and pass that path. Delete the copy when the run finishes. Do not leave a copy under `game/`.

## Doctor

- `cd harness && npm run build` so `harness/dist/main.js` exists. The game refuses to boot without it.
- `godot --version` prints 4.7.2. `node --version` prints v22.
- `xvfb-run` is installed.
- `STARTUP_VALLEY_IGNORE_HOST_CREDENTIALS=1` is set. Unset `STARTUP_VALLEY_NO_WORKER` and `STARTUP_VALLEY_FAKE_PROVIDER`.
- `STARTUP_VALLEY_DATA_DIR` is a fresh directory. The helper sets one under the temp dir when it is unset. Do not point it at a real save.
- `SV_PROOF_DIR` is set. The helper exits with `PROOF FAIL` when it is empty.

## Drive

`capture_journey.gd` is a `SceneTree` script. It instances `main.tscn` in a 1280×720 SubViewport, sets the day clock speed to 0, and pushes mouse and key events at the live controls.

The run ships Crypto Alpha Newsletter, trains Founder Tech, ends the day, researches Sneakers, starts Sneakers Newsletter, ships that second product, and buys Oak Standing Desk. After the first build day it checks the Season card and the date label. It snaps the locked Office card on the fresh company, then boots a seeded team, clicks Expand office, and snaps the Open Floor card and the new desks in the room. After Sneakers is researched it snaps the picker bonus, starts that product, and snaps the journey bonus line. Button names and the order are in the feature files. Scroll the journey with the same reveal the tests use before clicking a card that sits below New Product.

## Evidence

The helper writes these PNGs into `SV_PROOF_DIR` and prints `SNAP` plus the file name:

- `01-journey.png` — Company Journey at the top
- `02-research-card.png` — Research card on day 1
- `03-picker-locked.png` — locked topics and types in the picker
- `04-release-research.png` — release screen with the research line
- `05-trained-notice.png` — the lesson line on the training day
- `06-notice-gone.png` — the next office day, lesson line gone
- `07-research-unlocked.png` — the unlock line
- `08-sneakers-started.png` — Sneakers Newsletter on the bench
- `09-upgrades-card.png` — Upgrades card with Buy Oak Standing Desk enabled
- `10-upgrade-owned.png` — the purchase line and the owned desk
- `11-season-card.png` — Season card, favored topics, and the next event
- `12-date-label.png` — the date label, "Spring 2 · Year 1", after one office day
- `13-office-card.png` — Office card before the expansion, Garage Loft, desks 1/4, Expand office disabled
- `14-office-expanded-card.png` — Office card after Expand office, Open Floor, desks 3/7
- `15-office-new-desks.png` — the office at the normal game size, with the new desks among the existing furniture
- `16-research-fit-picker.png` — the picker fit line with "Research bonus: +6 fit" after Sneakers is researched
- `17-research-fit-journey.png` — Company Journey with "Sneakers Newsletter · Research bonus +6 fit" on the product that just started

A finished run prints `PROOF PASS` or `PROOF FAIL` and a `FAILURE` line for each miss. Open the PNGs. A black frame means the display server did not render the SubViewport.

## Cleanup

The helper's data dir is under the OS temp directory. Leave it. Do not commit `SV_PROOF_DIR`, `game/assets/runtime/`, or a `.uid` created beside a copied script. Do not commit a helper copy under `game/tools/`.

## Helpers

The only helper is `.cursor/skills/verify-startup-valley/capture_journey.gd`. It reads `SV_PROOF_DIR` and isolates `STARTUP_VALLEY_DATA_DIR`. Headless gameplay checks that do not need PNGs stay the Godot `--script res://tests/...` commands in `AGENTS.md`.
