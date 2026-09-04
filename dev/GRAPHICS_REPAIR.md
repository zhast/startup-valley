# Graphics repair — September 3, 2026

## Scope and root causes

This pass addresses the reported workstation orientation and menu-corner defects. It does not certify every visual in the game as finished.

- The former layered desk showed the **screen toward the viewer**, while its employee sat on the far side facing the viewer. Its independently normalized rear/front images were not complementary masks.
- Desk sitting/typing used cross-legged floor/laptop poses. A chair was absent.
- Parchment nine-slice margins were 10 px, cutting through rivets extending beyond that boundary. At large menu sizes this stretched the remaining rivet fragments into triangles. A 14 px source margin fixes the issue using ordinary Godot StyleBoxTexture; this was not an engine bug.
- The 25 px name plaque has mid-edge rivets, unsuitable for vertical stretching. Variable-height rail labels now use the existing corner-riveted parchment; Journey buttons use existing button-state art.
- Fractional 0.98 button/reader scaling and unsnapped drawer movement resampled pixel edges during transitions.

## Implemented

- Three original ImageGen masters retained under `game/assets/source/polish/`: south-workstation, mira-seated, theo-seated.
- One 256×112 workstation atlas: 2×1 cells of 128×112. The source is normalized once and split at row 45 on a common canvas. Rear = chair and far tabletop/keyboard; front = monitor back, near tabletop, props and legs. The hands remain visible over the far tabletop. Both use the same position and native scale.
- Two 288×80 seated atlases: 6×1 cells of 48×80, idle/blink then four typing frames. Foot baseline (24,72); consistent palette and head center. Lunch, approval, research, thinking, delivery and locomotion retain their other original art.
- Removed the desk monitor-screen overlay: a front-facing glow would be on the wrong side of this monitor. Other equipment overlays remain.
- Protected complete parchment corners and wood bevels. Shared outer-frame styling now serves both rail and drawer.
- Nearest sampling on the employee, Company and document UI roots. Nunito font antialiasing configuration is unchanged.
- Button depression is immediate tint plus existing pressed textures, with a 90 ms release. Reader fades retain native scale; the 160 ms drawer slide uses integer positions.
- Native clicking exposed an inconsistent open-dropdown state: it used the blue menu-row highlight as the button surface and inherited white hover-pressed text. It now keeps the authored field/arrow texture and dark ink while its menu is open; menu-row highlights remain blue.

## Asset usage truth

Generated does not mean rendered. Do not force obsolete concepts into the game merely to increase usage.

| Asset family | Current disposition |
| --- | --- |
| south-workstation + new seated sheets | Rendered by founder/employee desks and employee desk poses |
| layered-furniture row 1 | Active research bench layers |
| layered-furniture row 0, employee-workstation, research-bench standalone plates | Superseded; retained references |
| original work sheets | Still used for lunch, thinking, research, approval, delivery; old laptop typing cells superseded |
| shell, campus, coffee, collaboration, archive, approval, prototype | Current modular environment; prototype remains developer-stage art |
| notebook wood, parchment, portraits, tabs, input frames | Active; approved overall silhouette retained |
| generated secondary button states | Now also used by Journey/settings/shell buttons |
| name-plaque, whole-office composition, gameplay title plaque | Retained older art; not used for the repaired variable-size surfaces |
| artifact-reader-frame, standalone binder/rivet pieces, unused Journal helper styles | Alternatives/reference pieces, not evidence of active integration |

The source and runtime READMEs were corrected where they claimed obsolete standalone props or removed renovation panels were still rendered.

## Verification

Focused test: `godot --path game --fixed-fps 60 --script res://tests/test_graphics_regressions.gd`.

It compares all opaque pixels in the four resized parchment corners to the source, verifies shared desk-layer origin/depth/native scale, checks desk-vs-lunch pose selection, tests scale-safe feedback, and saves Chat, Assign, Journey, reader and seated/typing captures at 1280×720 plus a 1600×900 window sample. Fixtures disable the worker and disconnect worker actions; they do not read credentials or modify the player's company.

Evidence is regenerated in `game/tests/output/graphics-repair/`:
- `corner-comparison.png`: previous 10 px cuts on the left, corrected 14 px cuts on the right.
- `office-seated.png`, `office-typing.png`: actual game composition, not pasted concept art.
- `chat.png`, `assign.png`, `journey.png`, `reader.png`, `chat-1600x900.png`.

Verification results:

- Godot import and project validation: pass, including all three new native atlas dimensions.
- Existing gameplay suite, complete-game real-input suite, UI-flow regressions: pass.
- Focused graphics regression: pass. Includes actual mouse motion/down/up opening the **visible purpose picker**, preserved corner pixels, and distinct rendered typing frames for both employees.
- Static review: all 27 current captures regenerated (the original 21-state set has grown).
- Motion review: six world scenarios (1,713 frames at 30 FPS) and six UI scenarios (495 frames at 30 FPS); manifest/keyframe/contact-sheet validation passes. Inspected idle/desk, depth, controls and reader sequences.
- Native macOS window and maximized/aspect-preserved presentation inspected; employee selection, Assign, dropdown, and Escape dismissal exercised through real pointer/key input. The isolated fixture is closed afterward.
- Rebuilding the three runtime PNGs twice produces identical SHA-256 hashes.
- No worker code, protocol, save data or credentials changed. No paid model job was needed or run for this visual repair.

