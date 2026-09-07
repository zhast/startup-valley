# Four-facing workstation production review

September 4, 2026. **PASS for the current Mina/Theo production workstation.**
North, East, South and West now resolve from the ordinary furniture catalogue,
through `TownRoom`, into an immutable `CharacterArt` capability. Runtime layers
and character atlases are exact reviewed copies; catalogue booleans, missing or
forged revisions, and altered handoff values cannot manufacture admission.

The native
[`production-four-facing-contact-sheet.png`](../../game/tests/output/reviewed-workstations-production/production-four-facing-contact-sheet.png)
was captured from ordinary `GameMain`, with the worker disabled, at 1280×720.
It demonstrates that the normal game—not only a calibration fixture—loads all
four independent footprints, render layers, employee pose sources and VFX
anchors without raster rotation or scaling.

Reviewed production assemblies automatically use the bounded, retargetable
140 ms seat handoff. Legacy South fallback remains instantaneous, and explicit
editor calibration retains its own independently timed preview. The transition
changes visual offset/depth only: collision, pathing, reservations and physical
feet remain unchanged.

Verification at this checkpoint:

- `test_reviewed_workstation_production.gd`: 273 checks, 0 failures.
- `test_seat_transition.gd`: 4,729 checks, 0 failures.
- Complete North/East/South/West lifecycle suites: all pass.
- `validate_project.gd`: pass.
- Native production capture: four images, zero failures.

The contact sheet also records honest residual polish: side-facing workstations
are compact, name callouts can compete with narrow furniture, typing motion is
subtle, and no direction has a bespoke sit/stand animation. Those are catalogue
follow-ups, not hidden as completed assets.
