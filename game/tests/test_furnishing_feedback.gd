extends SceneTree
## Focused response/recovery correlation tests. Actual input + stdio + SQLite
## durability is covered separately by test_furnishing_worker_ui.gd.

var checks := 0
var failures: Array[String] = []

func _initialize() -> void:
	OS.set_environment("STARTUP_VALLEY_NO_WORKER", "1")
	call_deferred("run")

func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures.append(message)
		push_error(message)

func snapshot(revision: int, x: float = 22.0) -> Dictionary:
	return {"version": 1, "revision": revision, "inventory": [], "placements": {"decor-broadleaf_planter": {"grid": [x, 16.0], "facing": "east"}}, "recovery": ""}

func pending(editor: OfficeRenovation, revision: int = 3) -> void:
	editor._pending_mutation = {"operationId": "same-operation", "expectedRevision": revision, "placements": {"decor-broadleaf_planter": {"grid": [22, 16], "facing": "east"}}, "previous": {}}
	editor._save_pending = true

func run() -> void:
	var editor := OfficeRenovation.new()
	root.add_child(editor)
	check(OfficeRenovation._same_placements({"p": {"grid": [22, 16], "facing": "east"}}, {"p": {"grid": [22.0, 16.0], "facing": "east"}}), "JSON floats and snapped integers describe the same grid")
	check(not OfficeRenovation._same_placements({"p": {"grid": [22, 16], "facing": "north"}}, {"p": {"grid": [22.0, 16.0], "facing": "east"}}), "Different facings are never the same placement")
	pending(editor)
	editor.receive_state(snapshot(4))
	check(not editor._save_pending and editor._pending_mutation.is_empty(), "Bootstrap confirms the committed lost-ack placement")
	check(editor._history.size() == 1, "Lost acknowledgement adds exactly one Undo step")
	editor.receive_state(snapshot(4), "same-operation")
	check(editor._history.size() == 1, "Late duplicate response cannot add another Undo step")
	editor._history.clear()
	pending(editor)
	editor.receive_state(snapshot(5, 23.0), "same-operation")
	check(not editor._save_pending and editor._pending_mutation.is_empty(), "Replayed receipt with newer layout clears pending without rolling back")
	check(editor._history.is_empty() and float(editor._committed_state.placements["decor-broadleaf_planter"].grid[0]) == 23.0, "A newer layout is not an Undo step for an older response")
	pending(editor, 5)
	editor.save_failed("same-operation", "Storage unavailable")
	check(not editor._save_pending and not editor._pending_mutation.is_empty(), "Failed write retains same operation for explicit Retry")
	editor.receive_state(snapshot(5, 23.0))
	check(not editor._pending_mutation.is_empty() and editor._last_save_error == "Storage unavailable", "Same-revision refresh preserves failure and retry payload")
	editor.receive_state(snapshot(6, 24.0))
	check(editor._pending_mutation.is_empty() and not editor._last_save_error.is_empty(), "Superseded failed write drops obsolete retry with explanation")
	editor.connection_lost()
	check(not editor._can_save(), "Cached inventory cannot imply the disconnected worker can save")
	editor.receive_state(snapshot(6, 24.0))
	check(editor._can_save(), "Fresh authoritative state restores save availability")
	editor.free()
	await retry_after_movement()
	print("Furnishing feedback: %d checks, %d failures" % [checks, failures.size()])
	quit(0 if failures.is_empty() else 1)

func retry_after_movement() -> void:
	# This is an isolated UI correlation fixture, not a fake durability proof.
	# Capture outbound signals but never fabricate a successful worker response.
	root.size = Vector2i(1280, 720)
	root.content_scale_size = Vector2i(1280, 720)
	var game := preload("res://world/main.tscn").instantiate() as GameMain
	root.add_child(game)
	await process_frame
	game.set_process(false)
	game._spawn_employees([])
	var state := {"version": 1, "revision": 0, "inventory": [], "placements": {}, "recovery": ""}
	for original: Dictionary in game.room.layout_model.data.props:
		if int(original.required_hires) != 0: continue
		state.inventory.append({"id": original.id, "kind": original.kind, "ownerId": str(original.get("owner_id", "")), "essential": true, "grant": "fixture", "roleKit": ""})
		state.placements[original.id] = {"grid": original.grid.duplicate(), "facing": original.facing}
	var library: Dictionary = OfficeLayout._read_json(OfficeLayout.FURNISHING_CATALOG_PATH)
	for item: Dictionary in library.starter_decor:
		state.inventory.append({"id": item.id, "kind": item.kind, "ownerId": "", "essential": false, "grant": "fixture", "roleKit": ""})
	game._on_furnishing_received(state)
	var renovation := game.office_renovation
	renovation.save_requested.disconnect(game._save_furnishing)
	var sent: Array[Dictionary] = []
	renovation.save_requested.connect(func(operation_id: String, revision: int, placements: Dictionary, actors: Array) -> void:
		sent.append({"operationId": operation_id, "expectedRevision": revision, "placements": placements.duplicate(true), "actorCells": actors.duplicate(true)})
	)
	var original_position := Vector2(565.125, 619.875)
	game.player.position = original_position
	game.room.navigation.actors["founder"] = original_position
	renovation.open()
	renovation.select_placement("decor-broadleaf_planter")
	renovation.begin_move()
	renovation.preview_at(Vector2i(24, 8))
	check(renovation.commit_preview() and sent.size() == 1, "A real editor submission freezes its first actor-position snapshot")
	var original_request := sent[0].duplicate(true)
	renovation.save_failed(str(original_request.operationId), "Storage unavailable")
	renovation.receive_state(state)
	renovation.close()
	check(not renovation.active and not renovation._pending_mutation.is_empty(), "A failed uncommitted save can be left and revisited")
	var moved_position := Vector2(575.125, 650.875)
	game.player.position = moved_position
	game.room.navigation.actors["founder"] = moved_position
	renovation.open()
	renovation.retry_save()
	check(sent.size() == 1, "Revisiting Retry after movement does not dispatch the old founder snapshot")
	check(renovation._pending_mutation.is_empty() and not renovation._save_pending and not renovation._pending_undo, "Moved-actor retry is cleared, not silently rewritten with a reused operation ID")
	check(renovation._status.text.contains("Someone moved") and renovation._status.text.contains("Choose the placement again"), "Discarded stale retry has an actionable readable explanation")
	check(game.player.position == moved_position and game.room.placement_overrides == state.placements, "Rejected stale retry keeps current founder and committed room unchanged")
	check(sent[0] == original_request, "The original operation fingerprint and frozen actor fields remain untouched")
	renovation.select_placement("decor-broadleaf_planter")
	renovation.begin_move()
	renovation.preview_at(Vector2i(24, 8))
	check(renovation.commit_preview() and sent.size() == 2, "After stale retry rejection a fresh placement can be submitted normally")
	var fresh := sent[1].duplicate(true)
	check(str(fresh.operationId) != str(original_request.operationId), "The new placement gets a fresh operation ID")
	check(fresh.actorCells.size() == 1 and fresh.actorCells[0].position == [moved_position.x, moved_position.y], "Fresh submission carries the current exact founder position")
	renovation.save_failed(str(fresh.operationId), "Storage temporarily unavailable")
	renovation.receive_state(state)
	renovation.retry_save()
	check(sent.size() == 3 and sent[2] == fresh, "Without actor movement Retry remains the identical frozen request")
	check(renovation._save_pending and game.player.position == moved_position, "Unchanged retry waits for acknowledgement without moving the founder")
	game.queue_free()
	await process_frame
	await process_frame
