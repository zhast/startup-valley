# Legal document toolkit — north-view native review

Reviewed 2026-09-04. **North-view staged role kit; E/S/W remain missing.** This
adds no lawyer employee, legal filing capability or worker behavior. Mina and
Theo are scale references only. The approved production office is unchanged.

## Contents and provenance

Three separately reusable objects: a dark indigo document-binder stack, an
open two-panel checklist folder, and a small pen cup. There is no gavel,
courthouse symbol, readable legal text or brand logo. Each object can be
placed on a compatible desk independently; it is not a baked workstation.

Masters and full prompts are under
`game/assets/source/overnight-20260904/roles/`:

| Attempt | Original generated file | Outcome |
| --- | --- | --- |
| `lawyer-kit-north-v1.png` | `exec-e271700e-9068-4675-961f-38716292763e.png` | RGBA 1536×1024; binder top skewed/isometric, rejected |
| `lawyer-kit-north-v2.png` | `exec-a149bcf1-9aaf-455b-a1e9-a999e27287f2.png` | RGB 1536×1024; corrected screen-aligned binder, opaque background |
| `lawyer-kit-north-v3.png` | `exec-441882bc-5091-4635-a148-0d4ee4fb2383.png` | RGBA 1672×941; alpha-clean source used for native export |

These are one initial call and two targeted retries. The v1 request used the
existing north computer kit solely for pixel/material density; electronics
were excluded. The corrected generated binder geometry is not a hand-painted
edit. Alpha extraction and native export do not fabricate hidden surfaces.

## Native geometry and palette alternatives

`dev/tools/build_lawyer_north_kit.sh` uses measured source islands, binary alpha,
one shared 40-color normalization and uniform point scaling per complete
object. Actual source crops are binder 406×441 at (57,285), folder 750×552 at
(584,174), cup 226×380 at (1397,346). No asymmetric scaling, rotation or mirror.

Each output remains a full **192×224** transparent canvas at pivot **(96,160)**:

| Object | Actual native ink bounds [x,y,w,h] | Opaque pixels |
| --- | --- | ---: |
| Binders | [54,106,20,22] | 437 |
| Open folder | [114,118,26,19] | 450 |
| Pen cup | [60,129,7,12] | 71 |

The composite has 958 opaque pixels and 32 used colors. The open two-leaf
folder is 26×19 rather than the prompt's approximate 18×22; its complete
shape fits the right-hand desktop without stretching. Binder height also
differs from the early nominal target, so its final elevations should be
measured again when a matching opposite view is drawn.

An optional `*-brand.png` set remaps the same native RGB pixels to the
16-swatch `role-material-palette.svg`. Original alpha is explicitly extracted
and reapplied; every alpha pixel must remain identical. It changes neither
shape nor placement. Both original and remapped versions are retained.

The first palette test exposed a real export bug: palette remapping without
an alpha mask made transparent padding dark and opaque. The native room
capture caught it even though earlier bounds-only tests passed. The builder
now compares the complete alpha mask after remapping, and the Godot harness
checks each pixel plus transparent corner padding. The corrected comparison
has no matte rectangle. No production texture was affected.

## In-room review

The six-frame comparison uses the exact north modular desk and established
north actor/chair/computer sockets. Columns show plain computer, original
kit palette and brand palette; rows show Mina and Theo. The binder's proposed
contact rectangle, entire flat folder, and cup base remain on the top.
Native frame2 and its 4× crop were inspected, with the original native sheet
retained for comparison. The **brand palette is preferred**: quieter indigo
and off-white read as documents without the source's electric-blue accent.

The center remains clear for the employee/computer. Folder and pen cup are
distinct from the desk grain at native size; the binder stack reads mainly
as a compact document block, not individually legible binders. This is an
appropriate small role cue, not a complete legal-office theme. The folder
lies close to the right wrist/mouse area; a real interaction and opposite-view
review must check this before production placement. Characters do not yet
animate using the documents.

Provisional scores: pixel coherence **2**, perspective **2**, silhouette **3**,
layering/anchors **2**, direction consistency **1** (only N exists), placement
**2**; mean **2.0**. Disposition: **normalize/reuse staged north art; generate
true remaining views after validating this composition**. Not runtime-ready.

- [Native room comparison](../../game/tests/output/lawyer-kit-north/frame2.png)
- [Preferred brand palette, native pixels enlarged 4×](../../game/tests/output/lawyer-kit-north/brand-mina-frame2-4x.png)
- [Original palette, 4×](../../game/tests/output/lawyer-kit-north/source-mina-frame2-4x.png)
- [Manifest](../../game/tests/output/lawyer-kit-north/manifest.json)

The final rendered harness passed **382 checks**, zero failures, with six
1280×720 screenshots. The final headless pass including alpha checks was
**34/0**. Tests prove recorded bounds,
alpha and caption isolation, not automatic visual acceptance. Worker disabled,
isolated TownRoom, no GameMain, provider calls, personal saves or new backend.
