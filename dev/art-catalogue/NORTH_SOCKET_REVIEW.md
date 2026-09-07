# North workstation socket and four-desk projection review

Reviewed 2026-09-04 06:35 UTC. **No tested north offset is accepted as a complete workstation. All four desk fixtures remain unapproved.** This review changes no candidate art, pose, capture harness, runtime metadata or saved game. Diagnostic color-boundary annotations were made from the existing native PNGs; no new semantic art was generated.

## Evidence examined

- All six native 1280×720 captures in `game/tests/output/north-seating/with-computer/`: `idle-frame0.png`, `pose-frame1.png` through `pose-frame5.png`.
- `game/tools/capture_north_seating.gd`, including actual sprite origins and draw ordering.
- Native/nearest-enlarged Mina and Theo north atlases, north chair v1, east chair v2, north computer kit v2 and all four current desk fixtures.
- Per-pixel center-column color transitions in the desk PNGs, rather than inferring a tabletop plane from whole-object alpha bounds.

For the top row the desk anchors are `(280,272)`, `(584,272)`, `(888,272)`; chair/physical work feet are 32px south. The lower row repeats this at y496. The three columns apply actor-only render Y offsets −8, −12, −16. Desks and the computer kit are at depth `anchor.y`/`anchor.y+1`, the actor at `physical_foot.y`, and the **entire** chair at `physical_foot.y+1`.

## P0: the current north desktop violates the intended projection

The intended calibration contract is a 32px elevation with screen-aligned floor axes:

- N/S: three-by-one-cell tabletop, 96×32, plane x[48,144), y[112,144), near floor-contact boundary y176.
- E/W: one-by-three-cell tabletop, 32×96, plane x[80,112), y[80,176), near floor-contact boundary y208. A side tray can extend beyond the 32px top width, but it is not part of that plane.

Measurements below count the outlined plane, including its far outline and near top rim. The near boundary is the first row after that rim. This uses exclusive boundaries consistently; measuring from the last rim pixel instead gives a rise one pixel larger.

| Fixture | Entire opaque silhouette | Outlined tabletop plane | Near rim / boundary | Floor-contact boundary | Inferred rise | Disposition |
| --- | --- | --- | --- | --- | --- | --- |
| `desk-north-v2.png` | 96×68 at (48,108) | **96×27**, y[108,135) | rim134 / boundary135 | 176 | **41px**, not32 | Top is 5px too shallow, 9px too high at its near boundary |
| `desk-south-v2.png` | 96×66 at (48,110) | **96×29**, y[110,139) | rim138 / boundary139 | 176 | **37px**, not32 | Top is 3px too shallow, 5px too high at its near boundary |
| `desk-east-v3.png` | 36×130 at (80,78) | **32×96**, y[78,174) | rim173 / boundary174 | 208 | **34px**, not32 | Correct plane depth, but whole plane is 2px north/high |
| `desk-west-v3.png` | 36×128 at (76,80) | **32×94**, y[80,174) | rim173 / boundary174 | 208 | **34px**, not32 | Plane is 2px too shallow; near boundary is 2px high |

The N interior is only x49–142/y110–133; its bright near rim is y134, darker vertical apron y135–140, and black separator y141. S interior is approximately y112–137, near rim138, apron139–144. E interior is approximately x81–110/y80–172, rim173; W interior is approximately x81–110/y83–172, rim173. The outline-inclusive dimensions above, not the smaller wood-fill interior, should be compared with the 96×32 or 32×96 geometric guide.

This explains why a superficially good full silhouette is not enough. N's `96×68` includes legs, and E/W's `36px` width includes a 4px side tray. Neither proves the desk's floor/top projection.

### Native color-boundary annotation

![Actual native desk plane boundaries; no candidate pixels rescaled](/Users/zhast/GitHub/startup-valley/game/tests/output/north-socket-review/desk-boundaries-native.png)

Each candidate is displayed at exactly native 192×224 inside its panel. Blue brackets mark measured far/near plane boundaries, the green tick marks the required near boundary, and orange marks the registered floor-contact boundary. Original canvas coordinates are printed below each panel. Separate per-desk annotated PNGs and a nearest 2× sheet are in `game/tests/output/north-socket-review/`. These are evidence overlays, never runtime assets.

Method: inspect original pixels along x96 and cross-check the horizontal top edges. For N, y133 is ordinary wood `#B9480D`, y134 is the bright top rim `#F97A02`, y135 darkens into apron, and y141 is the black underside boundary. The corresponding rim changes occur at S138, E173 and W173. Alpha bounds identify the final leg pixels at y175 for N/S and y207 for E/W. One-pixel antialias ambiguity is absent in these binary-alpha native exports, although choosing rim pixels versus geometric boundaries changes the quoted rise by one pixel.

**Correction priority:** redraw/normalize N/S against the exact technical guide before retuning poses. Keep E/W's 2px differences explicit for the family review. Do not stretch only a tabletop or relabel full alpha bounds as the plane. The root is handling corrected N/S generation; this review does not edit those candidates.

## P1: translating the whole computer kit south hides the wrong problem

The current keyboard occupies source x79–109/y127–137, with key-face pixels approximately y128–136. With the shared desk pivot `(96,160)`, its last few rows already overlap the N desk's near rim/apron instead of lying wholly on the horizontal wood surface.

A whole-kit **+6px south** shift would place key faces at y134–142 and the keyboard outline through y143. On the current N2 desk that is rim/apron/underside, not tabletop. The shift also moves the monitor stand and mouse, which were not independently shown to need that translation. **Reject this adjustment for N2.**

