# Legal toolkit south — native staged candidate

One initial draw and one alpha-extraction retry, no further attempts needed
for this stage. **Native export exists; actual south room composition and
cross-direction acceptance remain pending.** No production art or employee
capability changed.

Sources and prompts: `game/assets/source/overnight-20260904/roles/`.

| Source | Original output | Format/outcome |
| --- | --- | --- |
| `lawyer-kit-south-v1.png` | `exec-72e3f736-b17c-4791-84a4-1c0ad092b1d2.png` | RGB1672×941; right-spined binders, checklist left, opaque checkerboard |
| `lawyer-kit-south-v2.png` | `exec-1cc3f791-4ca7-4952-b82c-4865997408ab.png` | RGBA1672×941; clean source used for export |

The north reference informed identity, not a bitmap flip operation. South
has checklist left/blank cover right, tabs left, right-edge binder spines and
blue pen right. These large identity cues match the intended physical turn;
smaller highlights, tab counts and markings still require a four-view review.
The source's decorative marks are not claimed byte-identical between views.

`dev/tools/build_lawyer_south_kit.sh` uses measured complete source rectangles,
uniform point scale and exact-alpha-preserving shared role-palette remapping:

| Component | Source rectangle [x,y,w,h] | Native bounds [x,y,w,h] |
| --- | --- | --- |
| Binders | [105,236,405,464] | [122,106,20,23] |
| Open folder | [608,214,677,475] | [51,117,26,18] |
| Pen cup | [1375,332,210,365] | [126,131,7,12] |

Every output uses192×224/pivot(96,160). No axis-specific resize, mirror,
rotation or source repaint. Actual binder height23 versus north22 and folder
height18 versus north19 are retained, not stretched to hide variation.
The first layout put the cup immediately against the binder. Moving only
the binder Y108→106 leaves a visible two-row separation; no pixel changes.

The native union has974 opaque pixels and15 used colors. Source and native
4× outputs were inspected: separate document silhouettes, clear blank-paper
blocks and tiny pen cup. The pen cup remains a very small signifier, not an
animated/graspable tool. Pixel geometry alone does not prove actor reach.

The proposed left folder overlaps the ordinary south mouse location. The
next room composition must move that mouse to a clear right-side socket or
omit it intentionally; do not paint the folder over it and call the kit done.
No final placement or complete acceptance score is claimed before that test.

Native outputs: `game/tests/fixtures/furniture-calibration/roles/` prefixed
`lawyer-south-v2-`, with separate `binders`, `folder`, `pen_cup`, union and
nearest4× pale proof. All source alpha checks and palette-alpha comparisons
passed. A common component-union/placement test is still to be added.
