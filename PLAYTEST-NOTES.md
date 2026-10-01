# Chapter 1 playtest notes

Headless first-player pass on 2026-09-30. Godot 4.7.2 (`/home/box/.local/bin/godot`). Worker is Node 22.19 against an isolated `--data-dir`, not a shared company save. No OpenRouter key and no paid model call.

## What ran

- `godot --headless --path game --script res://tools/validate_project.gd` — pass.
- `godot --headless --path game --script res://tests/run_all.gd` — pass (`test_worker_walks_to_desk: passed`).
- `godot --headless --path game --script res://tests/test_ui_flow_regressions.gd` — pass.
- `godot --headless --path game --script res://tests/test_chapter1_first_player.gd` with `STARTUP_VALLEY_NODE` pointing at Node 22.19 and a temp data dir — `CHAPTER1 PASS`.
- `cd harness && npm test` (Node 22.19) — 60 pass, 0 fail, 2 skipped. The skips are the existing live Godot cases that require `GODOT_BINARY`; they were not set in that process.

The chapter 1 script is `game/tests/test_chapter1_first_player.gd`. It is not part of `run_all.gd`. It boots `main.tscn` in a 1280×720 subviewport, uses the real worker, and stops before any model call.

## What the fresh company does

1. Title screen, founder alone, floor and wall art bound.
2. Start company opens Journey. Hire Mina (free) confirms and only Mina joins.
3. Mina's desk is `mira-workstation` with `mina_discovery_kit`.
4. Meet Mina returns to the office. The next-step hint names the website work order.
5. WASD moves the founder. Founder and Mina use their own locomotion sheets.
6. J opens Journey. Prepare work order opens Assign bound to the website milestone.
7. Start website work order, with no API key, opens Connect AI and does not submit a job.
8. End day + save reaches the day summary, which can begin the next day.

## What broke, and the fix

The website Start button was disabled whenever no key was saved. `configure_employees()` (roster bootstrap, including the hire that follows Journey) calls `close_drawer()`, which hides Connect. A disabled button does not emit `pressed`, so `_submit_assignment()` never reached its existing "open Connect" branch. The player could see "Start website work order" and the rail "Connect" label, and the primary action did nothing.

Start now stays pressable when the worker is connected, a teammate is selected, no job is active, and Connect is closed. Pressing it still opens Connect and does not send work. While Connect is open, Start stays disabled, which is what `run_all.gd` requires.

The founder desk caption always said "Hire Mina" if any candidate was available, including Theo after the website, and it preferred that hire over an open website assignment. It now names the actual candidate and keeps "Assign website" while that milestone is the open work order.

## Creative hire

`CharacterArt.locomotion_sheet("creative")` was the founder sheet. It now uses `res://assets/runtime/characters/creative-locomotion.png` (288×320, 6×4, every cell occupied, idle and walk frames distinct). `validate_project.gd` checks that atlas the same way as Mina and Theo.

`furnishing_catalog.json` maps `creative` → `creative_design_kit`, and that kit's `owner_id` is `creative` with `host_kind` `desk`. That is the same pairing Mina and Theo use. There is still no Creative employee in the journey contract (`candidates` is only `mira` and `theo`, max 2) and no Creative desk in `office_layout.json`, so the kit does not appear in a Chapter 1 room. Creative has no seated sheet; a future hire would stand at a desk. Bust portraits for unknown ids still use the founder concept crop. Chat faces already sample the locomotion sheet, so Creative's chat face follows the new sheet.

## Cafe architecture

`cafe-floor.png`, `cafe-wall.png`, `cafe-window.png`, `cafe-trim.png`, and `cafe-door.png` are on disk next to the base architecture sheets. `OfficeArchitecture` only loads `floor.png`, `wall.png`, `trim.png`, `window.png`, and `door.png`. There is no loft/studio/evening/cafe selector. No theme picker was added, and the base floor and wall were not overwritten.

## Remaining gaps

- Chapter 1 work orders still need an OpenRouter key. Connect is the path; this pass does not call a model, run ads, or incorporate.
- Creative is registered art plus a kit binding, not a hire you can make on day 1.
- No windowed play. Checks are headless input (click, WASD, J, end day), not a watched pixel frame.
- Other unbound art (founder seated sheets, extra role kits, outdoor and theme sheets) was left untracked.
