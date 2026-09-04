extends SceneTree

const POLICY: Script = preload("res://ui/window_presentation.gd")
var checks := 0
var failures: Array[String] = []

func _initialize() -> void:
	call_deferred("run")

func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures.append(message)
		push_error(message)

func run() -> void:
	_test_sizing()
	_test_startup_guards()
	if failures.is_empty(): print("Window presentation: %d checks passed" % checks)
	else: print("Window presentation: %d failures / %d checks" % [failures.size(), checks])
	quit(0 if failures.is_empty() else 1)

func _test_sizing() -> void:
	var retina_usable := Rect2i(0, 66, 3456, 2168)
	var retina: Rect2i = POLICY.initial_rect(retina_usable, 2.0, Vector2i(0, 44))
	check(retina.size == Vector2i(2560, 1440), "Retina startup preserves a 1280×720 logical client area")
	check(retina.position == Vector2i(448, 408), "Retina content and title bar are centered inside usable bounds")
	check(retina.size / 2 == POLICY.LOGICAL_SIZE, "DPI policy changes physical window, not authored UI geometry")
	check(retina_usable.encloses(Rect2i(retina.position, retina.size + Vector2i(0, 44))), "Retina decorations fit the usable screen")
	var standard: Rect2i = POLICY.initial_rect(Rect2i(0, 24, 1920, 1056), 1.0, Vector2i(0, 24))
	check(standard.size == Vector2i(1280, 720), "Standard display keeps the original physical dimensions")
	check(standard.position == Vector2i(320, 180), "Standard display is centered below the menu bar")
	var small_usable := Rect2i(0, 24, 1024, 700)
	var small: Rect2i = POLICY.initial_rect(small_usable, 1.0, Vector2i(0, 24))
	check(small.size == Vector2i(976, 549), "Small screens clamp without stretching either axis")
	check(small.size.x * 9 == small.size.y * 16, "Clamped startup retains exact 16:9 proportions")
	check(small_usable.encloses(Rect2i(small.position, small.size + Vector2i(0, 24))), "Small-screen client and chrome remain visible")
	var offset := Vector2i(-3840, -600)
	var moved: Rect2i = POLICY.initial_rect(Rect2i(retina_usable.position + offset, retina_usable.size), 2.0, Vector2i(0, 44))
	check(moved.position == retina.position + offset and moved.size == retina.size, "Nonzero and negative monitor origins are preserved")
	# macOS uses max connected scale even when the selected monitor is non-Retina.
	var mixed: Rect2i = POLICY.initial_rect(Rect2i(3456, 0, 3840, 2112), 2.0, Vector2i(0, 44))
	check(mixed.size == Vector2i(2560, 1440), "Mixed-display max-scale coordinates keep the logical window readable")
	for invalid_scale: float in [-1.0, 0.0, NAN, INF, 1000.0]:
		var fallback: Rect2i = POLICY.initial_rect(Rect2i(0, 0, 1920, 1080), invalid_scale)
		check(fallback.size == Vector2i(1280, 720), "Invalid scale falls back safely: %s" % invalid_scale)
	check(not POLICY.initial_rect(Rect2i(), 2.0).has_area(), "Unavailable screen metrics do not create a zero-size window")
	check(not POLICY.initial_rect(Rect2i(0, 0, 32, 32), 2.0).has_area(), "Impossibly small usable area leaves the existing window alone")
	var negative_chrome: Rect2i = POLICY.initial_rect(retina_usable, 2.0, Vector2i(-8, -20))
	check(negative_chrome == POLICY.initial_rect(retina_usable, 2.0), "Invalid decoration metrics cannot enlarge available space")

func _test_startup_guards() -> void:
	check(POLICY.should_adapt("macOS", "macOS", Window.MODE_WINDOWED, []), "Normal macOS entry may adapt once")
	check(not POLICY.should_adapt("macOS", "headless", Window.MODE_WINDOWED, []), "Headless tests never query native sizing")
	for platform: String in ["Windows", "Linux", "Web", "Android", "iOS"]:
		check(not POLICY.should_adapt(platform, platform, Window.MODE_WINDOWED, []), "Other platform sizing is unchanged: " + platform)
	for mode: int in [Window.MODE_MINIMIZED, Window.MODE_MAXIMIZED, Window.MODE_FULLSCREEN, Window.MODE_EXCLUSIVE_FULLSCREEN]:
		check(not POLICY.should_adapt("macOS", "macOS", mode, []), "Existing non-windowed mode is preserved: %d" % mode)
	for flag: String in ["--resolution", "--position", "--write-movie", "--embedded", "--editor", "-e", "--project-manager", "-p", "--fullscreen", "-f", "--maximized", "-m"]:
		check(not POLICY.should_adapt("macOS", "macOS", Window.MODE_WINDOWED, PackedStringArray([flag, "1280x720"])), "Explicit geometry or capture bypass: " + flag)
		check(not POLICY.should_adapt("macOS", "macOS", Window.MODE_WINDOWED, PackedStringArray([flag + "=1280x720"])), "Equals-form override bypass: " + flag)
	check(POLICY.should_adapt("macOS", "macOS", Window.MODE_WINDOWED, ["--path", "game", "--script", "res://tools/play_ui_redesign.gd"]), "Opt-in developer entry can exercise native startup")
	check(POLICY.should_adapt("macOS", "macOS", Window.MODE_WINDOWED, ["--", "--resolution"]), "User arguments are not mistaken for engine geometry")
