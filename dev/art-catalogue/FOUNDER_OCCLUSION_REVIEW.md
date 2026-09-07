# Founder body and world picking

2026-09-04 10:29 UTC. **Fixed, bounded native/input regression passed.** The
founder has no selection action, but its visible body must occlude objects behind
it just as a noninteractive furniture surface does.

## Proven before and after

The dev capture creates a fresh actual `GameMain` for every case and replaces its
worker with `NullWorker` before adding the scene to the tree. No provider, saved
state, credential or project file is used. Inputs are actual mouse-motion and
button-down/up events, not direct calls to an interaction handler.

| Case | Founder feet / clicked pixel | Before | After |
| --- | --- | --- | --- |
| Founder in front of Mina's desk | (336,304) / (336,238) | Selects hidden `mira-workstation` | No object action |
| Founder in front of Mina | (464,464) / (464,398) | Selects hidden `mira` | No object action |
| Founder behind Mina | (464,400) / (464,364) | Not in the original diagnostic | Still selects visible `mira` |

The chosen pixel is opaque in the actual body texture. Native checks compare
the rendered viewport pixel to the visible body's source pixel, establishing
that the clicked thing really is the founder (or the nearer Mina in case three),
not merely overlapping sprite rectangles. Hidden founder art and zero-alpha
modulation cease occluding the underlying target.

`PlayerAvatar.body_surface_at()` now exposes only its painted character sprite.
`GameMain._interaction_at()` compares that sprite to the top employee/prop surface
using the existing `VisibleSurface` depth ordering. Shadows, status labels and
transparent atlas padding do not become blockers.

**Ground-click behavior is unchanged.** Returning no object interaction prevents
opening a hidden employee/station; it does not make the founder a new clickable
object or turn clicks on its body into a special no-op. The ordinary walkable
ground handling still applies. This is the existing passive-furniture convention.

## Evidence and verification

- `game/tools/capture_founder_occlusion.gd`; test alias
  `game/tests/test_founder_occlusion.gd`.
- `game/tests/output/founder-occlusion/`: historical `before-headless.json`
  (8 checks), `before-native.json` (12 checks) and two native PNGs retained.
- `after-headless.json`: **27 checks, 0 failures**.
- `after-native.json`: **33 checks, 0 failures**, three native PNGs.
- Root independently inspected the after station and employee full-size captures.
  The images are visually unchanged by picking semantics; source/native pixel
  assertions plus input traces are the relevant proof.
- Post-fix headless regressions pass: visible-surface picking32,230, station
  hover288, complete-game real-input checks and `run_all`. The last two report
  pass/fail without counted assertions. Broader combined regression is separate.
- Native AFTER command output was truncated at a context boundary; the saved
  completed result, all three captures and absence of the process were recovered.
  Do not infer additional clean-shutdown claims from the lost console output.
- Native BEFORE warned about two leaked ObjectDB instances at shutdown. An
  independent dev-fixture teardown review is in progress; this result does not
  claim to fix those warnings or establish that they occur in the playable game.

```sh
STARTUP_VALLEY_NO_WORKER=1 godot --headless --path game --script res://tests/test_founder_occlusion.gd
STARTUP_VALLEY_NO_WORKER=1 godot --path game --script res://tests/test_founder_occlusion.gd
```

`--expect-old` exists only to reproduce the historical diagnosis against old
source; do not overwrite frozen before evidence with the fixed implementation.

Source/result SHA-256 at the verified checkpoint:

| File | SHA-256 |
| --- | --- |
| `game/world/main.gd` | `8915f4a56e8af3a4db2ee45e68fb9619dcce9b55391c9015f2080ebd092cdec5` |
| `game/actors/player_avatar.gd` | `b767e2689bfaee52be9fac7742b97bd93ba80e780b6edadfbc6c91affc6f8a06` |
| `game/tools/capture_founder_occlusion.gd` | `fea70c2b91c4afe330b8ef5ae202879efe94fd6d72d73de0323d003e9ba2e221` |
| `after-native.json` | `08a19a43f67258dac9cff3fef4bd300a3ada164603c2f6bf6a772a6589c86356` |
