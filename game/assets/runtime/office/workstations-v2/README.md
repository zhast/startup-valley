# Reviewed workstations v2

Native, unscaled runtime layers for the accepted North, East, South and West workstation
assemblies. Desk and equipment PNGs are byte-for-byte copies of the reviewed
calibration exports. The six chair layers now use the retained ImageGen wooden
chair family in `assets/source/task-chair-v3`, normalized reproducibly by
`tools/build_task_chair.gd -- --apply`. All current hashes are in `manifest.json`;
runtime code must not rotate, mirror, trim, or resample them.

The chair remains a native 96×160 registered module. Its visible bounds are
32×43; the shorter wooden back, cream cushion and four legs replace the earlier
corporate chair while preserving the seated hip/hand anchors. Side `front`
layers are the near seat rail/legs (the historical node name is `ChairNearArm`).
Collaboration tables reference these same six files directly at their existing
chair offsets; old padded cluster copies remain historical source material.

The furniture catalogue supplies each direction's independent footprint,
socket, anchor, and layer depths. `CharacterArt` owns the matching immutable
pose/presentation capability. Neither catalogue review flags nor these files on
their own grant runtime admission.

The normal production path and its bounded 140 ms seated handoff are captured
at 1280×720 under `res://tests/output/reviewed-workstations-production/`.
