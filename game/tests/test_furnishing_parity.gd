extends SceneTree
## Cross-process semantic parity, consuming cases computed by the real worker.
func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var path := "res://tests/output/furnishing-parity/cases.json"
	for argument: String in OS.get_cmdline_user_args():
		if argument.begins_with("--cases="): path = argument.trim_prefix("--cases=")
	var input: Variant = OfficeLayout._read_json(path)
	if not input is Dictionary:
		push_error("Generate worker parity cases before running: " + path)
		quit(1)
		return
	var contexts: Dictionary = {}
	for context: Dictionary in input.contexts:
		contexts[context.name] = context
	var model := OfficeLayout.new()
	model.load_files()
	model.furnishing_bound = true
	var failures: Array[Dictionary] = []
	for item: Dictionary in input.cases:
		var context: Dictionary = contexts[item.context]
		model.furnishing_inventory.clear()
		for owned: Dictionary in context.inventory: model.furnishing_inventory[str(owned.id)] = owned
		var placements: Dictionary = context.placements.duplicate(true)
		placements[item.id] = {"grid": item.grid, "facing": item.facing}
		var valid := true
		var errors: Array = []
		for stage: int in range(5):
			var result := model.validate_placements(model.resolve_placements(stage, placements, true))
			if not result.valid:
				valid = false
				errors = result.errors
				break
		if valid != bool(item.valid):
			failures.append({"case": item, "godot_valid": valid, "godot_errors": errors})
	var destination := path.get_base_dir().path_join("godot-results.json")
	var output := FileAccess.open(destination, FileAccess.WRITE)
	output.store_string(JSON.stringify({"checks": input.cases.size(), "failures": failures}, "\t"))
	print("Furnishing parity: %d cases, %d mismatches; %s" % [input.cases.size(), failures.size(), destination])
	quit(0 if failures.is_empty() else 1)
