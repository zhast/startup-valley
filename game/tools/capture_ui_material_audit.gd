extends "res://tools/capture_visual_review.gd"
## Audit-only production evidence. No font/skin overrides or worker requests.

const MATERIAL_OUTPUT := "res://tests/output/ui-material-audit"
var _material_captures: Array[Dictionary] = []

func _capture(name_value: String) -> bool:
	await _save_material_capture(name_value)
	if name_value == "ui-journal-active":
		var panel := _main.job_panel
		await _material_pointer(panel._usage_toggle, false)
		await _save_material_capture("usage-hover")
		await _material_pointer(panel._usage_toggle, true)
		await _save_material_capture("usage-pressed")
		_material_release(panel._usage_toggle)
		await _settle(3)
		await _save_material_capture("usage-expanded")
		await _material_click(panel._usage_toggle)
		await _material_click(panel._activity_details_toggle)
		await _save_material_capture("work-details-expanded")
		await _material_click(panel._usage_toggle)
		await _save_material_capture("work-and-usage-expanded")
	if name_value == "ui-journal-approval":
		await _material_click(_main.job_panel._usage_toggle)
		await _save_material_capture("approval-usage-expanded")
	if name_value == "ui-work":
		var panel := _main.job_panel
		await _material_click(panel._purpose_picker)
		assert(panel._purpose_picker.get_popup().visible)
		await _save_material_capture("assignment-dropdown-open")
		panel._purpose_picker.get_popup().hide()
		await _material_click(panel._attachment_toggle)
		assert(panel._attachment_picker.visible)
		await _save_material_capture("attachment-expanded")
		# Invoke the same purpose-change path as the selector without submitting
		# a work order. This is a fixture transition, not a hardware-input claim.
		panel._choose_work_purpose(1)
		panel._choose_work_purpose(0)
		await _settle(3)
		await _save_material_capture("attachment-after-template-roundtrip")
	return true

func _save_material_capture(name_value: String) -> void:
	await create_timer(0.25).timeout
	await process_frame
	RenderingServer.force_draw(false)
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(MATERIAL_OUTPUT))
	var path := MATERIAL_OUTPUT.path_join(name_value + ".png")
	var rendered := root.get_texture().get_image()
	assert(rendered.get_size() == Vector2i(1280, 720))
	assert(rendered.save_png(path) == OK)
	var controls: Array[Dictionary] = []
	_material_inventory(_main, controls)
	var panel := _main.job_panel
	var state := {"attachmentContentVisible": panel._attachment_picker.visible, "attachmentArrowExpanded": panel._attachment_toggle.get_meta("cozy_disclosure_expanded", false), "usageVisible": panel._usage_label.visible, "workDetailsVisible": panel._activity_details.visible, "activityScrollRect": str(panel._activity_scroll.get_global_rect())}
	_material_captures.append({"name": name_value, "path": path, "controls": controls, "state": state})
	var file := FileAccess.open(MATERIAL_OUTPUT.path_join("manifest.json"), FileAccess.WRITE)
	file.store_string(JSON.stringify({"workerDisabled": true, "productionSkins": true, "productionTypography": true, "viewport": [1280, 720], "captures": _material_captures, "limitations": ["Audit evidence, not a visual pass/fail verdict.", "Pointer events are injected through Godot, not OS hardware.", "Only disclosure and dropdown actions are clicked; no job/provider requests."]}, "\t"))
	file.close()
	print("UI material audit: " + name_value)

func _material_inventory(node: Node, output: Array[Dictionary]) -> void:
	if node is Control and (node as Control).is_visible_in_tree():
		var control := node as Control
		var entry: Dictionary = {"node": str(control.get_path()), "class": control.get_class(), "rect": [control.global_position.x, control.global_position.y, control.size.x, control.size.y]}
		if control is Button:
			var button := control as Button
			entry["text"] = button.text
			entry["variant"] = str(button.get_meta("cozy_variant", "unassigned"))
			entry["disabled"] = button.disabled
			entry["hovered"] = button.is_hovered()
			entry["styles"] = {}
			for state: String in ["normal", "hover", "pressed", "disabled", "focus"]:
				var style := button.get_theme_stylebox(state)
				var details := {"class": style.get_class()}
				if style is StyleBoxTexture: details["texture"] = (style as StyleBoxTexture).texture.resource_path
				entry["styles"][state] = details
			output.append(entry)
	for child: Node in node.get_children():
		_material_inventory(child, output)

func _material_pointer(control: Control, pressed: bool) -> void:
	assert(control.is_visible_in_tree(), "Audit must never click a hidden control")
	var point := control.get_global_rect().get_center()
	var motion := InputEventMouseMotion.new()
	motion.position = point
	motion.global_position = point
	root.push_input(motion, true)
	if pressed:
		var event := InputEventMouseButton.new()
		event.position = point
		event.global_position = point
		event.button_index = MOUSE_BUTTON_LEFT
		event.pressed = true
		root.push_input(event, true)
	await process_frame

func _material_release(control: Control) -> void:
	var event := InputEventMouseButton.new()
	event.position = control.get_global_rect().get_center()
	event.global_position = event.position
	event.button_index = MOUSE_BUTTON_LEFT
	event.pressed = false
	root.push_input(event, true)

func _material_click(control: Control) -> void:
	await _material_pointer(control, true)
	_material_release(control)
	await _settle(3)