Native dropdown evidence: `game/tests/output/graphics-repair/native-dropdown.png`;
final deterministic open-menu capture: `game/tests/output/graphics-repair/assign-dropdown.png`.

## Rebuild

Run `bash dev/tools/build_workstation_assets.sh`, then Godot import. The full polish-asset builder also invokes this correction builder, so rebuilding old sheets cannot silently restore the old desk. Normalization uses ImageMagick only as development tooling; no production dependency changes.

## Exact ImageGen prompts

### Workstation

Reference: `game/assets/source/polish/layered-furniture-master.png`.
Output master: `game/assets/source/polish/south-workstation-master.png`.

Use case: stylized-concept. Asset type: original Startup Valley pixel-art production workstation, NOT a mockup. Reference image: palette, walnut materials, screen-aligned overhead projection only; correct its wrong computer facing. Draw ONE complete empty workstation, including a charcoal office chair centered BEHIND the desk (north/top of image), warm walnut desk, indigo monitor, small keyboard, mouse, a little plant at left and two books at right. The worker will sit behind the desk and face down toward the viewer. Therefore the visible face of the monitor must be its opaque charcoal BACK with ventilation slots and a stand, NOT its luminous screen. Keyboard is on the far/north side of the monitor, within reach of the chair. Show a believable seat opening behind the tabletop. Screen-aligned 3/4 overhead cozy farming-sim pixel art: long edges horizontal, no yaw, no isometric diamond. Designed for native 128x112 pixels; hard chunky deliberate pixel clusters, 1px dark outlines, limited walnut/charcoal/indigo/cream palette, small vermilion accent. Center the complete object with 8% clear padding. Real transparent background, no checkerboard, floor, grid, labels, people, UI, halo, or watermark. One object only, no variations. The chair's back is above the desk, its lower portion hidden by the tabletop. Keep the chair back a simple vertical rectangle behind the future employee head. The desktop/monitor/legs will be rendered in front of the employee and chair back behind. Leave top-of-desk low enough to reveal the employee head.

### Mina seated

Reference: `game/assets/source/polish/mira-work-master.png`.
Output master: `game/assets/source/polish/mira-seated-master.png`.

Use case: identity-preserve. Asset type: original Startup Valley desk-seated animation sheet. Reference: Mina identity and pixel palette ONLY, do NOT copy cross-legged pose. ONE evenly spaced 6-column by 1-row sheet: first two frames quiet seated idle/blink; next four small alternating typing-hand movements. Mina wears olive-green cardigan, cream trousers, brown shoes, dark hair top bun. She faces the viewer, eyes slightly down toward her desk. Normal ergonomic chair-seated anatomy: upright torso, thighs forward, knees bent, both lower legs vertical side by side, feet pointing down. NO cross-legged posture, NO sitting on ground, NO laptop, NO keyboard, NO chair, NO desk. Furniture is rendered separately. Forearms extend slightly forward at desktop height; typing frames have palms facing down and small finger/wrist changes. Keep same head position, identical scale and foot baseline in every frame; movement only eyelids/hands. Full body in each cell with generous transparent padding. Original cozy farming-sim pixel art, crisp dark outlines and large intentional pixel clusters; intended native 48x80 per cell, entire sheet 288x80. True transparent background; no checkerboard, labels, frames, floor or shadows. Exactly 6 figures in one horizontal row, equally spaced.

### Theo seated

Reference: `game/assets/source/polish/theo-work-master.png`.
Output master: `game/assets/source/polish/theo-seated-master.png`.

Use case: identity-preserve. Asset type: original Startup Valley desk-seated animation sheet. Reference: Theo identity and pixel palette ONLY, do NOT copy cross-legged pose. ONE evenly spaced 6-column by 1-row sheet: first two frames quiet seated idle/blink; next four small alternating typing-hand movements. Theo has brown skin, short curly brown hair, vermilion-orange jacket, white shirt, olive trousers and cream sneakers. He faces the viewer, eyes slightly down toward his desk. Normal ergonomic chair-seated anatomy: upright torso, thighs forward, knees bent, both lower legs vertical side by side, feet pointing down. NO cross-legged posture, NO sitting on ground, NO laptop, NO keyboard, NO chair, NO desk. Furniture is rendered separately. Forearms extend slightly forward at desktop height; typing frames have palms facing down and small finger/wrist changes. Keep same head position, identical scale and foot baseline in every frame; movement only eyelids/hands. Full body in each cell with generous transparent padding. Original cozy farming-sim pixel art, crisp dark outlines and large intentional pixel clusters; intended native 48x80 per cell, entire sheet 288x80. True transparent background; no checkerboard, labels, frames, floor or shadows. Exactly 6 figures in one horizontal row, equally spaced.
