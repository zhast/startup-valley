# Supported north workstation assembly study

Status: **diagnostic candidate study, not approved for runtime**. Reviewed all 14 native 1280×720 captures on 2026-09-04. No production sprites, pose registry, navigation, worker, or company state changed.

## Result

Moving the chair and character together preserves their relative support geometry; moving the character alone did not. Of the requested three trials, **chair −12 / actor −20** is the useful next calibration candidate. It is not a finished workstation: Theo still sits approximately four pixels too high against the inferred seat, his head obscures most of the display, and no sit/pull-in/stand transition exists. **Chair −18 / actor −26 is rejected** as a common north socket: Theo's sampled fingertips overshoot the keybed and his head hides 94–95% of its lit monitor pixels.

The desktop is the exact code-native geometry control from `game/tools/modular_desk_geometry.gd`, without material tiles. Flat brown surfaces are intentional geometry controls, not an accepted material treatment. The tabletop is actually visible in these captures; desk parents have positive absolute depth, so their Rear child is not hidden by the room backdrop.

## Reproduction and evidence

```sh
/private/tmp/startup-valley-godot/Godot.app/Contents/MacOS/Godot --headless --path game --script res://tools/capture_supported_north_assembly.gd
/private/tmp/startup-valley-godot/Godot.app/Contents/MacOS/Godot --path game --fixed-fps 30 --write-movie res://tests/output/supported-north-assembly/supported-north.avi --script res://tools/capture_supported_north_assembly.gd
```

- Headless: **115 checks, 0 failures**, `game/tests/output/supported-north-assembly/results-headless.json`.
- Rendered: **143 checks, 0 failures**, `game/tests/output/supported-north-assembly/manifest.json`.
- Native stills: `standing-endpoint.png`, `native-frame0.png` through `native-frame5.png`, `guides-frame0.png` through `guides-frame5.png`, `standing-guides.png` in that directory. All inspected at native size.
- Movie: `supported-north.avi`, **284 frames at 30 FPS**. Capture warm-up/stills precede a 240-frame diagnostic sequence. Hard standing/seated endpoints intentionally expose displacement; this is not a claimed polished transition.

Columns are assembly shifts **0 / −12 / −18**. Mina is the upper row and Theo the lower row. The six desk pivots are `(280,272)`, `(584,272)`, `(888,272)`, `(280,496)`, `(584,496)`, `(888,496)`. Detail review regions are respectively `Rect(232,210,96,110)`, `Rect(536,210,96,110)`, `Rect(840,210,96,110)` and those rectangles translated down 224 pixels.

Inputs are existing fixtures, without raster edits:

- `game/tests/fixtures/furniture-calibration/characters/mira-north-seated-v2.png`
- `game/tests/fixtures/furniture-calibration/characters/theo-north-seated-v2.png`
- `game/tests/fixtures/furniture-calibration/chair-north-v1.png`
- `game/tests/fixtures/furniture-calibration/kits/computer-north-v2.png`

## Fixed geometry and support contract

For desk pivot `D`, the logical work foot is **`P = D + (0,32)`**, unchanged in every column. The blocked desk floor is `Rect(-48,-16,96,32)` relative to `D`. The adjacent reserved work cell is `Rect(-16,16,32,32)`; it shares an edge with, but does not overlap, that footprint.

Chair render foot is `P + (0, shift)`. Seated actor render foot is **chair foot −8Y**. Sprite pivots remain chair `(48,112)` and actor `(24,72)`. Scale remains exactly one. These are render-only placements; no actor/navigation instance is moved into a blocked cell.

The exact desktop is `Rect(-48,-48,96,32)`. Computer N2 is placed at `D + (0,4)`. Its native keyboard outline `(79,127,31,11)` therefore occupies `Rect(-17,-29,31,11)` relative to `D`, wholly inside the desktop and ending two pixels before the near tabletop edge. This fixes the earlier invalid idea of pushing keys onto the old N2 apron; it does **not** change the keyboard's projection.

Guide colors:

- Red: blocked logical desk footprint; green: unchanged reserved work cell.
- White: unchanged logical foot and displacement to the chair.
- Cyan: inferred seat plane at **chair foot −16Y**, derived from the visible east-chair family, not an authored north-chair socket.
- Amber: estimated anatomical hip/support band, Mina native rows **63–65**, Theo **59–61**, each approximately ±2px interpretation uncertainty.
- Blue: exact desktop and unchanged standing sprite-cell outline.

The chair is 22% opaque in guide captures. Consequently a hidden lower body cannot be mistaken for proven seat support.

## Measured comparison