On a corrected N top ending at y144, y134–142 could become a valid keyboard location. That must be evaluated against the corrected art; it is not approval of the current composite or proof that the hands/seat then fit.

## P1: hand contact is not satisfied across all typing frames

Let `P` be the physical work-cell/chair pivot and `o` the actor render offset. The atlas origin is `P + (0,o) − (24,72)`. Keyboard key-face Y is currently `P.y−64 … P.y−56`.

Native hand-color samples were cross-checked against the enlarged sprites. They are not semantic collision masks: Mina's visible typing skin lies mostly at cell y36–39, reaching y42 in frame4; Theo's hands are around y31–37 and move differently between frames. The corresponding hand bands are:

| Actor-only offset | Mina hand Y relative to P | Theo hand Y relative to P | Current key contact |
| --- | --- | --- | --- |
| −8 | −44…−38 | −49…−43 | Clear southward gap; neither can type on the current keyboard |
| −12 | −48…−42 | −53…−47 | Smaller but still clear gap |
| −16 | −52…−46 | −57…−51 | Mina remains at least4px south; only some Theo fingertips overlap the last1–2 key rows |

The broad Theo range must not be treated as contact for all four frames: frame4's hands sit lower than frame3, and the visible hand sample in frame5 is also below the existing key-face band. The native `pose-frame2.png`/`pose-frame4.png` lower-right composite around `(872…904,470…490)` shows why one apparently touching frame is insufficient. Mina's upper-right hand region is around `(872…904,252…258)`, while the current keys are around y240…248.

The hands are also near the keyboard's lateral extremes. Mina reaches roughly x8…40 within its 48px cell, while the keyboard spans P.x−17…P.x+13; the far-right fingers approach the mouse side. This deserves a native contact-point check after the desktop is corrected, not speculative whole-pose scaling.

## P1: −16 moves the hip as well as the feet

The north chair v1 has a 32×55 silhouette, backrest top at local y73 (`P.y−39`) and floor contact through y127 (`P.y+15`). Its seat plane is mostly obscured by the rear frame. East chair v2 exposes a plausible same-family seat support at local y96–97 (`P.y−16 … P.y−15`); north's small blue seat shoulders around y95–104 are compatible with that hypothesis, but do not prove an exact authored socket.

Mina's rear hip/trouser support region is visually around cell y63–65; Theo's broad hip support is nearer y59–61. These anatomical ranges have roughly ±2px ambiguity because the sprites do not contain explicit seat landmarks and the chair hides them in the actual composite.

Under the east-derived seat-plane hypothesis:

| Offset | Mina hip support relative to P | Theo hip support relative to P | Seat-support interpretation |
| --- | --- | --- | --- |
| −8 | −17…−15 | −21…−19 | Mina is a plausible chair-only test; Theo is already several pixels high |
| −12 | −21…−19 | −25…−23 | Both progressively above the likely support plane |
| −16 | −25…−23 | −29…−27 | About7–10px high for Mina and11–14px high for Theo; not a supported seat |

Thus −16 does move the shoes north under the desk, but **it cannot do so independently of the hip**. It is not a foot-tuck pose. The entire atlas shifts; the hips and head move by the same amount. Keeping the chair fixed while choosing this offset for fingertip convenience likely floats the hips above its seat.

The existing composite can conceal that mistake: the whole north chair is drawn in front of the actor. Its opaque backrest spans the possible hip region at all three offsets, hiding both bad contact and most feet. “No visible gap” is therefore not evidence of support. The unchanged chair floor pivot also means the chair has not actually moved closer to the desk when only the person moves.

## Offset dispositions and next bounded check

- **Accepted complete north workstation offsets: none.**
- **−8:** retain only as a plausible *Mina chair-support hypothesis*, not a typing/desk fit and not an automatically shared Theo offset.
- **−12:** unaccepted compromise; it proves neither complete keyboard contact nor seat support.
- **−16:** unaccepted. It improves apparent fingertip proximity at the cost of likely unsupported hips, while still failing Mina contact and some Theo frames.
- The visible east chair/pose relation is a useful cross-direction control: Mina east's support underside near cell y55 lands about1–2px above that chair's y96–97 seat when unshifted. The north atlas has different anatomical placement inside its cell; a shared numeric pivot is not a shared seat socket.

After the desk projection is corrected:

1. Establish a visible/authored chair support plane and pose-specific hip landmark. Do not approve contact behind an opaque rear-chair mask alone.
2. Place the **chair and supported actor together** relative to the work cell, preserving their hip/seat relationship; keep navigation feet/reservations unchanged. A deliberate sub-cell chair pull-in can be tested, but should not be mistaken for actor-only lift.
3. Place keyboard/mouse wholly on the corrected horizontal top, then check leading fingertip contacts in every typing frame. If monitor, keyboard and mouse need different sockets, use genuinely separate authored kit components rather than dragging the entire packed kit to satisfy one hand.
4. Inspect the monitor/head relationship too: moving the person north eventually covers the current low monitor. Keyboard contact alone is not sufficient acceptance.
5. Verify chair backrest/armrest/base depth separately from the actor's hands, hips and feet, then inspect idle→typing→standing and sit/pull-in continuity. A new offset must not create a visible seat hop.

No pose correction or replacement socket is proposed as final before those geometry checks. The current findings narrow the next test; they do not justify a larger arbitrary offset or a new pose batch yet.
