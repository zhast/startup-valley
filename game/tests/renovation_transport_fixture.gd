extends RefCounted
## Explicit synchronous transport double for legacy art-only regression tests.
## These tests retain their original sparse override maps and do not claim SQLite
## durability or contract coverage. test_furnishing_worker_ui uses the real worker.

static func bind_layout_only(main: GameMain) -> void:
	assert(OS.get_environment("STARTUP_VALLEY_NO_WORKER") == "1")
	var renovation := main.office_renovation
	if renovation.save_requested.is_connected(main._save_furnishing):
		renovation.save_requested.disconnect(main._save_furnishing)
	if not renovation.has_meta("layout_test_transport"):
		renovation.set_meta("layout_test_transport", true)
		renovation.save_requested.connect(func(operation_id: String, expected_revision: int, placements: Dictionary, _actors: Array) -> void:
			if main.room.set_placement_overrides(placements):
				renovation.receive_state({"version": 1, "revision": expected_revision + 1, "inventory": [], "placements": placements.duplicate(true), "recovery": ""}, operation_id)
			else:
				renovation.save_failed(operation_id, "The art fixture rejected this placement.")
		)
	# Resync after a geometry-only test changes its facing outside Renovate.
	renovation.receive_state({"version": 1, "revision": main.room.furnishing_revision + 1, "inventory": [], "placements": main.room.placement_overrides.duplicate(true), "recovery": ""})
