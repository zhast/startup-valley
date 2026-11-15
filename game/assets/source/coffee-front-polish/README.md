# Espresso front-panel correction

The original code-native south appliance resembled a flat electronic control
box. This replacement retains its full 192×256 canvas, (96,192) ground pivot,
31×46 content bounds at (81,119), original top plane, alpha and placement. Only
the 31×31 front plane at (81,134) changes. The generated cup, group head, pressure
gauge and drip tray make the appliance readable as an espresso machine.

`generated-front-panel.png` is the unmodified built-in ImageGen output. The
[prompt](prompt.md) records the canonical style board, input roles, generation
IDs and the rejected whole-machine attempt. Point sampling and palette mapping
are deterministic in `game/tools/build_coffee_front_polish.gd`.

```sh
godot --headless --path game --script res://tools/build_coffee_front_polish.gd
godot --headless --path game --script res://tools/build_coffee_front_polish.gd -- --check
```

The builder uses the unchanged historical code-native fixture as its base. It
emits the accepted-size panel, full espresso layer and exactly recomposed south
whole reference here and copies the latter two to runtime. It changes no
counter, grinder, serviceware, plant, other facing, interaction or hit geometry.
The historical fixture is preserved; the production regression explicitly
selects this retained source for the two corrected files.

`technical-validation.json` records byte/pixel integrity and geometry checks.
The candidate review record binds this source and the actual-room evidence to
the final runtime hashes. A generated candidate is not its own approval.