Values below use typing frames 2–5. Hand/key counts are reviewed skin-color samples near the source's outer forearms, **not a complete semantic hand mask**; Theo frame 5 has only one bright sample, so its 1/1 must not be described as complete hand contact. Monitor percentages are the exact fraction of sampled lit display pixels covered by opaque actor pixels, not the fraction of the whole monitor assembly.

| Character | Chair / actor Y from logical foot | Hand samples over keybed, f2 / f3 / f4 / f5 | Lit display hidden | Hip versus inferred seat | Disposition |
|---|---|---|---|---|---|
| Mina | 0 / −8 | 0/16, 0/12, 0/11, 0/16 | 8–9% | −1 to +1px | Support hypothesis plausible, but hands visibly below the keys; reject typing socket. |
| Mina | −12 / −20 | 7/16, 6/12, 8/11, 8/16 | 55–56% | −1 to +1px | Best of these trials; partial contact, monitor remains recognizable but heavily covered. Candidate only. |
| Mina | −18 / −26 | 2/16, 3/12, 2/11, 2/16 | 72–74% | −1 to +1px | Most fingertips move past useful key area; excessive tuck and display obstruction. Reject common socket. |
| Theo | 0 / −8 | 0/7, 0/6, 0/11, 0/1 | 10% | −5 to −3px | Hands miss and inferred seat gap remains. Reject. |
| Theo | −12 / −20 | 3/7, 3/6, 3/11, 1/1 | 79–80% | −5 to −3px | Better contact than other trials, but seat and monitor fail combined acceptance. |
| Theo | −18 / −26 | 0/7, 0/6, 0/11, 0/1 | 94–95% | −5 to −3px | Display nearly disappears and fingertips overshoot; reject. |

The invariant hip gap is the useful finding: **assembly translation cannot fix a character-specific anatomical registration error**. With the same −8 actor/chair relationship, all three Mina hip bands straddle the inferred plane while all three Theo hip bands remain above it. A possible next experiment is a separately calibrated Theo actor/chair relation, not silently accepting the shared value or hiding him behind the chair. Actual north-seat geometry still needs an exposed seat layer or an authored seat landmark before either estimate becomes a production contract.

## Native visual findings and next corrections

1. **Keyboard approach improves at −12, not −18.** In `native-frame2.png` and `native-frame4.png`, compare Mina at `(568,243)` with `(872,243)` and Theo at `(568,466)` with `(872,466)`. At the deepest trial the hands lie beside/back of the keyboard rather than reading as typing. Preserve the exact desktop and supported chair relationship while resolving individual hand reach.
2. **Display obstruction becomes the next constraint.** `native-frame0.png` through `native-frame5.png`, especially Theo center/right around `(584,449)` and `(888,445)`, show a head replacing almost the whole lit screen. Some north-facing overlap is physically expected; 94–95% hides the workstation's useful visual feedback. Do not solve this by drawing a monitor on top of a nearer head. Separate monitor/stand and keyboard sockets, then test a physically taller or otherwise authored compatible monitor kit while keeping keyboard contact on the tabletop.
3. **North seat support is still a hypothesis.** In `guides-frame2.png`, Mina's center hip guide is around `(584,276)`; Theo's center hip guide is around `(584,496)`, approximately four pixels above his inferred seat line at `y500`. Ordinary opaque-chair views cannot prove support because the chair covers these regions. Keep transparent review, and validate a real seat surface before acceptance.
4. **Desk depth is corrected, but chair layering is not validated.** The current whole chair is in front of the character, as in the existing candidate fixture. The desk remains rear/front layered with the actor and chair ahead of its near components. There is no obvious tabletop-cutting-head defect in these static north views, but this does not validate limb/chair depth or a standing approach through the chair. A reusable production chair needs explicit seat/back/front occlusion ownership and a supported sit/stand path.
5. **Sit/stand jumps are 8 / 20 / 26 pixels.** Compare `standing-endpoint.png` with each seated frame. The movie deliberately snaps between them. The standing founder/employee logical foot remains outside the desk while the seated render foot moves inward; the deepest render foot lands inside the desk's projected floor footprint without moving its logical reservation. That can represent a tucked seated body only if a real approach, sit, chair pull-in, and reverse sequence explains it. It cannot ship as a teleport or as a standing collision exemption.
6. **Motion acceptance remains open.** All six source frames were shown at native scale, but tiny hand changes and strong head/chair occlusion make the typing loop subtle. Distinct frames and passing geometry assertions do not establish a readable work animation. Final review must inspect the resolved full assembly in motion with appropriate chair layers and corrected contact.

No offset is registered or approved by this study. The bounded next candidate is **Mina chair −12 / actor −20**, followed by character-specific support and monitor/keyboard assembly calibration. The shared −18 proposal is disproven by the visible and measured evidence above.
