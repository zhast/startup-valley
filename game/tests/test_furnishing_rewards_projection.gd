extends SceneTree
## Inventory must arrive before the release panel describes an earned reward.
## Simulation eligibility and durable grants are tested in the shared worker.
var failures: Array[String] = []
var events: Array[String] = []
var checks := 0

func _initialize() -> void:
	OS.set_environment("STARTUP_VALLEY_NO_WORKER", "1")
	call_deferred("run")

func run() -> void:
	var client := WorkerClient.new()
	root.add_child(client)
	client.journey_received.connect(func(_journey: Dictionary) -> void: events.append("journey"))
	client.furnishing_received.connect(func(_state: Dictionary, _operation: String) -> void: events.append("furnishing"))
	var old := {"version": 1, "revision": 2, "inventory": [], "placements": {}, "recovery": ""}
	var earned := {"version": 1, "revision": 3, "inventory": [{"id": "decor-low_bookshelf", "kind": "low_bookshelf"}], "placements": {}, "recovery": ""}
	var results: Array[Dictionary] = []
	client.company_action_completed.connect(func(_method: String, result: Dictionary) -> void:
		events.append("completed")
		results.append(result)
		check(client.furnishing_state == earned, "Reward completion sees the already projected inventory")
	)
	client.furnishing_state = old.duplicate(true)
	var response := {"journey": {"day": 2}, "furnishing": earned.duplicate(true), "furnishingRewards": ["Low bookshelf"]}
	client._handle_response("tycoon.release", "", response)
	check(events == ["journey", "furnishing", "completed"], "Release projects journey and inventory before opening its summary")
	check(results.size() == 1 and results[0].get("furnishingRewards") == ["Low bookshelf"], "Display names reach the completion handler intact")
	response.furnishing.revision = 999
	check(client.furnishing_state.revision == 3, "Cached inventory is isolated from response mutation")
	for method: String in ["tycoon.earlyAccess", "tycoon.expandOffice"]:
		events.clear()
		client.furnishing_state = old.duplicate(true)
		client._handle_response(method, "", {"journey": {}, "furnishing": earned.duplicate(true), "furnishingRewards": []})
		check(events == ["journey", "furnishing", "completed"], method + " projects inventory before reporting completion")
	events.clear()
	client._handle_response("tycoon.release", "", {"journey": {}, "furnishingRewards": []})
	check(events == ["journey", "completed"] and client.furnishing_state == earned, "Legacy response without inventory retains the last authoritative room")
	events.clear()
	client._handle_response("tycoon.release", "", {"journey": {}, "furnishing": {"version": 999}})
	check(events == ["journey", "completed"] and client.furnishing_state == earned, "Unknown furnishing versions cannot replace the saved room")
	client.queue_free()
	await process_frame
	print("FURNISHING REWARD PROJECTION: %d checks, %d failures" % [checks, failures.size()])
	quit(0 if failures.is_empty() else 1)

func check(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		failures.append(message)
		push_error(message)
