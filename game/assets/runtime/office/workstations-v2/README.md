# Reviewed workstations v2

Native, unscaled runtime layers for the accepted North, East, South and West workstation
assemblies. These PNGs are byte-for-byte copies of the reviewed calibration
exports named in `manifest.json`; runtime code must not rotate, mirror, trim, or
resample them.

The furniture catalogue supplies each direction's independent footprint,
socket, anchor, and layer depths. `CharacterArt` owns the matching immutable
pose/presentation capability. Neither catalogue review flags nor these files on
their own grant runtime admission.

The normal production path and its bounded 140 ms seated handoff are captured
at 1280×720 under `res://tests/output/reviewed-workstations-production/`.
