extends SceneTree

## Boot main.tscn with the real worker and shoot the Company Journey loop.
## Output directory: SV_PROOF_DIR. Prints PROOF PASS or PROOF FAIL.

const MAIN := preload("res://world/main.tscn")
var main: GameMain
var viewport: SubViewport
var failures: Array[String] = []
var proof_dir := ""

func _initialize() -> void:
	proof_dir = OS.get_environment("SV_PROOF_DIR").strip_edges()
	OS.unset_environment("STARTUP_VALLEY_NO_WORKER")
	OS.unset_environment("STARTUP_VALLEY_FAKE_PROVIDER")
	OS.set_environment("STARTUP_VALLEY_IGNORE_HOST_CREDENTIALS", "1")
	if OS.get_environment("STARTUP_VALLEY_DATA_DIR").strip_edges().is_empty():
		var data_dir := OS.get_temp_dir().path_join("startup-valley-proof-%d-%d" % [OS.get_process_id(), Time.get_ticks_usec()])
		DirAccess.make_dir_recursive_absolute(data_dir)
		OS.set_environment("STARTUP_VALLEY_DATA_DIR", data_dir)
	call_deferred("_run")

func check(ok: bool, message: String) -> void:
	if ok:
		print("PASS ", message)
	else:
		failures.append(message)
		push_error("FAIL " + message)

func frames(count: int = 2) -> void:
	for _index: int in range(count):
		await process_frame

func wait_until(predicate: Callable, message: String, timeout_ms: int = 20000) -> bool:
	var deadline := Time.get_ticks_msec() + timeout_ms
	while Time.get_ticks_msec() < deadline:
		await frames(1)
		if predicate.call():
			return true
	check(false, message)
	return false

func button_named(prefix: String) -> Button:
	if main == null or main.company_panel == null:
		return null
	for node: Node in main.company_panel.find_children("*", "Button", true, false):
		var button := node as Button
		if button.is_visible_in_tree() and button.text.to_lower().begins_with(prefix.to_lower()):
			return button
	return null

func label_named(node_name: String) -> Label:
	if main == null or main.company_panel == null:
		return null
	return main.company_panel.find_child(node_name, true, false) as Label

func label_contains(fragment: String) -> bool:
	if main == null or main.company_panel == null:
		return false
	for node: Node in main.company_panel.find_children("*", "Label", true, false):
		if (node as Label).text.contains(fragment):
			return true
	return false

func label_text(text: String) -> Label:
	var found: Label = null
	if main == null or main.company_panel == null:
		return null
	for node: Node in main.company_panel.find_children("*", "Label", true, false):
		var label := node as Label
		if label.text == text and label.is_visible_in_tree():
			found = label
	return found

func reveal(control: Control) -> void:
	if control == null or main == null or main.company_panel == null:
		return
	var content := main.company_panel._content
	if content == null or not content.is_ancestor_of(control):
		return
	var top := control.position.y
	var current := control.get_parent()
	while current != null and current != content:
		if current is Control:
			top += (current as Control).position.y
		current = current.get_parent()
	main.company_panel._scroll.scroll_vertical = maxi(0, int(top) - 8)
	await frames(3)

func click(control: Control) -> void:
	check(control != null and control.is_visible_in_tree() and not (control is BaseButton and (control as BaseButton).disabled), "Click target is visible and enabled: " + (str(control.name) if control != null else "missing") + ((" / " + (control as Button).text) if control is Button else ""))
	if control == null:
		return
	await reveal(control)
	var point := control.get_global_rect().get_center()
	var motion := InputEventMouseMotion.new()
	motion.position = point
	motion.global_position = point
	viewport.push_input(motion, true)
	await frames(1)
	for pressed: bool in [true, false]:
		var event := InputEventMouseButton.new()
		event.position = point
		event.global_position = point
		event.button_index = MOUSE_BUTTON_LEFT
		event.button_mask = MOUSE_BUTTON_MASK_LEFT if pressed else 0
		event.pressed = pressed
		viewport.push_input(event, true)
		await frames(1)
	await frames(8)

func key(code: Key, pressed: bool) -> void:
	var event := InputEventKey.new()
	event.keycode = code
	event.physical_keycode = code
	event.pressed = pressed
	viewport.push_input(event, true)
	await frames(1)

func company_cash() -> int:
	var company: Dictionary = main.company_panel.state.get("company", {})
	return int(company.get("cashCents", 0))

func tycoon_state() -> Dictionary:
	var value: Variant = main.company_panel.state.get("tycoon", {})
	return value as Dictionary if value is Dictionary else {}

func research_points() -> int:
	return int(tycoon_state().get("researchPoints", -1))

func developing() -> Dictionary:
	var value: Variant = tycoon_state().get("developing", {})
	return value as Dictionary if value is Dictionary else {}

func contract_state() -> Dictionary:
	var value: Variant = tycoon_state().get("contract", {})
	return value as Dictionary if value is Dictionary else {}

func latest_shipped() -> Dictionary:
	var history: Array = tycoon_state().get("history", []) as Array
	if history.is_empty() or not history[0] is Dictionary:
		return {}
	return history[0] as Dictionary

func company_reputation() -> int:
	var company: Dictionary = main.company_panel.state.get("company", {})
	return int(company.get("reputation", 0))

func button_choice(title: String) -> Button:
	if main == null or main.company_panel == null:
		return null
	for node: Node in main.company_panel.find_children("*", "Button", true, false):
		var button := node as Button
		if button.is_visible_in_tree() and (button.text == title or button.text.begins_with(title + " ·")):
			return button
	return null

func open_journey() -> void:
	if main.company_panel.visible and main.company_panel.screen == "journey":
		return
	if main.company_panel.visible:
		var back := button_named("Back to office")
		if back != null:
			await click(back)
			await frames(8)
	await key(KEY_J, true)
	await key(KEY_J, false)
	await wait_until(func() -> bool: return main.company_panel.visible and main.company_panel.screen == "journey", "J opens Company Journey")

func open_product() -> void:
	await open_journey()
	if main.company_panel.screen != "product":
		await click(button_named("New Product"))
		await wait_until(func() -> bool: return main.company_panel.screen == "product" and not main.company_panel.busy, "New Product opens the ship screen")

func end_office_day() -> void:
	await click(button_named("End day"))
	await wait_until(func() -> bool: return main.company_panel.screen == "summary", "Ending the day opens the summary")
	await click(button_named("Begin next day"))
	await wait_until(func() -> bool: return not main.company_panel.visible, "Begin next day returns to the office")
	main.day_clock.set_speed(0)

func snap(name: String, focus: Control = null) -> void:
	if focus != null:
		await reveal(focus)
	await frames(6)
	await RenderingServer.frame_post_draw
	var image := viewport.get_texture().get_image()
	var path := proof_dir.path_join(name + ".png")
	var err := image.save_png(path)
	check(err == OK and FileAccess.file_exists(path), "Saved " + path)
	print("SNAP ", path)

func _run() -> void:
	if proof_dir.is_empty():
		check(false, "SV_PROOF_DIR is required")
		print("PROOF FAIL")
		quit(1)
		return
	DirAccess.make_dir_recursive_absolute(proof_dir)
	root.content_scale_size = Vector2i(1280, 720)
	root.size = Vector2i(1280, 720)
	viewport = SubViewport.new()
	viewport.size = Vector2i(1280, 720)
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(viewport)
	viewport.notify_mouse_entered()
	main = MAIN.instantiate()
	viewport.add_child(main)
	var ready := await wait_until(func() -> bool:
		return main._state_loaded and main._worker_ready and main.company_panel != null and main.company_panel.visible and not main.company_panel.state.is_empty()
	, "Worker bootstrap loads a fresh company")
	if not ready:
		_finish()
		return
	main.day_clock.set_speed(0)
	await click(button_named("Start company"))
	await wait_until(func() -> bool: return main.company_panel.screen == "journey", "Start company opens Journey")
	main.company_panel._scroll.scroll_vertical = 0
	await snap("01-journey")
	var contract_card := main.company_panel.find_child("ContractCard", true, false) as Control
	var accept := button_named("Accept contract")
	check(contract_card != null, "Company Journey shows the contract card")
	check(accept != null and not accept.disabled and str(accept.get_meta("cozy_variant", "")) == "secondary" and accept.text == "Accept contract", "Accept contract is a secondary action")
	check(label_named("ContractClient") != null and not label_named("ContractClient").text.is_empty(), "The offer names a client")
	check(label_named("ContractPair") != null and label_named("ContractPair").text.contains("×"), "The offer names topic × type")
	check(label_named("ContractBonus") != null and label_named("ContractBonus").text.begins_with("Bonus $"), "The offer names the bonus")
	check(button_named("Hire Mina") != null and str(button_named("Hire Mina").get_meta("cozy_variant", "")) == "primary", "Hire Mina stays primary beside the contract")
	await snap("22-contract-offer", contract_card)
	await snap("02-research-card", main.company_panel.find_child("ResearchCard", true, false) as Control)
	var expand := button_named("Expand office")
	check(expand != null and expand.disabled and expand.text == "Expand office", "Expand office starts disabled")
	check(label_named("OfficeName") != null and label_named("OfficeName").text == "Garage Loft", "The fresh office is the Garage Loft")
	check(label_named("OfficeDesks") != null and label_named("OfficeDesks").text == "Desks: 1/4", "The fresh desk line is 1/4")
	check(button_named("Hire Mina") != null and str(button_named("Hire Mina").get_meta("cozy_variant", "")) == "primary", "Hire Mina stays primary beside the Office card")
	await snap("13-office-card", main.company_panel.find_child("OfficeCard", true, false) as Control)
	await open_product()
	check(not main.job_panel._connection_panel.visible, "Connect stays closed on the product picker")
	var sneakers_locked := button_named("Sneakers")
	check(sneakers_locked != null and sneakers_locked.disabled and sneakers_locked.text.contains("· locked"), "Sneakers starts locked")
	await snap("03-picker-locked", sneakers_locked)
	await click(button_named("Crypto Alpha"))
	await frames(4)
	await click(button_named("Newsletter"))
	await frames(4)
	var catalog_price := main.company_panel.find_child("Price_100", true, false) as Button
	check(catalog_price != null and str(catalog_price.get_meta("cozy_variant", "")) == "secondary" and catalog_price.text == "Catalog", "Catalog price is a secondary action")
	check(label_named("PriceEffect") != null and label_named("PriceEffect").text == "$9.00 · catalog units", "Catalog shows $9.00 · catalog units")
	var no_ad := main.company_panel.find_child("Marketing_none", true, false) as Button
	var small_ad := main.company_panel.find_child("Marketing_small", true, false) as Button
	var big_ad := main.company_panel.find_child("Marketing_big", true, false) as Button
	check(no_ad != null and not no_ad.disabled and str(no_ad.get_meta("cozy_variant", "")) == "secondary" and no_ad.text == "None", "None is a secondary marketing action")
	check(small_ad != null and small_ad.disabled and str(small_ad.get_meta("cozy_variant", "")) == "secondary" and small_ad.text == "Small ad · Need $50", "Small ad shows Need $50")
	check(big_ad != null and big_ad.disabled and big_ad.text == "Big ad · Need $150", "Big ad shows Need $150")
	var marketing_effect := label_named("MarketingEffect")
	check(marketing_effect != null and marketing_effect.text == "None · $0 · no extra units", "No ad shows $0 and no extra units")
	var marketing_heading := label_text("Marketing")
	await reveal(marketing_heading if marketing_heading != null else marketing_effect)
	if marketing_heading != null:
		main.company_panel._scroll.ensure_control_visible(marketing_heading)
		main.company_panel._scroll.scroll_vertical = maxi(0, main.company_panel._scroll.scroll_vertical - 24)
		await frames(3)
	await snap("20-marketing-picker")
	await click(button_named("Start development"))
	await wait_until(func() -> bool: return developing().get("name", "") == "Crypto Alpha Newsletter" and not main.company_panel.busy, "Development starts on Crypto Alpha Newsletter")
	await end_office_day()
	await open_journey()
	var office_date := label_named("OfficeDate")
	check(office_date != null and office_date.text.contains("Spring 2 · Year 1"), "The date label reads Spring 2 · Year 1")
	check(label_named("SeasonTopics") != null and label_named("SeasonTopics").text == "In season: Fitness, Dating Advice", "Spring favors Fitness and Dating Advice")
	check(label_named("SeasonEvent") != null and label_named("SeasonEvent").text == "Creator Fair in 11 days", "Creator Fair is 11 days away")
	main.company_panel._scroll.scroll_vertical = 0
	await snap("12-date-label", office_date)
	await snap("11-season-card", main.company_panel.find_child("SeasonCard", true, false) as Control)
	await open_product()
	await end_office_day()
	await open_product()
	check(bool(developing().get("ready", false)), "Two office days make the newsletter ready")
	await click(button_named("Release"))
	await wait_until(func() -> bool: return main.company_panel.screen == "release" and label_contains("+3 research points"), "Release shows +3 research points")
	await snap("04-release-research", label_named("ReleaseResearch"))
	await open_journey()
	var patch_offer := button_named("Patch")
	var selling := main.company_panel.find_child("Selling_p1", true, false) as Control
	check(selling != null, "Company Journey shows the selling-product card")
	check(patch_offer != null and not patch_offer.disabled and str(patch_offer.get_meta("cozy_variant", "")) == "secondary" and patch_offer.text == "Patch · $100", "Patch · $100 is a secondary action")
	check(button_named("Hire Mina") != null and str(button_named("Hire Mina").get_meta("cozy_variant", "")) == "primary", "Hire Mina stays primary beside Patch")
	await snap("24-patch-offer", selling)
	await end_office_day()
	await open_journey()
	await end_office_day()
	await open_journey()
	check(company_cash() >= 30000, "Second sales day covers a $300 Tech lesson")
	var train := button_named("Train Tech")
	check(train != null and not train.disabled, "Train Tech is enabled")
	await click(train)
	await wait_until(func() -> bool: return not main.company_panel.busy and label_contains("Founder trained Tech to 3"), "Training notice names the new Tech level")
	await snap("05-trained-notice", label_named("TrainingNotice"))
	await end_office_day()
	await open_journey()
	check(label_named("TrainingNotice") == null, "Training notice is gone after End day")
	await snap("06-notice-gone", main.company_panel.find_child("TrainStaff", true, false) as Control)
	check(research_points() >= 4, "The shipped newsletter earned enough points to research a topic")
	var research := button_named("Research Sneakers")
	check(research != null and not research.disabled, "Research Sneakers is enabled")
	await click(research)
	await wait_until(func() -> bool: return not main.company_panel.busy and label_contains("Unlocked Sneakers. −4 RP"), "Research notice names Sneakers")
	await snap("07-research-unlocked", label_named("ResearchNotice"))
	await end_office_day()
	await open_journey()
	var finished := main.company_panel.find_child("Finished_p1", true, false) as Control
	var sequel_offer := main.company_panel.find_child("Sequel_p1", true, false) as Button
	check(str(latest_shipped().get("status", "")) == "complete", "The first newsletter has finished selling")
	check(finished != null, "Company Journey shows the finished product")
	check(sequel_offer != null and not sequel_offer.disabled and str(sequel_offer.get_meta("cozy_variant", "")) == "secondary" and sequel_offer.text == "Sequel", "Sequel is a secondary action on the finished product")
	check(button_named("Hire Mina") != null and str(button_named("Hire Mina").get_meta("cozy_variant", "")) == "primary", "Hire Mina stays primary beside Sequel")
	await snap("26-sequel-offer", finished)
	var award_offer := main.company_panel.find_child("Award_p1", true, false) as Button
	check(award_offer != null and not award_offer.disabled and str(award_offer.get_meta("cozy_variant", "")) == "secondary" and award_offer.text == "Enter award", "Enter award is a secondary action on the finished product")
	check(label_named("AwardShow_p1") != null and label_named("AwardShow_p1").text == "Whop Creator Awards · $40", "The shipped card names the show and the fee")
	check(label_named("AwardResult_p1") == null, "The result line is hidden until the product enters")
	check(button_named("Hire Mina") != null and str(button_named("Hire Mina").get_meta("cozy_variant", "")) == "primary", "Hire Mina stays primary beside Enter award")
	await snap("28-award-offer", finished)
	var port_offer := main.company_panel.find_child("Port_p1", true, false) as Button
	check(port_offer != null and not port_offer.disabled and str(port_offer.get_meta("cozy_variant", "")) == "secondary" and port_offer.text == "Port", "Port is a secondary action on the finished product")
	check(label_named("PortShelf_p1") != null and label_named("PortShelf_p1").text == "Whop Mobile · $80", "The shipped card names the shelf and the fee")
	check(label_named("PortLine_p1") == null, "The port line is hidden until the port starts")
	check(button_named("Hire Mina") != null and str(button_named("Hire Mina").get_meta("cozy_variant", "")) == "primary", "Hire Mina stays primary beside Port")
	await snap("30-port-offer", finished)
	await open_product()
	var sneakers := button_named("Sneakers")
	check(sneakers != null and not sneakers.disabled and not sneakers.text.contains("locked"), "Sneakers is selectable after research")
	await click(sneakers)
	await frames(4)
	await click(button_named("Newsletter"))
	await frames(4)
	var fit_bonus := label_named("ResearchFitBonus")
	check(fit_bonus != null and fit_bonus.text == "Research bonus: +6 fit", "Picker shows the research fit bonus")
	await snap("16-research-fit-picker", fit_bonus)
	var cheap := main.company_panel.find_child("Price_80", true, false) as Button
	check(cheap != null and str(cheap.get_meta("cozy_variant", "")) == "secondary", "−20% price is a secondary action")
	await click(cheap)
	await frames(4)
	var price_effect := label_named("PriceEffect")
	check(price_effect != null and price_effect.text == "$7.20 · +20% units", "−20% shows $7.20 · +20% units")
	await snap("18-price-picker", price_effect)
	var small_later := main.company_panel.find_child("Marketing_small", true, false) as Button
	check(small_later != null and not small_later.disabled and str(small_later.get_meta("cozy_variant", "")) == "secondary", "Small ad is an affordable secondary action")
	var cash_before_ad := company_cash()
	await click(small_later)
	await frames(4)
	check(label_named("MarketingEffect") != null and label_named("MarketingEffect").text == "Small ad · $50 · +20% units", "Small ad shows $50 and +20% units")
	await click(button_named("Start development"))
	await wait_until(func() -> bool: return developing().get("name", "") == "Sneakers Newsletter" and int(developing().get("pricePercent", -1)) == 80 and str(developing().get("marketing", "")) == "small" and not main.company_panel.busy, "Sneakers Newsletter starts at −20% with a small ad")
	check(company_cash() == cash_before_ad - 5000, "The small ad charges $50 at the start")
	await snap("08-sneakers-started")
	await open_journey()
	var journey_bonus := label_named("ResearchFitJourney")
	check(journey_bonus != null and journey_bonus.text == "Sneakers Newsletter · Research bonus +6 fit", "Journey names the product on the research line")
	await snap("17-research-fit-journey", journey_bonus)
	await end_office_day()
	await open_product()
	await end_office_day()
	await open_product()
	check(bool(developing().get("ready", false)), "Two office days make Sneakers Newsletter ready")
	await click(button_named("Release"))
	await wait_until(func() -> bool: return main.company_panel.screen == "release" and label_named("ReleasePrice") != null, "The second product opens the release card")
	check(label_named("ReleasePrice").text == "$7.20 · +20% units", "Release shows the chosen price and unit effect")
	await snap("19-price-released", label_named("ReleasePrice"))
	check(label_named("ReleaseMarketing") != null and label_named("ReleaseMarketing").text == "Small ad · $50 · +20% units", "Release shows the small ad")
	check(label_contains("Launch sales"), "Release shows launch sales next to the ad")
	await snap("21-marketing-released", label_named("ReleaseMarketing"))
	await _contract_release_proof()
	await open_journey()
	var waits := 0
	while company_cash() < 25000 and waits < 4:
		await end_office_day()
		await open_journey()
		waits += 1
	check(company_cash() >= 25000, "Cash covers Oak Standing Desk (%d cents)" % company_cash())
	var buy := button_named("Buy Oak Standing Desk")
	check(buy != null and not buy.disabled and str(buy.get_meta("cozy_variant", "")) == "secondary", "Buy Oak Standing Desk is an enabled secondary action")
	await snap("09-upgrades-card", main.company_panel.find_child("UpgradesCard", true, false) as Control)
	await click(buy)
	await wait_until(func() -> bool: return not main.company_panel.busy and label_contains("Bought Oak Standing Desk. −$250"), "Purchase notice names the desk")
	await snap("10-upgrade-owned", label_named("UpgradeNotice"))
	check(label_named("Owned_standing_desk") != null, "The owned line names the desk")
	check(button_named("Buy Oak Standing Desk") == null, "The desk buy button hides once it is owned")
	check(not main.job_panel._connection_panel.visible, "The loop never opens Connect")
	await _engine_proof()
	await _focus_proof()
	await _audience_proof()
	await _size_proof()
	await _payroll_proof()
	await _loan_proof()
	await _publisher_proof()
	await _expo_proof()
	await _localize_proof()
	await _town_day_proof()
	await _press_demo_proof()
	await _trailer_proof()
	await _diary_proof()
	await _rival_proof()
	await _feature_proof()
	await _day_plan_proof()
	await _bugs_proof()
	await _crunch_proof()
	await _early_access_proof()
	await _cancel_proof()
	await _slip_proof()
	await _pivot_proof()
	await _playtest_proof()
	await _assign_team_proof()
	await _research_spike_proof()
	await _sale_price_proof()
	await _office_expansion_proof()
	_finish()

func release_company() -> void:
	if main == null:
		return
	var leaving: Node = main
	main = null
	leaving.queue_free()
	var closed := false
	for _index: int in range(40):
		await frames(1)
		if not is_instance_valid(leaving):
			closed = true
			break
	check(closed, "The previous company closed")
	await frames(4)

## Missing-key onboarding opens Connect over a hired company and blocks J.
func dismiss_onboarding() -> void:
	var quiet := 0
	var deadline := Time.get_ticks_msec() + 3000
	while Time.get_ticks_msec() < deadline and quiet < 4:
		await frames(1)
		if main.job_panel._connection_panel.visible or main.job_panel.drawer_is_open():
			main.job_panel.close_drawer(false)
			quiet = 0
		else:
			quiet += 1

func boot_company() -> bool:
	main = MAIN.instantiate()
	viewport.add_child(main)
	var ready := await wait_until(func() -> bool:
		return main._state_loaded and main._worker_ready and main.company_panel != null and main.company_panel.visible and not main.company_panel.state.is_empty()
	, "Worker bootstrap loads the company", 45000)
	if ready:
		main.day_clock.set_speed(0)
	return ready

func seed_team(data_dir: String) -> bool:
	var database := ProjectSettings.globalize_path("res://../harness/src/database.ts")
	var tsx := ProjectSettings.globalize_path("res://../harness/node_modules/tsx/dist/cli.mjs")
	var node := OS.get_environment("STARTUP_VALLEY_NODE").strip_edges()
	if node.is_empty():
		for dir: String in OS.get_environment("PATH").split(":"):
			if FileAccess.file_exists(dir.path_join("node")):
				node = dir.path_join("node")
				break
	if node.is_empty():
		node = "/home/box/.local/node22/bin/node"
	var script_path := data_dir.path_join("seed-office.mjs")
	var script := "import { mkdirSync } from 'node:fs';\nimport { DatabaseSync } from 'node:sqlite';\nimport { GameDatabase } from %s;\nconst root = process.argv[process.argv.length - 1];\nmkdirSync(root + '/company-project', { recursive: true });\nconst file = root + '/startup-valley.sqlite';\nlet db = new GameDatabase(file, root + '/company-project');\ndb.journey.hire('mira', 1);\ndb.close();\nconst sql = new DatabaseSync(file);\nsql.prepare(\"UPDATE milestone_progress SET completed = 1 WHERE id = 'website'\").run();\nsql.close();\ndb = new GameDatabase(file, root + '/company-project');\ndb.journey.recordCompanyChange('office-test-cash', 1, 90000, 0, 0, 'Office test cash');\ndb.journey.hire('theo', 1);\nconst cash = db.journey.state().company.cashCents;\ndb.close();\nif (cash !== 60000) { console.error('expected 60000 cash, got ' + cash); process.exit(2); }\n" % JSON.stringify(database)
	var file := FileAccess.open(script_path, FileAccess.WRITE)
	if file == null:
		check(false, "Could not write the office seed script")
		return false
	file.store_string(script)
	file.close()
	var output: Array = []
	var code := OS.execute(node, PackedStringArray([tsx, script_path, data_dir]), output, true)
	check(code == 0, "Seeded Mina, Theo, and $600 (%s)" % " ".join(output))
	return code == 0

func _contract_release_proof() -> void:
	await open_journey()
	var offer := contract_state()
	check(str(offer.get("status", "")) == "offered", "The offer is still open after the free launches")
	await click(button_named("Accept contract"))
	await wait_until(func() -> bool: return str(contract_state().get("status", "")) == "accepted" and not main.company_panel.busy, "The contract is accepted")
	await open_product()
	var topic_button := button_choice(str(offer.get("topicName", "")))
	var type_button := button_choice(str(offer.get("typeName", "")))
	check(topic_button != null and not topic_button.disabled, "The contract topic stays enabled")
	check(type_button != null and not type_button.disabled, "The contract type stays enabled")
	var other_disabled := false
	for item: Variant in tycoon_state().get("topics", []) as Array:
		if not item is Dictionary:
			continue
		var row := item as Dictionary
		if str(row.get("id", "")) == str(offer.get("topicId", "")):
			continue
		if not bool(row.get("unlocked", false)):
			continue
		var other := button_choice(str(row.get("name", "")))
		if other != null and other.disabled and other.text.contains("· contract"):
			other_disabled = true
			break
	check(other_disabled, "Another topic is disabled for the contract")
	await click(topic_button)
	await frames(4)
	type_button = button_choice(str(offer.get("typeName", "")))
	check(type_button != null and not type_button.disabled, "The contract type is still enabled after the topic click")
	await click(type_button)
	await frames(4)
	await click(button_named("Start development"))
	await wait_until(func() -> bool: return str(developing().get("topicId", "")) == str(offer.get("topicId", "")) and not main.company_panel.busy, "The contracted product starts")
	var guard := 0
	while not bool(developing().get("ready", false)) and guard < 6:
		await end_office_day()
		await open_product()
		guard += 1
	check(bool(developing().get("ready", false)), "The contract product is ready to release")
	var before := company_cash()
	var fans_before := company_reputation()
	await click(button_named("Release"))
	await wait_until(func() -> bool: return main.company_panel.screen == "release" and label_named("ReleaseContract") != null, "Release shows the contract bonus")
	var shipped := latest_shipped()
	var deal: Dictionary = shipped.get("contract", {}) if shipped.get("contract") is Dictionary else {}
	var bonus := int(deal.get("bonusCents", 0))
	var client := str(deal.get("client", ""))
	check(bonus > 0 and client == str(offer.get("client", "")), "The shipped product keeps the client and the bonus")
	check(label_named("ReleaseContract").text == "Contract: %s · +$%d" % [client, int(bonus / 100)], "Release names the contract bonus")
	check(int(shipped.get("salesCents", 0)) > 0 and company_cash() == before + int(shipped.get("salesCents", 0)) + bonus, "The bonus is paid once on top of launch sales")
	check(company_reputation() == fans_before + int(shipped.get("fans", 0)), "The bonus does not add fans")
	await snap("23-contract-released", label_named("ReleaseContract"))
	await open_journey()
	var patch := button_named("Patch")
	check(patch != null and not patch.disabled and str(patch.get_meta("cozy_variant", "")) == "secondary", "Patch is available on the contracted product")
	await click(patch)
	await wait_until(func() -> bool: return not main.company_panel.busy and label_named("PatchNotice") != null, "Patch notice names the cost")
	check(label_named("PatchNotice").text.contains("−$100"), "The patch cost line reads −$100")
	check(label_contains("Patched · +1 score"), "The selling card shows the patched state")
	var patched_button := button_named("Patch")
	check(patched_button != null and patched_button.disabled and patched_button.text.contains("Already patched"), "Patch stays disabled after it applies")
	var patched_card: Control = label_named("PatchNotice")
	while patched_card != null and not str(patched_card.name).begins_with("Selling_"):
		patched_card = patched_card.get_parent() as Control
	if patched_card == null:
		patched_card = label_named("PatchNotice")
	await snap("25-patch-applied", patched_card)
	var sequel_button := main.company_panel.find_child("Sequel_p1", true, false) as Button
	check(sequel_button != null and not sequel_button.disabled and sequel_button.text == "Sequel", "Sequel is available on the finished newsletter")
	await click(sequel_button)
	await wait_until(func() -> bool:
		return str(developing().get("name", "")) == "Crypto Alpha Newsletter 2" and int(developing().get("devDaysRequired", 0)) == 1 and not main.company_panel.busy
	, "The sequel starts on a one-day build")
	check(label_named("ProductProgress") != null and label_named("ProductProgress").text == "Building · day 0 of 1", "The build line shows the shorter day")
	check(label_named("SequelBonus") != null and label_named("SequelBonus").text == "Sequel · +1 score", "The build line shows the carried score")
	await snap("27-sequel-started", label_named("ProductProgress"))
	await open_journey()
	var award_button := main.company_panel.find_child("Award_p1", true, false) as Button
	check(award_button != null and not award_button.disabled and award_button.text == "Enter award", "Enter award is available on the finished newsletter")
	var cash_before_award := company_cash()
	var fans_before_award := company_reputation()
	await click(award_button)
	await wait_until(func() -> bool: return not main.company_panel.busy and label_named("AwardResult_p1") != null, "The award result line appears")
	check(label_named("AwardResult_p1").text == "Award · Nominated · +4 fans", "A score of 6 is a nominee with +4 fans")
	var award_again := main.company_panel.find_child("Award_p1", true, false) as Button
	check(award_again != null and award_again.disabled and award_again.text == "Enter award · Already entered.", "A second entry stays disabled")
	check(company_cash() == cash_before_award - 4000, "The award charges $40")
	check(company_reputation() == fans_before_award + 4, "The nominee bonus adds 4 fans once")
	var result_card: Control = label_named("AwardResult_p1")
	while result_card != null and not str(result_card.name).begins_with("Finished_"):
		result_card = result_card.get_parent() as Control
	if result_card == null:
		result_card = label_named("AwardResult_p1")
	await snap("29-award-result", result_card)
	var port_button := main.company_panel.find_child("Port_p1", true, false) as Button
	check(port_button != null and not port_button.disabled and port_button.text == "Port", "Port is available on the finished newsletter")
	var cash_before_port := company_cash()
	var fans_before_port := company_reputation()
	await click(port_button)
	await wait_until(func() -> bool: return not main.company_panel.busy and label_named("PortLine_p1") != null and label_named("PortLine_p1").text == "Port · Whop Mobile · selling 1 day", "The port line says it is selling for one day")
	var port_again := main.company_panel.find_child("Port_p1", true, false) as Button
	check(port_again != null and port_again.disabled and port_again.text == "Port · Already ported.", "A second port stays disabled")
	check(company_cash() == cash_before_port - 8000, "The port charges $80")
	check(company_reputation() == fans_before_port, "The port fee adds no fans")
	await end_office_day()
	await open_journey()
	var port_line := label_named("PortLine_p1")
	check(port_line != null and port_line.text.begins_with("Port · Whop Mobile · $"), "The extra sales day names its cash")
	check(company_reputation() > fans_before_port, "The extra sales day adds fans once")
	var port_card: Control = port_line
	while port_card != null and not str(port_card.name).begins_with("Finished_"):
		port_card = port_card.get_parent() as Control
	if port_card == null:
		port_card = port_line
	await snap("31-port-result", port_card)

func _engine_proof() -> void:
	await open_journey()
	var price := label_named("EnginePrice")
	check(price != null and price.text == "Whop Kit Engine · $120", "The engine card names Whop Kit Engine and $120")
	var buy := main.company_panel.find_child("Buy_engine", true, false) as Button
	check(buy != null and not buy.disabled and str(buy.get_meta("cozy_variant", "")) == "secondary" and buy.text == "Buy Whop Kit Engine · $120", "Buy Whop Kit Engine is an enabled secondary action")
	check(button_named("Hire Mina") != null and str(button_named("Hire Mina").get_meta("cozy_variant", "")) == "primary", "Hire Mina stays the one primary action beside the engine")
	await snap("32-engine-offer", main.company_panel.find_child("EngineCard", true, false) as Control)
	var cash_before := company_cash()
	await click(buy)
	await wait_until(func() -> bool: return not main.company_panel.busy and label_named("EngineNotice") != null and label_named("EngineNotice").text == "Bought Whop Kit Engine. −$120", "Purchase notice names the engine")
	check(company_cash() == cash_before - 12000, "The engine charges $120 once")
	var again := main.company_panel.find_child("Buy_engine", true, false) as Button
	check(again != null and again.disabled and again.text == "Buy Whop Kit Engine · Already owned.", "A second buy stays disabled")
	check(button_named("Hire Mina") != null and str(button_named("Hire Mina").get_meta("cozy_variant", "")) == "primary", "Hire Mina stays primary after the engine is owned")
	var guard := 0
	while not developing().is_empty() and not bool(developing().get("ready", false)) and guard < 4:
		await end_office_day()
		await open_journey()
		guard += 1
	if not developing().is_empty() and bool(developing().get("ready", false)):
		await open_product()
		await click(button_named("Release"))
		await wait_until(func() -> bool: return main.company_panel.screen == "release" and not main.company_panel.busy, "The product on the bench releases")
	await open_product()
	var none := main.company_panel.find_child("Engine_none", true, false) as Button
	var kit := main.company_panel.find_child("Engine_whop_kit", true, false) as Button
	check(none != null and not none.disabled and str(none.get_meta("cozy_variant", "")) == "secondary" and none.text == "None", "None is the default engine")
	check(kit != null and not kit.disabled and str(kit.get_meta("cozy_variant", "")) == "secondary" and kit.text == "Whop Kit Engine", "Whop Kit Engine is a secondary choice")
	check(button_named("Start development") != null and str(button_named("Start development").get_meta("cozy_variant", "")) == "primary", "Start development stays the primary action")
	await click(kit)
	await frames(4)
	check(label_named("EngineEffect") != null and label_named("EngineEffect").text == "Whop Kit Engine · +1 score", "The engine shows +1 score")
	check(label_named("OnTheBuild") != null and label_named("OnTheBuild").text == "On the build · Whop Kit Engine", "The build line names the engine")
	await snap("33-engine-picker", label_named("EngineHeading"))

func _focus_proof() -> void:
	await open_product()
	await click(button_named("Crypto Alpha"))
	await frames(4)
	await click(button_named("Newsletter"))
	await frames(4)
	var none := main.company_panel.find_child("Engine_none", true, false) as Button
	check(none != null and not none.disabled, "None is available before the focus shot")
	await click(none)
	await frames(4)
	var design := main.company_panel.find_child("Focus_design", true, false) as Button
	check(design != null and not design.disabled and str(design.get_meta("cozy_variant", "")) == "secondary" and design.text == "Design", "Design is a secondary focus")
	check(label_named("FocusEffect") != null and label_named("FocusEffect").text == "Balanced · no point bump", "The picker starts on Balanced")
	await click(design)
	await frames(4)
	check(label_named("FocusEffect") != null and label_named("FocusEffect").text == "Design · +1 design", "The focus shows +1 design")
	check(label_named("OnTheBuild") != null and label_named("OnTheBuild").text == "On the build · Design", "The build line names the focus")
	check(button_named("Start development") != null and str(button_named("Start development").get_meta("cozy_variant", "")) == "primary", "Start development stays the primary action")
	await snap("34-focus-picker", label_named("FocusHeading"))
	await click(button_named("Start development"))
	await wait_until(func() -> bool: return developing().get("name", "") == "Crypto Alpha Newsletter" and not main.company_panel.busy, "The focused newsletter starts")
	await open_journey()
	var journey := label_named("FocusJourney")
	check(journey != null and journey.text == "On the build · Design · +1 design", "Journey names the focus")
	check(button_named("Hire Mina") != null and str(button_named("Hire Mina").get_meta("cozy_variant", "")) == "primary", "Hire Mina stays the one primary action beside the focus")
	await snap("35-focus-journey", journey)

func _audience_proof() -> void:
	var guard := 0
	while not developing().is_empty() and not bool(developing().get("ready", false)) and guard < 4:
		await end_office_day()
		await open_journey()
		guard += 1
	if not developing().is_empty() and bool(developing().get("ready", false)):
		await open_product()
		await click(button_named("Release"))
		await wait_until(func() -> bool: return main.company_panel.screen == "release" and not main.company_panel.busy, "The focused product releases before the audience shot")
	await open_product()
	await click(button_named("Crypto Alpha"))
	await frames(4)
	await click(button_named("Newsletter"))
	await frames(4)
	var none := main.company_panel.find_child("Engine_none", true, false) as Button
	if none != null and not none.disabled:
		await click(none)
		await frames(4)
	var balanced := main.company_panel.find_child("Focus_balanced", true, false) as Button
	if balanced != null and not balanced.disabled:
		await click(balanced)
		await frames(4)
	var regulars := main.company_panel.find_child("Audience_regulars", true, false) as Button
	check(regulars != null and not regulars.disabled and str(regulars.get_meta("cozy_variant", "")) == "secondary" and regulars.text == "Regulars", "Regulars is a secondary audience")
	check(label_named("AudienceEffect") != null and label_named("AudienceEffect").text == "Everyone · no fan bump", "The picker starts on Everyone")
	await click(regulars)
	await frames(4)
	check(label_named("AudienceEffect") != null and label_named("AudienceEffect").text == "Regulars · +2 fans on a repeated topic", "The audience shows +2 fans on a repeated topic")
	check(label_named("OnTheBuild") != null and label_named("OnTheBuild").text == "On the build · Regulars", "The build line names the audience")
	check(button_named("Start development") != null and str(button_named("Start development").get_meta("cozy_variant", "")) == "primary", "Start development stays the primary action")
	await snap("36-audience-picker", label_named("AudienceHeading"))
	await click(button_named("Start development"))
	await wait_until(func() -> bool: return developing().get("name", "") == "Crypto Alpha Newsletter" and not main.company_panel.busy, "The Regulars newsletter starts")
	await open_journey()
	var journey := label_named("AudienceJourney")
	check(journey != null and journey.text == "On the build · Regulars", "Journey names the audience")
	check(button_named("Hire Mina") != null and str(button_named("Hire Mina").get_meta("cozy_variant", "")) == "primary", "Hire Mina stays the one primary action beside the audience")
	await snap("37-audience-journey", journey)

func _size_proof() -> void:
	var guard := 0
	while not developing().is_empty() and not bool(developing().get("ready", false)) and guard < 4:
		await end_office_day()
		await open_journey()
		guard += 1
	if not developing().is_empty() and bool(developing().get("ready", false)):
		await open_product()
		await click(button_named("Release"))
		await wait_until(func() -> bool: return main.company_panel.screen == "release" and not main.company_panel.busy, "The audience product releases before the size shot")
	await open_product()
	await click(button_named("Crypto Alpha"))
	await frames(4)
	await click(button_named("Newsletter"))
	await frames(4)
	var none := main.company_panel.find_child("Engine_none", true, false) as Button
	if none != null and not none.disabled:
		await click(none)
		await frames(4)
	var balanced := main.company_panel.find_child("Focus_balanced", true, false) as Button
	if balanced != null and not balanced.disabled:
		await click(balanced)
		await frames(4)
	var everyone := main.company_panel.find_child("Audience_everyone", true, false) as Button
	if everyone != null and not everyone.disabled:
		await click(everyone)
		await frames(4)
	var long_size := main.company_panel.find_child("Size_long", true, false) as Button
	check(long_size != null and not long_size.disabled and str(long_size.get_meta("cozy_variant", "")) == "secondary" and long_size.text == "Long", "Long is a secondary size")
	check(label_named("SizeEffect") != null and label_named("SizeEffect").text == "Catalog · same length", "The picker starts on Catalog")
	await click(long_size)
	await frames(4)
	check(label_named("SizeEffect") != null and label_named("SizeEffect").text == "Long · +1 day · +10% units", "The size shows +1 day and +10% units")
	check(label_named("OnTheBuild") != null and label_named("OnTheBuild").text == "On the build · Long", "The build line names the size")
	check(button_named("Start development") != null and str(button_named("Start development").get_meta("cozy_variant", "")) == "primary", "Start development stays the primary action")
	await snap("38-size-picker", label_named("SizeHeading"))
	await click(button_named("Start development"))
	await wait_until(func() -> bool: return developing().get("name", "") == "Crypto Alpha Newsletter" and not main.company_panel.busy, "The long newsletter starts")
	await open_journey()
	var journey := label_named("SizeJourney")
	check(journey != null and journey.text == "On the build · Long", "Journey names the size")
	check(button_named("Hire Mina") != null and str(button_named("Hire Mina").get_meta("cozy_variant", "")) == "primary", "Hire Mina stays the one primary action beside the size")
	await snap("39-size-journey", journey)

func seed_payroll(data_dir: String) -> bool:
	var database := ProjectSettings.globalize_path("res://../harness/src/database.ts")
	var tsx := ProjectSettings.globalize_path("res://../harness/node_modules/tsx/dist/cli.mjs")
	var node := OS.get_environment("STARTUP_VALLEY_NODE").strip_edges()
	if node.is_empty():
		for dir: String in OS.get_environment("PATH").split(":"):
			if FileAccess.file_exists(dir.path_join("node")):
				node = dir.path_join("node")
				break
	if node.is_empty():
		node = "/home/box/.local/node22/bin/node"
	var script_path := data_dir.path_join("seed-payroll.mjs")
	var script := "import { mkdirSync } from 'node:fs';\nimport { GameDatabase } from %s;\nconst root = process.argv[process.argv.length - 1];\nmkdirSync(root + '/company-project', { recursive: true });\nconst file = root + '/startup-valley.sqlite';\nconst db = new GameDatabase(file, root + '/company-project');\ndb.journey.hire('mira', 1);\ndb.setClock(28, 480, 0);\nconst payroll = db.tycoon.view().payroll;\nconst cash = db.journey.state().company.cashCents;\ndb.close();\nif (cash !== 0 || payroll.cents !== 8000 || payroll.payday !== 'Spring 28') { console.error(JSON.stringify({ cash: cash, payroll: payroll })); process.exit(2); }\n" % JSON.stringify(database)
	var file := FileAccess.open(script_path, FileAccess.WRITE)
	if file == null:
		check(false, "Could not write the payroll seed script")
		return false
	file.store_string(script)
	file.close()
	var output: Array = []
	var code := OS.execute(node, PackedStringArray([tsx, script_path, data_dir]), output, true)
	check(code == 0, "Seeded Mina on Spring 28 with $0 (%s)" % " ".join(output))
	return code == 0

func _payroll_proof() -> void:
	var seeded := OS.get_temp_dir().path_join("startup-valley-proof-payroll-%d-%d" % [OS.get_process_id(), Time.get_ticks_usec()])
	DirAccess.make_dir_recursive_absolute(seeded)
	if not seed_payroll(seeded):
		return
	await release_company()
	OS.set_environment("STARTUP_VALLEY_DATA_DIR", seeded)
	if not await boot_company():
		return
	var continue_button := button_named("Continue")
	if continue_button != null:
		await click(continue_button)
	await dismiss_onboarding()
	await open_journey()
	var line := label_named("SeasonPayroll")
	check(line != null and line.text == "Payroll · $80 on Spring 28", "The Season card names Mina's payday")
	var header := label_named("OfficeDate")
	check(header != null and header.text.contains("Spring 28") and header.text.contains("$0.00"), "Spring 28 still shows $0 before payday")
	check(button_named("Payroll") == null, "Payroll is not a new button")
	await snap("40-payroll-season-card", main.company_panel.find_child("SeasonCard", true, false) as Control)
	await click(button_named("End day"))
	await wait_until(func() -> bool: return main.company_panel.screen == "summary", "Ending Spring 28 opens the summary")
	check(label_contains("Payroll: Spring"), "The summary names the payroll row")
	check(label_named("PayrollNotice") != null and label_named("PayrollNotice").text == "Paid payroll · −$80", "The payday notice names the amount")
	await click(button_named("Begin next day"))
	await wait_until(func() -> bool: return not main.company_panel.visible, "Begin next day returns to the office")
	main.day_clock.set_speed(0)
	await open_journey()
	header = label_named("OfficeDate")
	check(header != null and header.text.contains("cash is negative") and header.text.contains("−$80.00"), "The header says cash is negative")
	check(label_named("SeasonPayroll") != null and label_named("SeasonPayroll").text == "Payroll · $80 on Summer 28", "The next payday is Summer 28")
	check(label_named("PayrollNotice") != null and label_named("PayrollNotice").text == "Paid payroll · −$80", "The paid notice stays on the Season card")
	check(label_named("CashNegative") != null, "The Season card says cash is negative")
	await snap("41-payroll-paid", main.company_panel.find_child("SeasonCard", true, false) as Control)

func seed_loan_offer(data_dir: String) -> bool:
	var database := ProjectSettings.globalize_path("res://../harness/src/database.ts")
	var tsx := ProjectSettings.globalize_path("res://../harness/node_modules/tsx/dist/cli.mjs")
	var node := OS.get_environment("STARTUP_VALLEY_NODE").strip_edges()
	if node.is_empty():
		for dir: String in OS.get_environment("PATH").split(":"):
			if FileAccess.file_exists(dir.path_join("node")):
				node = dir.path_join("node")
				break
	if node.is_empty():
		node = "/home/box/.local/node22/bin/node"
	var script_path := data_dir.path_join("seed-loan.mjs")
	var script := "import { mkdirSync } from 'node:fs';\nimport { GameDatabase } from %s;\nconst root = process.argv[process.argv.length - 1];\nmkdirSync(root + '/company-project', { recursive: true });\nconst file = root + '/startup-valley.sqlite';\nconst db = new GameDatabase(file, root + '/company-project');\nconst loan = db.tycoon.view().loan;\nconst cash = db.journey.state().company.cashCents;\ndb.close();\nif (cash !== 0 || loan.outstanding || loan.amountCents !== 50000 || loan.due !== 'Spring 28') { console.error(JSON.stringify({ cash: cash, loan: loan })); process.exit(2); }\n" % JSON.stringify(database)
	var file := FileAccess.open(script_path, FileAccess.WRITE)
	if file == null:
		check(false, "Could not write the loan seed script")
		return false
	file.store_string(script)
	file.close()
	var output: Array = []
	var code := OS.execute(node, PackedStringArray([tsx, script_path, data_dir]), output, true)
	check(code == 0, "Seeded a fresh company with a loan offer (%s)" % " ".join(output))
	return code == 0

func _loan_proof() -> void:
	var seeded := OS.get_temp_dir().path_join("startup-valley-proof-loan-%d-%d" % [OS.get_process_id(), Time.get_ticks_usec()])
	DirAccess.make_dir_recursive_absolute(seeded)
	if not seed_loan_offer(seeded):
		return
	await release_company()
	OS.set_environment("STARTUP_VALLEY_DATA_DIR", seeded)
	if not await boot_company():
		return
	var enter := button_named("Continue")
	if enter == null:
		enter = button_named("Start company")
	if enter != null:
		await click(enter)
	await dismiss_onboarding()
	await open_journey()
	var line := label_named("SeasonLoan")
	check(line != null and line.text == "Loan · $500, repay $550 on Spring 28", "The Season card names the loan offer")
	var take := button_named("Take loan")
	check(take != null and not take.disabled and str(take.get_meta("cozy_variant", "")) == "secondary", "Take loan is a secondary action")
	check(button_named("Hire Mina") != null and str(button_named("Hire Mina").get_meta("cozy_variant", "")) == "primary", "Hire Mina stays the one primary action beside the loan")
	var header := label_named("OfficeDate")
	check(header != null and header.text.contains("$0.00"), "The offer still shows $0")
	await snap("42-loan-offer", main.company_panel.find_child("SeasonCard", true, false) as Control)
	await click(take)
	await wait_until(func() -> bool: return company_cash() == 50000 and not main.company_panel.busy, "Taking the loan adds $500")
	check(label_named("SeasonLoan") != null and label_named("SeasonLoan").text == "Loan due · $550 on Spring 28", "The Season card names the due loan")
	check(button_named("Take loan") == null, "The take button hides while a loan is out")
	header = label_named("OfficeDate")
	check(header != null and header.text.contains("$500.00"), "The header shows the loan cash")
	await snap("43-loan-taken", main.company_panel.find_child("SeasonCard", true, false) as Control)

func seed_publisher_offer(data_dir: String) -> bool:
	var database := ProjectSettings.globalize_path("res://../harness/src/database.ts")
	var tsx := ProjectSettings.globalize_path("res://../harness/node_modules/tsx/dist/cli.mjs")
	var node := OS.get_environment("STARTUP_VALLEY_NODE").strip_edges()
	if node.is_empty():
		for dir: String in OS.get_environment("PATH").split(":"):
			if FileAccess.file_exists(dir.path_join("node")):
				node = dir.path_join("node")
				break
	if node.is_empty():
		node = "/home/box/.local/node22/bin/node"
	var script_path := data_dir.path_join("seed-publisher.mjs")
	var script := "import { mkdirSync } from 'node:fs';\nimport { GameDatabase } from %s;\nconst root = process.argv[process.argv.length - 1];\nmkdirSync(root + '/company-project', { recursive: true });\nconst file = root + '/startup-valley.sqlite';\nconst db = new GameDatabase(file, root + '/company-project');\ndb.tycoon.start('crypto', 'newsletter', []);\nconst view = db.tycoon.view().developing;\nconst cash = db.journey.state().company.cashCents;\ndb.close();\nconst offer = view && view.publisher;\nif (cash !== 0 || !offer || offer.signed || offer.name !== 'Creator Collective' || offer.advanceCents !== 15000 || offer.cutPercent !== 30) { console.error(JSON.stringify({ cash: cash, view: view })); process.exit(2); }\n" % JSON.stringify(database)
	var file := FileAccess.open(script_path, FileAccess.WRITE)
	if file == null:
		check(false, "Could not write the publisher seed script")
		return false
	file.store_string(script)
	file.close()
	var output: Array = []
	var code := OS.execute(node, PackedStringArray([tsx, script_path, data_dir]), output, true)
	check(code == 0, "Seeded a developing newsletter with a publisher offer (%s)" % " ".join(output))
	return code == 0

func _publisher_proof() -> void:
	var seeded := OS.get_temp_dir().path_join("startup-valley-proof-publisher-%d-%d" % [OS.get_process_id(), Time.get_ticks_usec()])
	DirAccess.make_dir_recursive_absolute(seeded)
	if not seed_publisher_offer(seeded):
		return
	await release_company()
	OS.set_environment("STARTUP_VALLEY_DATA_DIR", seeded)
	if not await boot_company():
		return
	var enter := button_named("Continue")
	if enter == null:
		enter = button_named("Start company")
	if enter != null:
		await click(enter)
	await dismiss_onboarding()
	await open_journey()
	var line := label_named("PublisherOffer")
	check(line != null and line.text == "Publisher · Creator Collective pays $150 now, takes 30% of sales", "The journey card names the publisher offer")
	var sign := button_named("Sign publisher")
	check(sign != null and not sign.disabled and str(sign.get_meta("cozy_variant", "")) == "secondary", "Sign publisher is a secondary action")
	check(button_named("Hire Mina") != null and str(button_named("Hire Mina").get_meta("cozy_variant", "")) == "primary", "Hire Mina stays the one primary action beside the publisher")
	var header := label_named("OfficeDate")
	check(header != null and header.text.contains("$0.00"), "The offer still shows $0")
	await snap("44-publisher-offer", main.company_panel.find_child("PublisherCard", true, false) as Control)
	await click(sign)
	await wait_until(func() -> bool: return company_cash() == 15000 and not main.company_panel.busy, "Signing the publisher adds $150")
	check(label_named("PublisherOffer") != null and label_named("PublisherOffer").text == "Published by Creator Collective · 30% cut", "The card names the signed publisher")
	check(button_named("Sign publisher") == null, "The sign button hides after the deal")
	header = label_named("OfficeDate")
	check(header != null and header.text.contains("$150.00"), "The header shows the publisher cash")
	await snap("45-publisher-signed", main.company_panel.find_child("PublisherCard", true, false) as Control)

func seed_expo_offer(data_dir: String) -> bool:
	var database := ProjectSettings.globalize_path("res://../harness/src/database.ts")
	var tsx := ProjectSettings.globalize_path("res://../harness/node_modules/tsx/dist/cli.mjs")
	var node := OS.get_environment("STARTUP_VALLEY_NODE").strip_edges()
	if node.is_empty():
		for dir: String in OS.get_environment("PATH").split(":"):
			if FileAccess.file_exists(dir.path_join("node")):
				node = dir.path_join("node")
				break
	if node.is_empty():
		node = "/home/box/.local/node22/bin/node"
	var script_path := data_dir.path_join("seed-expo.mjs")
	var script := "import { mkdirSync } from 'node:fs';\nimport { GameDatabase } from %s;\nconst root = process.argv[process.argv.length - 1];\nmkdirSync(root + '/company-project', { recursive: true });\nconst file = root + '/startup-valley.sqlite';\nconst db = new GameDatabase(file, root + '/company-project');\ndb.journey.recordCompanyChange('seed:expo-cash', 1, 20700, 0, 0, 'Seed cash');\nconst expo = db.tycoon.view().expo;\nconst company = db.journey.state().company;\ndb.close();\nif (company.cashCents !== 20700 || company.earnedCents !== 0 || company.reputation !== 0 || expo.booked || expo.name !== 'Whop Creator Fair' || expo.when !== 'Spring 14' || expo.costCents !== 6000 || expo.fans !== 3) { console.error(JSON.stringify({ company: company, expo: expo })); process.exit(2); }\n" % JSON.stringify(database)
	var file := FileAccess.open(script_path, FileAccess.WRITE)
	if file == null:
		check(false, "Could not write the expo seed script")
		return false
	file.store_string(script)
	file.close()
	var output: Array = []
	var code := OS.execute(node, PackedStringArray([tsx, script_path, data_dir]), output, true)
	check(code == 0, "Seeded a company with $207 and an expo offer (%s)" % " ".join(output))
	return code == 0

func _expo_proof() -> void:
	var seeded := OS.get_temp_dir().path_join("startup-valley-proof-expo-%d-%d" % [OS.get_process_id(), Time.get_ticks_usec()])
	DirAccess.make_dir_recursive_absolute(seeded)
	if not seed_expo_offer(seeded):
		return
	await release_company()
	OS.set_environment("STARTUP_VALLEY_DATA_DIR", seeded)
	if not await boot_company():
		return
	var enter := button_named("Continue")
	if enter == null:
		enter = button_named("Start company")
	if enter != null:
		await click(enter)
	await dismiss_onboarding()
	await open_journey()
	var line := label_named("SeasonExpo")
	check(line != null and line.text == "Expo · Whop Creator Fair on Spring 14 · $60 booth, about 3 fans", "The Season card names the expo offer")
	var book := button_named("Book booth")
	check(book != null and not book.disabled and str(book.get_meta("cozy_variant", "")) == "secondary", "Book booth is a secondary action")
	check(button_named("Hire Mina") != null and str(button_named("Hire Mina").get_meta("cozy_variant", "")) == "primary", "Hire Mina stays the one primary action beside the booth")
	var header := label_named("OfficeDate")
	check(header != null and header.text.contains("$207.00"), "The offer still shows $207")
	await snap("46-expo-offer", main.company_panel.find_child("SeasonCard", true, false) as Control)
	await click(book)
	await wait_until(func() -> bool: return company_cash() == 14700 and not main.company_panel.busy, "Booking the booth charges $60")
	check(label_named("SeasonExpo") != null and label_named("SeasonExpo").text == "Booth booked · Whop Creator Fair on Spring 14", "The Season card names the booked booth")
	check(button_named("Book booth") == null, "The book button hides once the booth is booked")
	header = label_named("OfficeDate")
	check(header != null and header.text.contains("$147.00"), "The header shows the cash after the fee")
	await snap("47-expo-booked", main.company_panel.find_child("SeasonCard", true, false) as Control)

func seed_localize_offer(data_dir: String) -> bool:
	var database := ProjectSettings.globalize_path("res://../harness/src/database.ts")
	var tsx := ProjectSettings.globalize_path("res://../harness/node_modules/tsx/dist/cli.mjs")
	var node := OS.get_environment("STARTUP_VALLEY_NODE").strip_edges()
	if node.is_empty():
		for dir: String in OS.get_environment("PATH").split(":"):
			if FileAccess.file_exists(dir.path_join("node")):
				node = dir.path_join("node")
				break
	if node.is_empty():
		node = "/home/box/.local/node22/bin/node"
	var script_path := data_dir.path_join("seed-localize.mjs")
	var script := "import { mkdirSync } from 'node:fs';\nimport { GameDatabase } from " + JSON.stringify(database) + ";\nconst root = process.argv[process.argv.length - 1];\nmkdirSync(root + '/company-project', { recursive: true });\nconst db = new GameDatabase(root + '/startup-valley.sqlite', root + '/company-project');\ndb.tycoon.start('crypto', 'newsletter', []);\ndb.endDay(1);\ndb.endDay(2);\ndb.tycoon.release('p1');\ndb.endDay(3);\ndb.endDay(4);\ndb.endDay(5);\ndb.endDay(6);\ndb.setClock(7, 480, 0);\nconst offer = db.tycoon.view().history[0].localization;\nconst company = db.journey.state().company;\ndb.close();\nif (company.cashCents < 5000 || offer.phase !== '' || offer.enabled !== true || offer.edition !== 'Spanish edition' || offer.costCents !== 5000) { console.error(JSON.stringify({ company: company, offer: offer })); process.exit(2); }\n"
	var file := FileAccess.open(script_path, FileAccess.WRITE)
	if file == null:
		check(false, "Could not write the localization seed script")
		return false
	file.store_string(script)
	file.close()
	var output: Array = []
	var code := OS.execute(node, PackedStringArray([tsx, script_path, data_dir]), output, true)
	check(code == 0, "Seeded a finished newsletter with a translation offer (%s)" % " ".join(output))
	return code == 0

func _localize_proof() -> void:
	var seeded := OS.get_temp_dir().path_join("startup-valley-proof-localize-%d-%d" % [OS.get_process_id(), Time.get_ticks_usec()])
	DirAccess.make_dir_recursive_absolute(seeded)
	if not seed_localize_offer(seeded):
		return
	await release_company()
	OS.set_environment("STARTUP_VALLEY_DATA_DIR", seeded)
	if not await boot_company():
		return
	var enter := button_named("Continue")
	if enter == null:
		enter = button_named("Start company")
	if enter != null:
		await click(enter)
	await dismiss_onboarding()
	await open_journey()
	var line := label_named("LocalizeOffer_p1")
	check(line != null and line.text == "Translate · Spanish edition · $50, one extra sales day", "The shipped card names the translation offer")
	var translate := button_named("Translate")
	check(translate != null and not translate.disabled and str(translate.get_meta("cozy_variant", "")) == "secondary" and translate.text == "Translate", "Translate is a secondary action")
	check(button_named("Hire Mina") != null and str(button_named("Hire Mina").get_meta("cozy_variant", "")) == "primary", "Hire Mina stays the one primary action beside Translate")
	var before := company_cash()
	var header := label_named("OfficeDate")
	check(header != null and header.text.contains("$%s" % _proof_money(before)), "The offer header shows the cash before the fee")
	await snap("48-localize-offer", line)
	await click(translate)
	await wait_until(func() -> bool: return company_cash() == before - 5000 and not main.company_panel.busy, "Translating charges $50")
	check(label_named("LocalizeLine_p1") != null and label_named("LocalizeLine_p1").text == "Spanish edition · one extra sales day", "The shipped card names the bought translation")
	check(button_named("Translate") == null, "The translate button hides after the fee")
	check(label_named("LocalizeOffer_p1") == null, "The offer line hides after the fee")
	header = label_named("OfficeDate")
	check(header != null and header.text.contains("$%s" % _proof_money(before - 5000)), "The header shows the cash after the fee")
	await snap("49-localize-bought", label_named("LocalizeLine_p1"))

func seed_town_day_offer(data_dir: String) -> bool:
	var database := ProjectSettings.globalize_path("res://../harness/src/database.ts")
	var tsx := ProjectSettings.globalize_path("res://../harness/node_modules/tsx/dist/cli.mjs")
	var node := OS.get_environment("STARTUP_VALLEY_NODE").strip_edges()
	if node.is_empty():
		for dir: String in OS.get_environment("PATH").split(":"):
			if FileAccess.file_exists(dir.path_join("node")):
				node = dir.path_join("node")
				break
	if node.is_empty():
		node = "/home/box/.local/node22/bin/node"
	var script_path := data_dir.path_join("seed-town.mjs")
	var script := "import { mkdirSync } from 'node:fs';\nimport { GameDatabase } from %s;\nconst root = process.argv[process.argv.length - 1];\nmkdirSync(root + '/company-project', { recursive: true });\nconst file = root + '/startup-valley.sqlite';\nconst db = new GameDatabase(file, root + '/company-project');\ndb.journey.recordCompanyChange('seed:town-cash', 1, 20700, 0, 0, 'Seed cash');\nconst town = db.tycoon.view().townDay;\nconst company = db.journey.state().company;\ndb.close();\nif (company.cashCents !== 20700 || company.earnedCents !== 0 || company.reputation !== 0 || town.taken || town.name !== 'Whop Block Picnic' || town.season !== 'Spring' || town.costCents !== 2000 || town.fans !== 2) { console.error(JSON.stringify({ company: company, town: town })); process.exit(2); }\n" % JSON.stringify(database)
	var file := FileAccess.open(script_path, FileAccess.WRITE)
	if file == null:
		check(false, "Could not write the town day seed script")
		return false
	file.store_string(script)
	file.close()
	var output: Array = []
	var code := OS.execute(node, PackedStringArray([tsx, script_path, data_dir]), output, true)
	check(code == 0, "Seeded a company with $207 and a town day offer (%s)" % " ".join(output))
	return code == 0

func _town_day_proof() -> void:
	var seeded := OS.get_temp_dir().path_join("startup-valley-proof-town-%d-%d" % [OS.get_process_id(), Time.get_ticks_usec()])
	DirAccess.make_dir_recursive_absolute(seeded)
	if not seed_town_day_offer(seeded):
		return
	await release_company()
	OS.set_environment("STARTUP_VALLEY_DATA_DIR", seeded)
	if not await boot_company():
		return
	var enter := button_named("Continue")
	if enter == null:
		enter = button_named("Start company")
	if enter != null:
		await click(enter)
	await dismiss_onboarding()
	await open_journey()
	var line := label_named("SeasonTown")
	check(line != null and line.text == "Town · Whop Block Picnic this Spring · $20, about 2 fans", "The Season card names the town day offer")
	var take := button_named("Take the afternoon")
	check(take != null and not take.disabled and str(take.get_meta("cozy_variant", "")) == "secondary", "Take the afternoon is a secondary action")
	check(button_named("Hire Mina") != null and str(button_named("Hire Mina").get_meta("cozy_variant", "")) == "primary", "Hire Mina stays the one primary action beside the picnic")
	var header := label_named("OfficeDate")
	check(header != null and header.text.contains("$207.00") and header.text.contains("0 reputation"), "The offer still shows $207 and 0 reputation")
	await snap("50-townday-offer", line)
	await click(take)
	await wait_until(func() -> bool: return company_cash() == 18700 and company_reputation() == 2 and not main.company_panel.busy, "The picnic charges $20 and grants 2 fans")
	check(label_named("SeasonTown") != null and label_named("SeasonTown").text == "Afternoon off · Whop Block Picnic", "The Season card names the afternoon off")
	check(button_named("Take the afternoon") == null, "The afternoon button hides once the picnic is taken")
	header = label_named("OfficeDate")
	check(header != null and header.text.contains("$187.00") and header.text.contains("2 reputation"), "The header shows the cash and fans after the picnic")
	await snap("51-townday-taken", label_named("SeasonTown"))

func seed_press_demo_offer(data_dir: String) -> bool:
	var database := ProjectSettings.globalize_path("res://../harness/src/database.ts")
	var tsx := ProjectSettings.globalize_path("res://../harness/node_modules/tsx/dist/cli.mjs")
	var node := OS.get_environment("STARTUP_VALLEY_NODE").strip_edges()
	if node.is_empty():
		for dir: String in OS.get_environment("PATH").split(":"):
			if FileAccess.file_exists(dir.path_join("node")):
				node = dir.path_join("node")
				break
	if node.is_empty():
		node = "/home/box/.local/node22/bin/node"
	var script_path := data_dir.path_join("seed-press.mjs")
	var script := "import { mkdirSync } from 'node:fs';\nimport { GameDatabase } from %s;\nconst root = process.argv[process.argv.length - 1];\nmkdirSync(root + '/company-project', { recursive: true });\nconst file = root + '/startup-valley.sqlite';\nconst db = new GameDatabase(file, root + '/company-project');\ndb.journey.recordCompanyChange('seed:press-cash', 1, 20700, 0, 0, 'Seed cash');\ndb.tycoon.start('crypto', 'newsletter', []);\nconst view = db.tycoon.view().developing;\nconst company = db.journey.state().company;\ndb.close();\nconst offer = view && view.pressDemo;\nif (company.cashCents !== 20700 || company.earnedCents !== 0 || company.reputation !== 0 || !offer || offer.shown || offer.name !== 'Whop Weekly Preview' || offer.costCents !== 3000 || offer.fans !== 4) { console.error(JSON.stringify({ company: company, view: view })); process.exit(2); }\n" % JSON.stringify(database)
	var file := FileAccess.open(script_path, FileAccess.WRITE)
	if file == null:
		check(false, "Could not write the press demo seed script")
		return false
	file.store_string(script)
	file.close()
	var output: Array = []
	var code := OS.execute(node, PackedStringArray([tsx, script_path, data_dir]), output, true)
	check(code == 0, "Seeded a developing newsletter with $207 and a press demo offer (%s)" % " ".join(output))
	return code == 0

func _press_demo_proof() -> void:
	var seeded := OS.get_temp_dir().path_join("startup-valley-proof-press-%d-%d" % [OS.get_process_id(), Time.get_ticks_usec()])
	DirAccess.make_dir_recursive_absolute(seeded)
	if not seed_press_demo_offer(seeded):
		return
	await release_company()
	OS.set_environment("STARTUP_VALLEY_DATA_DIR", seeded)
	if not await boot_company():
		return
	var enter := button_named("Continue")
	if enter == null:
		enter = button_named("Start company")
	if enter != null:
		await click(enter)
	await dismiss_onboarding()
	await open_journey()
	var line := label_named("PressDemoOffer")
	check(line != null and line.text == "Press demo · Whop Weekly Preview · $30, about 4 fans", "The journey card names the press demo offer")
	var show := button_named("Show preview")
	check(show != null and not show.disabled and str(show.get_meta("cozy_variant", "")) == "secondary", "Show preview is a secondary action")
	check(button_named("Hire Mina") != null and str(button_named("Hire Mina").get_meta("cozy_variant", "")) == "primary", "Hire Mina stays the one primary action beside the preview")
	var header := label_named("OfficeDate")
	check(header != null and header.text.contains("$207.00") and header.text.contains("0 reputation"), "The offer still shows $207 and 0 reputation")
	await snap("52-pressdemo-offer", line)
	await click(show)
	await wait_until(func() -> bool: return company_cash() == 17700 and company_reputation() == 4 and not main.company_panel.busy, "The preview charges $30 and grants 4 fans")
	check(label_named("PressDemoOffer") != null and label_named("PressDemoOffer").text == "Preview shown · Whop Weekly Preview", "The card names the shown preview")
	check(button_named("Show preview") == null, "The preview button hides once it is shown")
	header = label_named("OfficeDate")
	check(header != null and header.text.contains("$177.00") and header.text.contains("4 reputation"), "The header shows the cash and fans after the preview")
	await snap("53-pressdemo-taken", label_named("PressDemoOffer"))

func seed_trailer_offer(data_dir: String) -> bool:
	var database := ProjectSettings.globalize_path("res://../harness/src/database.ts")
	var tsx := ProjectSettings.globalize_path("res://../harness/node_modules/tsx/dist/cli.mjs")
	var node := OS.get_environment("STARTUP_VALLEY_NODE").strip_edges()
	if node.is_empty():
		for dir: String in OS.get_environment("PATH").split(":"):
			if FileAccess.file_exists(dir.path_join("node")):
				node = dir.path_join("node")
				break
	if node.is_empty():
		node = "/home/box/.local/node22/bin/node"
	var script_path := data_dir.path_join("seed-trailer.mjs")
	var script := "import { mkdirSync } from 'node:fs';\nimport { GameDatabase } from %s;\nconst root = process.argv[process.argv.length - 1];\nmkdirSync(root + '/company-project', { recursive: true });\nconst file = root + '/startup-valley.sqlite';\nconst db = new GameDatabase(file, root + '/company-project');\ndb.tycoon.start('crypto', 'newsletter', []);\ndb.endDay(1);\ndb.endDay(2);\ndb.tycoon.release('p1');\nconst product = db.tycoon.view().history[0];\nconst company = db.journey.state().company;\ndb.close();\nconst offer = product && product.trailer;\nif (company.cashCents !== 20700 || company.reputation !== 5 || !product || product.status !== 'released' || product.salesCents !== 20700 || product.fans !== 5 || !offer || offer.made || offer.name !== 'Whop Creator Cut' || offer.costCents !== 2500 || offer.fans !== 6) { console.error(JSON.stringify({ company: company, product: product })); process.exit(2); }\n" % JSON.stringify(database)
	var file := FileAccess.open(script_path, FileAccess.WRITE)
	if file == null:
		check(false, "Could not write the trailer seed script")
		return false
	file.store_string(script)
	file.close()
	var output: Array = []
	var code := OS.execute(node, PackedStringArray([tsx, script_path, data_dir]), output, true)
	check(code == 0, "Seeded a selling newsletter at $207 with a trailer offer (%s)" % " ".join(output))
	return code == 0

func _trailer_proof() -> void:
	var seeded := OS.get_temp_dir().path_join("startup-valley-proof-trailer-%d-%d" % [OS.get_process_id(), Time.get_ticks_usec()])
	DirAccess.make_dir_recursive_absolute(seeded)
	if not seed_trailer_offer(seeded):
		return
	await release_company()
	OS.set_environment("STARTUP_VALLEY_DATA_DIR", seeded)
	if not await boot_company():
		return
	var enter := button_named("Continue")
	if enter == null:
		enter = button_named("Start company")
	if enter != null:
		await click(enter)
	await dismiss_onboarding()
	await open_journey()
	var line := label_named("TrailerOffer_p1")
	check(line != null and line.text == "Trailer · Whop Creator Cut · $25, about 6 fans", "The Selling card names the trailer offer")
	var make := button_named("Make trailer")
	check(make != null and not make.disabled and str(make.get_meta("cozy_variant", "")) == "secondary", "Make trailer is a secondary action")
	check(button_named("Hire Mina") != null and str(button_named("Hire Mina").get_meta("cozy_variant", "")) == "primary", "Hire Mina stays the one primary action beside the trailer")
	var header := label_named("OfficeDate")
	check(header != null and header.text.contains("Spring 3") and header.text.contains("$207.00") and header.text.contains("5 reputation"), "The offer still shows Spring 3, $207, and 5 reputation")
	await snap("54-trailer-offer", line)
	await click(make)
	await wait_until(func() -> bool: return company_cash() == 18200 and company_reputation() == 11 and not main.company_panel.busy, "The trailer charges $25 and grants 6 fans")
	check(label_named("TrailerOffer_p1") != null and label_named("TrailerOffer_p1").text == "Trailer made · Whop Creator Cut", "The Selling card names the made trailer")
	check(button_named("Make trailer") == null, "The trailer button hides once it is made")
	header = label_named("OfficeDate")
	check(header != null and header.text.contains("Spring 3") and header.text.contains("$182.00") and header.text.contains("11 reputation"), "The header shows the cash and fans after the trailer")
	await snap("55-trailer-made", label_named("TrailerOffer_p1"))

func seed_diary_offer(data_dir: String) -> bool:
	var database := ProjectSettings.globalize_path("res://../harness/src/database.ts")
	var tsx := ProjectSettings.globalize_path("res://../harness/node_modules/tsx/dist/cli.mjs")
	var node := OS.get_environment("STARTUP_VALLEY_NODE").strip_edges()
	if node.is_empty():
		for dir: String in OS.get_environment("PATH").split(":"):
			if FileAccess.file_exists(dir.path_join("node")):
				node = dir.path_join("node")
				break
	if node.is_empty():
		node = "/home/box/.local/node22/bin/node"
	var script_path := data_dir.path_join("seed-diary.mjs")
	var script := "import { mkdirSync } from 'node:fs';\nimport { GameDatabase } from %s;\nconst root = process.argv[process.argv.length - 1];\nmkdirSync(root + '/company-project', { recursive: true });\nconst file = root + '/startup-valley.sqlite';\nconst db = new GameDatabase(file, root + '/company-project');\ndb.tycoon.start('crypto', 'newsletter', []);\ndb.endDay(1);\ndb.endDay(2);\ndb.tycoon.release('p1');\ndb.endDay(3);\ndb.endDay(4);\ndb.endDay(5);\ndb.endDay(6);\ndb.setClock(7, 480, 0);\nconst product = db.tycoon.view().history[0];\nconst company = db.journey.state().company;\ndb.close();\nconst offer = product && product.diary;\nif (company.cashCents !== 46800 || company.reputation !== 11 || !product || product.status !== 'complete' || product.salesCents !== 46800 || product.fans !== 11 || !offer || offer.written || offer.name !== 'Whop Post-Mortem' || offer.costCents !== 1500 || offer.fans !== 1) { console.error(JSON.stringify({ company: company, product: product })); process.exit(2); }\n" % JSON.stringify(database)
	var file := FileAccess.open(script_path, FileAccess.WRITE)
	if file == null:
		check(false, "Could not write the diary seed script")
		return false
	file.store_string(script)
	file.close()
	var output: Array = []
	var code := OS.execute(node, PackedStringArray([tsx, script_path, data_dir]), output, true)
	check(code == 0, "Seeded a finished newsletter at $468 with a diary offer (%s)" % " ".join(output))
	return code == 0

func _diary_proof() -> void:
	var seeded := OS.get_temp_dir().path_join("startup-valley-proof-diary-%d-%d" % [OS.get_process_id(), Time.get_ticks_usec()])
	DirAccess.make_dir_recursive_absolute(seeded)
	if not seed_diary_offer(seeded):
		return
	await release_company()
	OS.set_environment("STARTUP_VALLEY_DATA_DIR", seeded)
	if not await boot_company():
		return
	var enter := button_named("Continue")
	if enter == null:
		enter = button_named("Start company")
	if enter != null:
		await click(enter)
	await dismiss_onboarding()
	await open_journey()
	var finished := main.company_panel.find_child("Finished_p1", true, false) as Control
	var line := label_named("DiaryOffer_p1")
	check(finished != null and line != null and finished.is_ancestor_of(line) and line.text == "Diary · Whop Post-Mortem · $15, about 1 fan", "The Shipped card names the diary offer")
	var write := button_named("Write diary")
	check(write != null and not write.disabled and str(write.get_meta("cozy_variant", "")) == "secondary", "Write diary is a secondary action")
	var shelf := main.company_panel.find_child("ShelfActions_p1", true, false)
	check(write != null and shelf != null and not shelf.is_ancestor_of(write), "Write diary sits off the four-button shelf row")
	check(button_named("Hire Mina") != null and str(button_named("Hire Mina").get_meta("cozy_variant", "")) == "primary", "Hire Mina stays the one primary action beside the diary")
	var header := label_named("OfficeDate")
	check(header != null and header.text.contains("Spring 7") and header.text.contains("$468.00") and header.text.contains("11 reputation"), "The offer still shows Spring 7, $468, and 11 reputation")
	await snap("56-diary-offer", finished)
	await click(write)
	await wait_until(func() -> bool: return company_cash() == 45300 and company_reputation() == 12 and not main.company_panel.busy, "The diary charges $15 and grants 1 fan")
	check(label_named("DiaryOffer_p1") != null and label_named("DiaryOffer_p1").text == "Diary written · Whop Post-Mortem", "The Shipped card names the written diary")
	check(button_named("Write diary") == null, "The diary button hides once it is written")
	header = label_named("OfficeDate")
	check(header != null and header.text.contains("Spring 7") and header.text.contains("$453.00") and header.text.contains("12 reputation"), "The header shows the cash and fans after the diary")
	finished = main.company_panel.find_child("Finished_p1", true, false) as Control
	await snap("57-diary-written", finished)

func _rival_proof() -> void:
	await open_journey()
	var card := main.company_panel.find_child("SeasonCard", true, false) as Control
	var line := label_named("SeasonRival")
	check(card != null and line != null and card.is_ancestor_of(line) and line.text == "Rival: Pip's Pop-up is pushing Cooking this season", "The Season card names the spring rival")
	check(label_named("SeasonTopics") != null and label_named("SeasonTopics").text == "In season: Fitness, Dating Advice", "The rival line leaves the season topics alone")
	var hire := button_named("Hire Mina")
	check(hire != null and str(hire.get_meta("cozy_variant", "")) == "primary", "Hire Mina stays the one primary action beside the rival")
	await snap("58-rival-season", card)
	await open_product()
	check(label_named("RivalWarning") == null, "Fitness shows no rival warning")
	var cooking := button_named("Cooking")
	check(cooking != null and cooking.text == "Cooking", "Cooking stays a plain topic button")
	await click(cooking)
	var warning := label_named("RivalWarning")
	check(warning != null and warning.text == "Rival · opening demand drops.", "Cooking shows the rival warning")
	await reveal(warning)
	main.company_panel._scroll.scroll_vertical = maxi(0, main.company_panel._scroll.scroll_vertical - 220)
	await frames(3)
	await snap("59-rival-picker")

func seed_feature_offer(data_dir: String) -> bool:
	var database := ProjectSettings.globalize_path("res://../harness/src/database.ts")
	var tsx := ProjectSettings.globalize_path("res://../harness/node_modules/tsx/dist/cli.mjs")
	var node := OS.get_environment("STARTUP_VALLEY_NODE").strip_edges()
	if node.is_empty():
		for dir: String in OS.get_environment("PATH").split(":"):
			if FileAccess.file_exists(dir.path_join("node")):
				node = dir.path_join("node")
				break
	if node.is_empty():
		node = "/home/box/.local/node22/bin/node"
	var script_path := data_dir.path_join("seed-feature.mjs")
	var script := "import { mkdirSync } from 'node:fs';\nimport { GameDatabase } from %s;\nconst root = process.argv[process.argv.length - 1];\nmkdirSync(root + '/company-project', { recursive: true });\nconst db = new GameDatabase(root + '/startup-valley.sqlite', root + '/company-project');\ndb.tycoon.start('crypto', 'newsletter', []);\nconst view = db.tycoon.view().developing;\nconst company = db.journey.state().company;\ndb.close();\nconst offer = view && view.feature;\nif (company.cashCents !== 0 || company.reputation !== 0 || !offer || offer.added || offer.name !== 'Whop Bonus Drop' || offer.dayDelta !== 1 || offer.unitPercent !== 110 || view.devDaysRequired !== 2 || view.devDays !== 0) { console.error(JSON.stringify({ company: company, view: view })); process.exit(2); }\n" % JSON.stringify(database)
	var file := FileAccess.open(script_path, FileAccess.WRITE)
	if file == null:
		check(false, "Could not write the feature seed script")
		return false
	file.store_string(script)
	file.close()
	var output: Array = []
	var code := OS.execute(node, PackedStringArray([tsx, script_path, data_dir]), output, true)
	check(code == 0, "Seeded a developing newsletter with the feature offer (%s)" % " ".join(output))
	return code == 0

func _feature_proof() -> void:
	var seeded := OS.get_temp_dir().path_join("startup-valley-proof-feature-%d-%d" % [OS.get_process_id(), Time.get_ticks_usec()])
	DirAccess.make_dir_recursive_absolute(seeded)
	if not seed_feature_offer(seeded):
		return
	await release_company()
	OS.set_environment("STARTUP_VALLEY_DATA_DIR", seeded)
	if not await boot_company():
		return
	var enter := button_named("Continue")
	if enter == null:
		enter = button_named("Start company")
	if enter != null:
		await click(enter)
	await dismiss_onboarding()
	await open_journey()
	var line := label_named("FeatureOffer")
	var card := main.company_panel.find_child("PublisherCard", true, false) as Control
	check(card != null and line != null and card.is_ancestor_of(line) and line.text == "Feature · Whop Bonus Drop · +1 office day, +10% opening demand", "The journey card names the feature offer")
	var add := button_named("Add feature")
	check(add != null and not add.disabled and str(add.get_meta("cozy_variant", "")) == "secondary", "Add feature is a secondary action")
	check(button_named("Hire Mina") != null and str(button_named("Hire Mina").get_meta("cozy_variant", "")) == "primary", "Hire Mina stays the one primary action beside the feature")
	check(int(developing().get("devDaysRequired", 0)) == 2 and int(developing().get("devDays", -1)) == 0 and company_cash() == 0, "The offer still needs 2 office days and no cash")
	await reveal(line)
	var footer := main.company_panel._footer
	check(add.get_global_rect().end.y <= footer.get_global_rect().position.y, "Add feature sits above Hire")
	var new_product := button_named("New Product")
	check(new_product != null and add.get_global_rect().end.y <= new_product.get_global_rect().position.y, "Add feature sits above New Product")
	await snap("60-feature-offer", line)
	await click(add)
	await wait_until(func() -> bool:
		return not main.company_panel.busy and label_named("FeatureOffer") != null and label_named("FeatureOffer").text == "Feature added · Whop Bonus Drop · Building · day 0 of 3" and int(developing().get("devDaysRequired", 0)) == 3 and company_cash() == 0
	, "Adding the feature keeps the cash and needs 3 office days")
	check(button_named("Add feature") == null, "The feature button hides once it is added")
	check(int(developing().get("devDays", -1)) == 0, "Adding the feature does not spend a dev day")
	var header := label_named("OfficeDate")
	check(header != null and header.text.contains("$0.00") and header.text.contains("0 reputation"), "The header stays at $0 and 0 reputation")
	await snap("61-feature-added", label_named("FeatureOffer"))

func _choice_pressed(button: Button) -> bool:
	if button == null:
		return false
	var box := button.get_theme_stylebox("normal")
	return box is StyleBoxTexture and str((box as StyleBoxTexture).texture.resource_path).ends_with("pressed.png")

func _day_plan_proof() -> void:
	var seeded := OS.get_temp_dir().path_join("startup-valley-proof-dayplan-%d-%d" % [OS.get_process_id(), Time.get_ticks_usec()])
	DirAccess.make_dir_recursive_absolute(seeded)
	if not seed_feature_offer(seeded):
		return
	await release_company()
	OS.set_environment("STARTUP_VALLEY_DATA_DIR", seeded)
	if not await boot_company():
		return
	var enter := button_named("Continue")
	if enter == null:
		enter = button_named("Start company")
	if enter != null:
		await click(enter)
	await dismiss_onboarding()
	await open_journey()
	var line := label_named("DayPlanOffer")
	var card := main.company_panel.find_child("PublisherCard", true, false) as Control
	var choices := main.company_panel.find_child("DayPlanChoices", true, false) as Control
	check(card != null and line != null and choices != null and card.is_ancestor_of(line) and card.is_ancestor_of(choices) and line.text == "Day plan · Even · design, tech, and hype as usual", "The journey card names the even day plan")
	var ids: Array[String] = ["even", "design", "tech", "hype"]
	var labels: Array[String] = ["Even", "Design", "Tech", "Hype"]
	var previous_end := line.get_global_rect().position.x
	for index: int in range(ids.size()):
		var choice := main.company_panel.find_child("DayPlan_" + ids[index], true, false) as Button
		check(choice != null and choice.text == labels[index] and not choice.disabled and str(choice.get_meta("cozy_variant", "")) == "secondary", "Day plan %s is a secondary choice" % labels[index])
		if choice == null:
			continue
		check(choice.get_global_rect().position.x >= previous_end - 1.0, "Day plan choices sit in a row")
		check(choice.get_global_rect().position.y >= line.get_global_rect().end.y - 2.0, "Day plan choices sit under the offer line")
		previous_end = choice.get_global_rect().end.x
		if ids[index] == "even":
			check(_choice_pressed(choice), "Even starts pressed")
		else:
			check(not _choice_pressed(choice), "%s starts unpressed" % labels[index])
	var hire := button_named("Hire Mina")
	check(hire != null and str(hire.get_meta("cozy_variant", "")) == "primary", "Hire Mina stays the one primary action beside the day plan")
	await reveal(line)
	var footer := main.company_panel._footer
	var even := main.company_panel.find_child("DayPlan_even", true, false) as Button
	check(even != null and even.get_global_rect().end.y <= footer.get_global_rect().position.y, "Day plan sits above Hire")
	var new_product := button_named("New Product")
	check(new_product != null and even.get_global_rect().end.y <= new_product.get_global_rect().position.y, "Day plan sits above New Product")
	check(company_cash() == 0 and company_reputation() == 0 and int(developing().get("devDays", -1)) == 0, "The even plan has not spent cash or a dev day")
	await snap("62-dayplan-offer", line)
	var design := main.company_panel.find_child("DayPlan_design", true, false) as Button
	await click(design)
	await wait_until(func() -> bool:
		return not main.company_panel.busy and label_named("DayPlanOffer") != null and label_named("DayPlanOffer").text == "Day plan · Design · today's craft goes to design"
	, "Picking Design shows the emphasis line")
	check(company_cash() == 0 and company_reputation() == 0 and int(developing().get("devDays", -1)) == 0, "Picking Design spends no cash and no dev day")
	var picked := main.company_panel.find_child("DayPlan_design", true, false) as Button
	check(picked != null and _choice_pressed(picked) and str(picked.get_meta("cozy_variant", "")) == "secondary", "Design stays a pressed secondary choice")
	check(main.company_panel.find_child("DayPlan_even", true, false) != null and not _choice_pressed(main.company_panel.find_child("DayPlan_even", true, false) as Button), "Even is no longer pressed")
	var header := label_named("OfficeDate")
	check(header != null and header.text.contains("$0.00") and header.text.contains("0 reputation"), "The header stays at $0 and 0 reputation")
	await snap("63-dayplan-design", label_named("DayPlanOffer"))


func seed_bugs_offer(data_dir: String) -> bool:
	var database := ProjectSettings.globalize_path("res://../harness/src/database.ts")
	var tsx := ProjectSettings.globalize_path("res://../harness/node_modules/tsx/dist/cli.mjs")
	var node := OS.get_environment("STARTUP_VALLEY_NODE").strip_edges()
	if node.is_empty():
		for dir: String in OS.get_environment("PATH").split(":"):
			if FileAccess.file_exists(dir.path_join("node")):
				node = dir.path_join("node")
				break
	if node.is_empty():
		node = "/home/box/.local/node22/bin/node"
	var script_path := data_dir.path_join("seed-bugs.mjs")
	var script := "import { mkdirSync } from 'node:fs';\nimport { GameDatabase } from %s;\nconst root = process.argv[process.argv.length - 1];\nmkdirSync(root + '/company-project', { recursive: true });\nconst db = new GameDatabase(root + '/startup-valley.sqlite', root + '/company-project');\ndb.tycoon.start('crypto', 'newsletter', []);\ndb.tycoon.setDayPlan('design');\ndb.endDay(1);\nconst view = db.tycoon.view().developing;\nconst company = db.journey.state().company;\ndb.close();\nconst bugs = view && view.bugs;\nif (company.cashCents !== 0 || company.reputation !== 0 || !bugs || bugs.count < 1 || bugs.cleared !== 0 || bugs.fixing || view.design !== 6 || view.tech !== 0 || view.hype !== 0 || view.devDays !== 1) { console.error(JSON.stringify({ company: company, view: view })); process.exit(2); }\n" % JSON.stringify(database)
	var file := FileAccess.open(script_path, FileAccess.WRITE)
	if file == null:
		check(false, "Could not write the bugs seed script")
		return false
	file.store_string(script)
	file.close()
	var output: Array = []
	var code := OS.execute(node, PackedStringArray([tsx, script_path, data_dir]), output, true)
	check(code == 0, "Seeded a lopsided newsletter with live bugs (%s)" % " ".join(output))
	return code == 0

func _bugs_proof() -> void:
	var seeded := OS.get_temp_dir().path_join("startup-valley-proof-bugs-%d-%d" % [OS.get_process_id(), Time.get_ticks_usec()])
	DirAccess.make_dir_recursive_absolute(seeded)
	if not seed_bugs_offer(seeded):
		return
	await release_company()
	OS.set_environment("STARTUP_VALLEY_DATA_DIR", seeded)
	if not await boot_company():
		return
	var enter := button_named("Continue")
	if enter == null:
		enter = button_named("Start company")
	if enter != null:
		await click(enter)
	await dismiss_onboarding()
	await open_journey()
	var line := label_named("BugsOffer")
	var card := main.company_panel.find_child("PublisherCard", true, false) as Control
	var fix := main.company_panel.find_child("FixBugs", true, false) as Button
	check(card != null and line != null and fix != null and card.is_ancestor_of(line) and card.is_ancestor_of(fix) and line.text.begins_with("Bugs · ") and line.text.contains("Fix bugs spends tomorrow's craft"), "The journey card names the bugs offer")
	check(not fix.disabled and str(fix.get_meta("cozy_variant", "")) == "secondary" and fix.text == "Fix bugs", "Fix bugs is a secondary button")
	var hire := button_named("Hire Mina")
	check(hire != null and str(hire.get_meta("cozy_variant", "")) == "primary", "Hire Mina stays the one primary action beside bugs")
	await reveal(line)
	var footer := main.company_panel._footer
	check(fix.get_global_rect().end.y <= footer.get_global_rect().position.y, "Bugs sits above Hire")
	var new_product := button_named("New Product")
	check(new_product != null and fix.get_global_rect().end.y <= new_product.get_global_rect().position.y, "Bugs sits above New Product")
	check(company_cash() == 0 and company_reputation() == 0 and int(developing().get("devDays", -1)) == 1, "The bugs offer has not spent cash")
	var header := label_named("OfficeDate")
	check(header != null and header.text.contains("$0.00") and header.text.contains("0 reputation"), "The header stays at $0 and 0 reputation")
	await snap("64-bugs-offer", line)
	await click(fix)
	await wait_until(func() -> bool:
		return not main.company_panel.busy and label_named("BugsOffer") != null and label_named("BugsOffer").text == "Fixing bugs · next office day clears craft into bugfix"
	, "Arming Fix bugs shows the fixing line")
	check(company_cash() == 0 and company_reputation() == 0 and int(developing().get("devDays", -1)) == 1, "Arming Fix bugs spends no cash and no extra day")
	check(main.company_panel.find_child("FixBugs", true, false) == null, "Fix bugs hides once armed")
	header = label_named("OfficeDate")
	check(header != null and header.text.contains("$0.00") and header.text.contains("0 reputation"), "The header stays at $0 and 0 reputation after arming")
	await snap("65-bugs-fixing", label_named("BugsOffer"))

func seed_crunch_offer(data_dir: String) -> bool:
	var database := ProjectSettings.globalize_path("res://../harness/src/database.ts")
	var tsx := ProjectSettings.globalize_path("res://../harness/node_modules/tsx/dist/cli.mjs")
	var node := OS.get_environment("STARTUP_VALLEY_NODE").strip_edges()
	if node.is_empty():
		for dir: String in OS.get_environment("PATH").split(":"):
			if FileAccess.file_exists(dir.path_join("node")):
				node = dir.path_join("node")
				break
	if node.is_empty():
		node = "/home/box/.local/node22/bin/node"
	var script_path := data_dir.path_join("seed-crunch.mjs")
	var script := "import { mkdirSync } from 'node:fs';\nimport { GameDatabase } from %s;\nconst root = process.argv[process.argv.length - 1];\nmkdirSync(root + '/company-project', { recursive: true });\nconst db = new GameDatabase(root + '/startup-valley.sqlite', root + '/company-project');\ndb.tycoon.start('crypto', 'newsletter', []);\nconst view = db.tycoon.view().developing;\nconst company = db.journey.state().company;\ndb.close();\nconst crunch = view && view.crunch;\nif (company.cashCents !== 0 || company.reputation !== 0 || !crunch || crunch.state !== 'idle' || view.devDays !== 0) { console.error(JSON.stringify({ company: company, view: view })); process.exit(2); }\n" % JSON.stringify(database)
	var file := FileAccess.open(script_path, FileAccess.WRITE)
	if file == null:
		check(false, "Could not write the crunch seed script")
		return false
	file.store_string(script)
	file.close()
	var output: Array = []
	var code := OS.execute(node, PackedStringArray([tsx, script_path, data_dir]), output, true)
	check(code == 0, "Seeded a developing newsletter with the crunch offer (%s)" % " ".join(output))
	return code == 0

func _crunch_proof() -> void:
	var seeded := OS.get_temp_dir().path_join("startup-valley-proof-crunch-%d-%d" % [OS.get_process_id(), Time.get_ticks_usec()])
	DirAccess.make_dir_recursive_absolute(seeded)
	if not seed_crunch_offer(seeded):
		return
	await release_company()
	OS.set_environment("STARTUP_VALLEY_DATA_DIR", seeded)
	if not await boot_company():
		return
	var enter := button_named("Continue")
	if enter == null:
		enter = button_named("Start company")
	if enter != null:
		await click(enter)
	await dismiss_onboarding()
	await open_journey()
	var line := label_named("CrunchOffer")
	var card := main.company_panel.find_child("PublisherCard", true, false) as Control
	var crunch := main.company_panel.find_child("Crunch", true, false) as Button
	check(card != null and line != null and crunch != null and card.is_ancestor_of(line) and card.is_ancestor_of(crunch) and line.text == "Crunch · double craft tomorrow, then a rest day and +1 bug", "The journey card names the crunch offer")
	check(not crunch.disabled and str(crunch.get_meta("cozy_variant", "")) == "secondary" and crunch.text == "Crunch", "Crunch is a secondary button")
	var hire := button_named("Hire Mina")
	check(hire != null and str(hire.get_meta("cozy_variant", "")) == "primary", "Hire Mina stays the one primary action beside crunch")
	await reveal(line)
	var footer := main.company_panel._footer
	check(crunch.get_global_rect().end.y <= footer.get_global_rect().position.y, "Crunch sits above Hire")
	check(line.get_global_rect().end.y <= crunch.get_global_rect().position.y + 1.0, "The crunch line sits above the button")
	var new_product := button_named("New Product")
	check(new_product != null and crunch.get_global_rect().end.y <= new_product.get_global_rect().position.y, "Crunch sits above New Product")
	check(company_cash() == 0 and company_reputation() == 0 and int(developing().get("devDays", -1)) == 0, "The crunch offer has not spent cash")
	var header := label_named("OfficeDate")
	check(header != null and header.text.contains("$0.00") and header.text.contains("0 reputation"), "The header stays at $0 and 0 reputation")
	await snap("66-crunch-offer", line)
	await click(crunch)
	await wait_until(func() -> bool:
		return not main.company_panel.busy and label_named("CrunchOffer") != null and label_named("CrunchOffer").text == "Crunching · tomorrow's craft counts double"
	, "Arming Crunch shows the crunching line")
	check(company_cash() == 0 and company_reputation() == 0 and int(developing().get("devDays", -1)) == 0, "Arming Crunch spends no cash and no day")
	check(main.company_panel.find_child("Crunch", true, false) == null, "Crunch hides once armed")
	await end_office_day()
	await open_journey()
	line = label_named("CrunchOffer")
	check(line != null and line.text == "Resting · team recovers tomorrow", "The next office day shows the resting line")
	check(main.company_panel.find_child("Crunch", true, false) == null, "Resting has no Crunch button")
	check(int(developing().get("design", -1)) == 4 and int(developing().get("tech", -1)) == 4 and int(developing().get("hype", -1)) == 4, "The crunch day doubled personal craft")
	check(company_cash() == 0 and company_reputation() == 0, "The crunch day spends no cash")
	header = label_named("OfficeDate")
	check(header != null and header.text.contains("$0.00") and header.text.contains("0 reputation"), "The header stays at $0 and 0 reputation while resting")
	await reveal(line)
	new_product = button_named("New Product")
	footer = main.company_panel._footer
	check(new_product != null and line.get_global_rect().end.y <= new_product.get_global_rect().position.y, "Resting sits above New Product")
	check(footer != null and line.get_global_rect().end.y <= footer.get_global_rect().position.y, "Resting sits above Hire")
	await snap("67-crunch-resting", line)

func seed_early_offer(data_dir: String) -> bool:
	var database := ProjectSettings.globalize_path("res://../harness/src/database.ts")
	var tsx := ProjectSettings.globalize_path("res://../harness/node_modules/tsx/dist/cli.mjs")
	var node := OS.get_environment("STARTUP_VALLEY_NODE").strip_edges()
	if node.is_empty():
		for dir: String in OS.get_environment("PATH").split(":"):
			if FileAccess.file_exists(dir.path_join("node")):
				node = dir.path_join("node")
				break
	if node.is_empty():
		node = "/home/box/.local/node22/bin/node"
	var script_path := data_dir.path_join("seed-early-access.mjs")
	var script := "import { mkdirSync } from 'node:fs';\nimport { GameDatabase } from %s;\nconst root = process.argv[process.argv.length - 1];\nmkdirSync(root + '/company-project', { recursive: true });\nconst db = new GameDatabase(root + '/startup-valley.sqlite', root + '/company-project');\ndb.tycoon.start('crypto', 'newsletter', []);\ndb.endDay(1);\nconst view = db.tycoon.view().developing;\nconst company = db.journey.state().company;\ndb.close();\nconst offer = view && view.earlyAccess;\nif (company.cashCents !== 0 || company.reputation !== 0 || !view || view.devDays !== 1 || !offer || offer.enabled !== true || offer.penalty !== 1 || offer.daysLeft !== 1 || offer.reason !== '') { console.error(JSON.stringify({ company: company, view: view })); process.exit(2); }\n" % JSON.stringify(database)
	var file := FileAccess.open(script_path, FileAccess.WRITE)
	if file == null:
		check(false, "Could not write the early access seed script")
		return false
	file.store_string(script)
	file.close()
	var output: Array = []
	var code := OS.execute(node, PackedStringArray([tsx, script_path, data_dir]), output, true)
	check(code == 0, "Seeded a one-day newsletter with the early access offer (%s)" % " ".join(output))
	return code == 0

func _early_access_proof() -> void:
	var seeded := OS.get_temp_dir().path_join("startup-valley-proof-early-%d-%d" % [OS.get_process_id(), Time.get_ticks_usec()])
	DirAccess.make_dir_recursive_absolute(seeded)
	if not seed_early_offer(seeded):
		return
	await release_company()
	OS.set_environment("STARTUP_VALLEY_DATA_DIR", seeded)
	if not await boot_company():
		return
	var enter := button_named("Continue")
	if enter == null:
		enter = button_named("Start company")
	if enter != null:
		await click(enter)
	await dismiss_onboarding()
	await open_journey()
	var line := label_named("EarlyAccessOffer")
	var card := main.company_panel.find_child("PublisherCard", true, false) as Control
	var ship := main.company_panel.find_child("ShipEarly", true, false) as Button
	check(card != null and line != null and ship != null and card.is_ancestor_of(line) and card.is_ancestor_of(ship) and line.text == "Early access · ship now, −1 score", "The journey card names the early access offer")
	check(not ship.disabled and str(ship.get_meta("cozy_variant", "")) == "secondary" and ship.text == "Ship early", "Ship early is a secondary button")
	var hire := button_named("Hire Mina")
	check(hire != null and str(hire.get_meta("cozy_variant", "")) == "primary", "Hire Mina stays the one primary action beside early access")
	await reveal(line)
	var footer := main.company_panel._footer
	var crunch := main.company_panel.find_child("Crunch", true, false) as Button
	var new_product := button_named("New Product")
	check(crunch != null and crunch.get_global_rect().end.y <= line.get_global_rect().position.y + 1.0, "Early access sits under Crunch")
	check(line.get_global_rect().end.y <= ship.get_global_rect().position.y + 1.0, "The early access line sits above Ship early")
	check(new_product != null and ship.get_global_rect().end.y <= new_product.get_global_rect().position.y, "Ship early sits above New Product")
	check(footer != null and ship.get_global_rect().end.y <= footer.get_global_rect().position.y and not ship.get_global_rect().intersects(footer.get_global_rect()), "Ship early does not overlap Hire")
	check(company_cash() == 0 and company_reputation() == 0 and int(developing().get("devDays", -1)) == 1, "The early access offer has not spent cash")
	var header := label_named("OfficeDate")
	check(header != null and header.text.contains("$0.00") and header.text.contains("0 reputation"), "The header stays at $0 and 0 reputation")
	await snap("68-early-offer", line)
	await click(ship)
	var shipped := await wait_until(func() -> bool:
		return not main.company_panel.busy and main.company_panel.screen == "release" and label_named("ReleaseEarly") != null and label_named("ReleaseEarly").text == "Early access"
	, "Shipping early opens the release card")
	if not shipped:
		return
	check(company_cash() > 0 and company_cash() < 20700, "Launch-day sales are quieter than a full newsletter")
	check(developing().is_empty(), "The bench is clear after the early ship")
	var mark := label_named("ReleaseEarly")
	var score := label_named("ReleaseScore")
	footer = main.company_panel._footer
	check(score != null and mark != null and score.get_global_rect().end.y <= mark.get_global_rect().position.y + 1.0, "Early access sits under the score")
	check(footer != null and mark.get_global_rect().end.y <= footer.get_global_rect().position.y and not mark.get_global_rect().intersects(footer.get_global_rect()), "Early access does not overlap the release actions")
	await snap("69-early-released", score)

func seed_cancel_offer(data_dir: String) -> bool:
	var database := ProjectSettings.globalize_path("res://../harness/src/database.ts")
	var tsx := ProjectSettings.globalize_path("res://../harness/node_modules/tsx/dist/cli.mjs")
	var node := OS.get_environment("STARTUP_VALLEY_NODE").strip_edges()
	if node.is_empty():
		for dir: String in OS.get_environment("PATH").split(":"):
			if FileAccess.file_exists(dir.path_join("node")):
				node = dir.path_join("node")
				break
	if node.is_empty():
		node = "/home/box/.local/node22/bin/node"
	var script_path := data_dir.path_join("seed-cancel.mjs")
	var script := "import { mkdirSync } from 'node:fs';\nimport { GameDatabase } from %s;\nconst root = process.argv[process.argv.length - 1];\nmkdirSync(root + '/company-project', { recursive: true });\nconst db = new GameDatabase(root + '/startup-valley.sqlite', root + '/company-project');\ndb.tycoon.start('crypto', 'newsletter', []);\ndb.endDay(1);\nconst view = db.tycoon.view().developing;\nconst company = db.journey.state().company;\ndb.close();\nconst offer = view && view.cancel;\nif (company.cashCents !== 0 || company.reputation !== 0 || !view || view.devDays !== 1 || !offer || offer.enabled !== true || offer.reason !== '') { console.error(JSON.stringify({ company: company, view: view })); process.exit(2); }\n" % JSON.stringify(database)
	var file := FileAccess.open(script_path, FileAccess.WRITE)
	if file == null:
		check(false, "Could not write the cancel seed script")
		return false
	file.store_string(script)
	file.close()
	var output: Array = []
	var code := OS.execute(node, PackedStringArray([tsx, script_path, data_dir]), output, true)
	check(code == 0, "Seeded a one-day newsletter with Cancel build (%s)" % " ".join(output))
	return code == 0

func _cancel_proof() -> void:
	var seeded := OS.get_temp_dir().path_join("startup-valley-proof-cancel-%d-%d" % [OS.get_process_id(), Time.get_ticks_usec()])
	DirAccess.make_dir_recursive_absolute(seeded)
	if not seed_cancel_offer(seeded):
		return
	await release_company()
	OS.set_environment("STARTUP_VALLEY_DATA_DIR", seeded)
	if not await boot_company():
		return
	var enter := button_named("Continue")
	if enter == null:
		enter = button_named("Start company")
	if enter != null:
		await click(enter)
	await dismiss_onboarding()
	await open_journey()
	var line := label_named("CancelOffer")
	var card := main.company_panel.find_child("PublisherCard", true, false) as Control
	var cancel := main.company_panel.find_child("CancelBuild", true, false) as Button
	var early := label_named("EarlyAccessOffer")
	check(card != null and line != null and cancel != null and card.is_ancestor_of(line) and card.is_ancestor_of(cancel) and line.text == "Cancel · drop this build. Days worked are gone.", "The journey card names the cancel offer")
	check(not cancel.disabled and str(cancel.get_meta("cozy_variant", "")) == "secondary" and cancel.text == "Cancel build", "Cancel build is a secondary button")
	var hire := button_named("Hire Mina")
	check(hire != null and str(hire.get_meta("cozy_variant", "")) == "primary", "Hire Mina stays the one primary action beside cancel")
	await reveal(line)
	var footer := main.company_panel._footer
	var ship := main.company_panel.find_child("ShipEarly", true, false) as Button
	var new_product := button_named("New Product")
	check(early != null and ship != null and ship.get_global_rect().end.y <= line.get_global_rect().position.y + 1.0, "Cancel sits under Ship early")
	check(line.get_global_rect().end.y <= cancel.get_global_rect().position.y + 1.0, "The cancel line sits above Cancel build")
	check(new_product != null and cancel.get_global_rect().end.y <= new_product.get_global_rect().position.y, "Cancel build sits above New Product")
	check(footer != null and cancel.get_global_rect().end.y <= footer.get_global_rect().position.y and not cancel.get_global_rect().intersects(footer.get_global_rect()), "Cancel build does not overlap Hire")
	check(company_cash() == 0 and company_reputation() == 0 and int(developing().get("devDays", -1)) == 1, "The cancel offer has not spent cash")
	var header := label_named("OfficeDate")
	check(header != null and header.text.contains("$0.00") and header.text.contains("0 reputation"), "The header stays at $0 and 0 reputation")
	await snap("70-cancel-offer", line)
	await click(cancel)
	var asked := await wait_until(func() -> bool:
		return not main.company_panel.busy and label_named("CancelOffer") != null and label_named("CancelOffer").text == "Drop this build? Days worked are gone." and main.company_panel.find_child("KeepBuild", true, false) != null and main.company_panel.find_child("DropBuild", true, false) != null
	, "Cancel build asks before it drops the product")
	if not asked:
		return
	var keep := main.company_panel.find_child("KeepBuild", true, false) as Button
	var drop := main.company_panel.find_child("DropBuild", true, false) as Button
	check(keep.has_focus() and str(keep.get_meta("cozy_variant", "")) == "secondary" and str(drop.get_meta("cozy_variant", "")) == "secondary", "Keep building takes focus and both choices stay secondary")
	await click(drop)
	var dropped := await wait_until(func() -> bool:
		return not main.company_panel.busy and main.company_panel.screen == "journey" and developing().is_empty() and label_named("CancelOffer") == null
	, "Drop the build clears the bench")
	if not dropped:
		return
	new_product = button_named("New Product")
	check(new_product != null and not new_product.disabled, "New Product is available after the drop")
	check(company_cash() == 0 and company_reputation() == 0, "Dropping the build leaves cash and fans")
	header = label_named("OfficeDate")
	check(header != null and header.text.contains("$0.00") and header.text.contains("0 reputation"), "The header stays at $0 and 0 reputation after the drop")
	await snap("71-cancel-done", new_product)

func seed_slip_offer(data_dir: String) -> bool:
	var database := ProjectSettings.globalize_path("res://../harness/src/database.ts")
	var tsx := ProjectSettings.globalize_path("res://../harness/node_modules/tsx/dist/cli.mjs")
	var node := OS.get_environment("STARTUP_VALLEY_NODE").strip_edges()
	if node.is_empty():
		for dir: String in OS.get_environment("PATH").split(":"):
			if FileAccess.file_exists(dir.path_join("node")):
				node = dir.path_join("node")
				break
	if node.is_empty():
		node = "/home/box/.local/node22/bin/node"
	var script_path := data_dir.path_join("seed-slip.mjs")
	var script := "import { mkdirSync } from 'node:fs';\nimport { GameDatabase } from %s;\nconst root = process.argv[process.argv.length - 1];\nmkdirSync(root + '/company-project', { recursive: true });\nconst db = new GameDatabase(root + '/startup-valley.sqlite', root + '/company-project');\ndb.tycoon.start('crypto', 'newsletter', []);\nconst view = db.tycoon.view().developing;\nconst company = db.journey.state().company;\ndb.close();\nconst offer = view && view.slip;\nif (company.cashCents !== 0 || company.reputation !== 0 || !view || view.devDays !== 0 || !offer || offer.enabled !== true || offer.pending !== false || offer.reason !== '') { console.error(JSON.stringify({ company: company, view: view })); process.exit(2); }\n" % JSON.stringify(database)
	var file := FileAccess.open(script_path, FileAccess.WRITE)
	if file == null:
		check(false, "Could not write the slip seed script")
		return false
	file.store_string(script)
	file.close()
	var output: Array = []
	var code := OS.execute(node, PackedStringArray([tsx, script_path, data_dir]), output, true)
	check(code == 0, "Seeded a day-zero newsletter with Slip a day (%s)" % " ".join(output))
	return code == 0

func _slip_proof() -> void:
	var seeded := OS.get_temp_dir().path_join("startup-valley-proof-slip-%d-%d" % [OS.get_process_id(), Time.get_ticks_usec()])
	DirAccess.make_dir_recursive_absolute(seeded)
	if not seed_slip_offer(seeded):
		return
	await release_company()
	OS.set_environment("STARTUP_VALLEY_DATA_DIR", seeded)
	if not await boot_company():
		return
	var enter := button_named("Continue")
	if enter == null:
		enter = button_named("Start company")
	if enter != null:
		await click(enter)
	await dismiss_onboarding()
	await open_journey()
	var line := label_named("SlipOffer")
	var card := main.company_panel.find_child("PublisherCard", true, false) as Control
	var slip := main.company_panel.find_child("SlipDay", true, false) as Button
	var cancel := main.company_panel.find_child("CancelBuild", true, false) as Button
	check(card != null and line != null and slip != null and card.is_ancestor_of(line) and card.is_ancestor_of(slip) and line.text == "Slip a day · hold tomorrow. The build does not.", "The journey card names the slip offer")
	check(not slip.disabled and str(slip.get_meta("cozy_variant", "")) == "secondary" and slip.text == "Slip a day", "Slip a day is a secondary button")
	var hire := button_named("Hire Mina")
	check(hire != null and str(hire.get_meta("cozy_variant", "")) == "primary", "Hire Mina stays the one primary action beside slip")
	await reveal(line)
	var footer := main.company_panel._footer
	var new_product := button_named("New Product")
	check(cancel != null and cancel.get_global_rect().end.y <= line.get_global_rect().position.y + 1.0, "Slip sits under Cancel build")
	check(line.get_global_rect().end.y <= slip.get_global_rect().position.y + 1.0, "The slip line sits above Slip a day")
	check(new_product != null and slip.get_global_rect().end.y <= new_product.get_global_rect().position.y, "Slip a day sits above New Product")
	check(footer != null and slip.get_global_rect().end.y <= footer.get_global_rect().position.y and not slip.get_global_rect().intersects(footer.get_global_rect()), "Slip a day does not overlap Hire")
	check(line.get_line_count() == 1, "The slip line stays on one line")
	check(company_cash() == 0 and company_reputation() == 0 and int(developing().get("devDays", -1)) == 0, "The slip offer has not spent cash")
	var header := label_named("OfficeDate")
	check(header != null and header.text.contains("$0.00") and header.text.contains("0 reputation"), "The header stays at $0 and 0 reputation")
	check(not main.job_panel._connection_panel.visible, "Slip a day never opens Connect")
	await snap("72-slip-offer", line)
	await click(slip)
	var held := await wait_until(func() -> bool:
		return not main.company_panel.busy and label_named("SlipOffer") != null and label_named("SlipOffer").text == "Holding tomorrow" and main.company_panel.find_child("SlipDay", true, false) == null
	, "Slip a day shows Holding tomorrow")
	if not held:
		return
	line = label_named("SlipOffer")
	await reveal(line)
	new_product = button_named("New Product")
	footer = main.company_panel._footer
	check(new_product != null and line.get_global_rect().end.y <= new_product.get_global_rect().position.y, "Holding tomorrow sits above New Product")
	check(footer != null and line.get_global_rect().end.y <= footer.get_global_rect().position.y and not line.get_global_rect().intersects(footer.get_global_rect()), "Holding tomorrow does not overlap Hire")
	check(company_cash() == 0 and company_reputation() == 0 and int(developing().get("devDays", -1)) == 0, "Arming the hold spends no cash and gains no day")
	var slip_block: Variant = developing().get("slip", null)
	check(slip_block is Dictionary and bool((slip_block as Dictionary).get("pending", false)), "The hold is pending")
	check(not main.job_panel._connection_panel.visible, "Holding tomorrow never opens Connect")
	await snap("73-slip-held", line)

func seed_pivot_offer(data_dir: String) -> bool:
	var database := ProjectSettings.globalize_path("res://../harness/src/database.ts")
	var tsx := ProjectSettings.globalize_path("res://../harness/node_modules/tsx/dist/cli.mjs")
	var node := OS.get_environment("STARTUP_VALLEY_NODE").strip_edges()
	if node.is_empty():
		for dir: String in OS.get_environment("PATH").split(":"):
			if FileAccess.file_exists(dir.path_join("node")):
				node = dir.path_join("node")
				break
	if node.is_empty():
		node = "/home/box/.local/node22/bin/node"
	var script_path := data_dir.path_join("seed-pivot.mjs")
	var script := "import { mkdirSync } from 'node:fs';\nimport { GameDatabase } from %s;\nconst root = process.argv[process.argv.length - 1];\nmkdirSync(root + '/company-project', { recursive: true });\nconst db = new GameDatabase(root + '/startup-valley.sqlite', root + '/company-project');\ndb.tycoon.start('crypto', 'newsletter', []);\nconst view = db.tycoon.view().developing;\nconst company = db.journey.state().company;\ndb.close();\nconst offer = view && view.pivot;\nif (company.cashCents !== 0 || company.reputation !== 0 || !view || view.devDays !== 0 || !offer || offer.enabled !== true || offer.used !== false || offer.reason !== '') { console.error(JSON.stringify({ company: company, view: view })); process.exit(2); }\n" % JSON.stringify(database)
	var file := FileAccess.open(script_path, FileAccess.WRITE)
	if file == null:
		check(false, "Could not write the pivot seed script")
		return false
	file.store_string(script)
	file.close()
	var output: Array = []
	var code := OS.execute(node, PackedStringArray([tsx, script_path, data_dir]), output, true)
	check(code == 0, "Seeded a day-zero newsletter with Pivot (%s)" % " ".join(output))
	return code == 0

func _pivot_proof() -> void:
	var seeded := OS.get_temp_dir().path_join("startup-valley-proof-pivot-%d-%d" % [OS.get_process_id(), Time.get_ticks_usec()])
	DirAccess.make_dir_recursive_absolute(seeded)
	if not seed_pivot_offer(seeded):
		return
	await release_company()
	OS.set_environment("STARTUP_VALLEY_DATA_DIR", seeded)
	if not await boot_company():
		return
	var enter := button_named("Continue")
	if enter == null:
		enter = button_named("Start company")
	if enter != null:
		await click(enter)
	await dismiss_onboarding()
	await open_journey()
	var line := label_named("PivotOffer")
	var card := main.company_panel.find_child("PublisherCard", true, false) as Control
	var pivot := main.company_panel.find_child("Pivot", true, false) as Button
	var slip := main.company_panel.find_child("SlipDay", true, false) as Button
	check(card != null and line != null and pivot != null and card.is_ancestor_of(line) and card.is_ancestor_of(pivot) and line.text == "Pivot · change topic or type. Days and points stay.", "The journey card names the pivot offer")
	check(not pivot.disabled and str(pivot.get_meta("cozy_variant", "")) == "secondary" and pivot.text == "Pivot", "Pivot is a secondary button")
	var hire := button_named("Hire Mina")
	check(hire != null and str(hire.get_meta("cozy_variant", "")) == "primary", "Hire Mina stays the one primary action beside pivot")
	await reveal(line)
	var footer := main.company_panel._footer
	var new_product := button_named("New Product")
	check(slip != null and slip.get_global_rect().end.y <= line.get_global_rect().position.y + 1.0, "Pivot sits under Slip a day")
	check(line.get_global_rect().end.y <= pivot.get_global_rect().position.y + 1.0, "The pivot line sits above Pivot")
	check(new_product != null and pivot.get_global_rect().end.y <= new_product.get_global_rect().position.y, "Pivot sits above New Product")
	check(footer != null and pivot.get_global_rect().end.y <= footer.get_global_rect().position.y and not pivot.get_global_rect().intersects(footer.get_global_rect()), "Pivot does not overlap Hire")
	check(line.get_line_count() == 1, "The pivot line stays on one line")
	check(company_cash() == 0 and company_reputation() == 0 and int(developing().get("devDays", -1)) == 0, "The pivot offer has not spent cash")
	var header := label_named("OfficeDate")
	check(header != null and header.text.contains("$0.00") and header.text.contains("0 reputation"), "The header stays at $0 and 0 reputation")
	check(not main.job_panel._connection_panel.visible, "Pivot never opens Connect")
	await snap("74-pivot-offer", line)
	await click(pivot)
	var picking := await wait_until(func() -> bool:
		return not main.company_panel.busy and label_named("PivotOffer") != null and label_named("PivotOffer").text == "Pivot · pick a new topic or type." and main.company_panel.find_child("ChangePair", true, false) != null
	, "Pivot opens the topic and type picker")
	if not picking:
		return
	var fitness := main.company_panel.find_child("PivotTopic_fitness", true, false) as Button
	await click(fitness)
	var course := main.company_panel.find_child("PivotType_course", true, false) as Button
	await click(course)
	var confirm := main.company_panel.find_child("ChangePair", true, false) as Button
	await wait_until(func() -> bool:
		return main.company_panel.find_child("ChangePair", true, false) != null and not (main.company_panel.find_child("ChangePair", true, false) as Button).disabled
	, "Change pair enables on Fitness Course")
	confirm = main.company_panel.find_child("ChangePair", true, false) as Button
	await click(confirm)
	var done := await wait_until(func() -> bool:
		return not main.company_panel.busy and developing().get("name", "") == "Fitness Course" and label_named("PivotOffer") != null and label_named("PivotOffer").text == "Pivoted · Fitness Course"
	, "Change pair pivots to Fitness Course")
	if not done:
		return
	line = label_named("PivotOffer")
	await reveal(line)
	new_product = button_named("New Product")
	footer = main.company_panel._footer
	check(new_product != null and line.get_global_rect().end.y <= new_product.get_global_rect().position.y, "Pivoted sits above New Product")
	check(footer != null and line.get_global_rect().end.y <= footer.get_global_rect().position.y and not line.get_global_rect().intersects(footer.get_global_rect()), "Pivoted does not overlap Hire")
	check(company_cash() == 0 and company_reputation() == 0 and int(developing().get("devDays", -1)) == 0, "Pivoting spends no cash and gains no day")
	check(str(developing().get("fit", "")) == "great" and str(developing().get("topicId", "")) == "fitness" and str(developing().get("typeId", "")) == "course", "The name and pair follow Fitness Course")
	var pivot_block: Variant = developing().get("pivot", null)
	check(pivot_block is Dictionary and bool((pivot_block as Dictionary).get("used", false)), "The one pivot is used")
	check(not main.job_panel._connection_panel.visible, "Pivoted never opens Connect")
	await snap("75-pivot-done", line)

func seed_playtest_offer(data_dir: String) -> bool:
	var database := ProjectSettings.globalize_path("res://../harness/src/database.ts")
	var tsx := ProjectSettings.globalize_path("res://../harness/node_modules/tsx/dist/cli.mjs")
	var node := OS.get_environment("STARTUP_VALLEY_NODE").strip_edges()
	if node.is_empty():
		for dir: String in OS.get_environment("PATH").split(":"):
			if FileAccess.file_exists(dir.path_join("node")):
				node = dir.path_join("node")
				break
	if node.is_empty():
		node = "/home/box/.local/node22/bin/node"
	var script_path := data_dir.path_join("seed-playtest.mjs")
	var script := "import { mkdirSync } from 'node:fs';\nimport { GameDatabase } from %s;\nconst root = process.argv[process.argv.length - 1];\nmkdirSync(root + '/company-project', { recursive: true });\nconst db = new GameDatabase(root + '/startup-valley.sqlite', root + '/company-project');\ndb.tycoon.start('crypto', 'newsletter', []);\ndb.endDay(1);\ndb.endDay(2);\nconst view = db.tycoon.view().developing;\nconst company = db.journey.state().company;\ndb.close();\nconst offer = view && view.playtest;\nif (company.cashCents !== 0 || company.reputation !== 0 || !view || view.devDays !== 2 || view.design !== 4 || !offer || offer.enabled !== true || offer.band !== 'mid' || offer.reason !== '') { console.error(JSON.stringify({ company: company, view: view })); process.exit(2); }\n" % JSON.stringify(database)
	var file := FileAccess.open(script_path, FileAccess.WRITE)
	if file == null:
		check(false, "Could not write the playtest seed script")
		return false
	file.store_string(script)
	file.close()
	var output: Array = []
	var code := OS.execute(node, PackedStringArray([tsx, script_path, data_dir]), output, true)
	check(code == 0, "Seeded a two-day newsletter with Playtest (%s)" % " ".join(output))
	return code == 0

func _playtest_proof() -> void:
	var seeded := OS.get_temp_dir().path_join("startup-valley-proof-playtest-%d-%d" % [OS.get_process_id(), Time.get_ticks_usec()])
	DirAccess.make_dir_recursive_absolute(seeded)
	if not seed_playtest_offer(seeded):
		return
	await release_company()
	OS.set_environment("STARTUP_VALLEY_DATA_DIR", seeded)
	if not await boot_company():
		return
	var enter := button_named("Continue")
	if enter == null:
		enter = button_named("Start company")
	if enter != null:
		await click(enter)
	await dismiss_onboarding()
	await open_journey()
	var line := label_named("PlaytestOffer")
	var card := main.company_panel.find_child("PublisherCard", true, false) as Control
	var playtest := main.company_panel.find_child("Playtest", true, false) as Button
	var pivot := main.company_panel.find_child("Pivot", true, false) as Button
	check(card != null and line != null and playtest != null and card.is_ancestor_of(line) and card.is_ancestor_of(playtest) and line.text == "Playtest · see the likely review band.", "The journey card names the playtest offer")
	check(not playtest.disabled and str(playtest.get_meta("cozy_variant", "")) == "secondary" and playtest.text == "Playtest", "Playtest is a secondary button")
	var hire := button_named("Hire Mina")
	check(hire != null and str(hire.get_meta("cozy_variant", "")) == "primary", "Hire Mina stays the one primary action beside playtest")
	await reveal(line)
	var footer := main.company_panel._footer
	var new_product := button_named("New Product")
	check(pivot != null and pivot.get_global_rect().end.y <= line.get_global_rect().position.y + 1.0, "Playtest sits under Pivot")
	check(line.get_global_rect().end.y <= playtest.get_global_rect().position.y + 1.0, "The playtest line sits above Playtest")
	check(new_product != null and playtest.get_global_rect().end.y <= new_product.get_global_rect().position.y, "Playtest sits above New Product")
	check(footer != null and playtest.get_global_rect().end.y <= footer.get_global_rect().position.y and not playtest.get_global_rect().intersects(footer.get_global_rect()) and not line.get_global_rect().intersects(footer.get_global_rect()), "Playtest does not overlap Hire")
	check(line.get_line_count() == 1, "The playtest line stays on one line")
	check(company_cash() == 0 and company_reputation() == 0 and int(developing().get("devDays", -1)) == 2, "The playtest offer has not spent cash")
	var header := label_named("OfficeDate")
	check(header != null and header.text.contains("$0.00") and header.text.contains("0 reputation"), "The header stays at $0 and 0 reputation")
	check(not main.job_panel._connection_panel.visible, "Playtest never opens Connect")
	await snap("76-playtest-offer", line)
	await click(playtest)
	var shown := await wait_until(func() -> bool:
		return not main.company_panel.busy and label_named("PlaytestOffer") != null and label_named("PlaytestOffer").text == "Playtest: likely mid reviews"
	, "Playtest shows the likely mid band")
	if not shown:
		return
	line = label_named("PlaytestOffer")
	playtest = main.company_panel.find_child("Playtest", true, false) as Button
	await reveal(line)
	new_product = button_named("New Product")
	footer = main.company_panel._footer
	check(playtest != null and str(playtest.get_meta("cozy_variant", "")) == "secondary", "Playtest stays secondary after the look")
	check(new_product != null and playtest.get_global_rect().end.y <= new_product.get_global_rect().position.y, "The band line sits above New Product")
	check(footer != null and line.get_global_rect().end.y <= footer.get_global_rect().position.y and not line.get_global_rect().intersects(footer.get_global_rect()) and not playtest.get_global_rect().intersects(footer.get_global_rect()), "The band line does not overlap Hire")
	check(line.get_line_count() == 1, "The band line stays on one line")
	check(company_cash() == 0 and company_reputation() == 0 and int(developing().get("devDays", -1)) == 2 and int(developing().get("design", -1)) == 4, "Playtest changes no cash, day, or points")
	var playtest_block: Variant = developing().get("playtest", null)
	check(playtest_block is Dictionary and str((playtest_block as Dictionary).get("band", "")) == "mid", "The payload band stays mid")
	check(not main.job_panel._connection_panel.visible, "The playtest result never opens Connect")
	await snap("77-playtest-result", line)

func seed_team_offer(data_dir: String) -> bool:
	var database := ProjectSettings.globalize_path("res://../harness/src/database.ts")
	var tsx := ProjectSettings.globalize_path("res://../harness/node_modules/tsx/dist/cli.mjs")
	var node := OS.get_environment("STARTUP_VALLEY_NODE").strip_edges()
	if node.is_empty():
		for dir: String in OS.get_environment("PATH").split(":"):
			if FileAccess.file_exists(dir.path_join("node")):
				node = dir.path_join("node")
				break
	if node.is_empty():
		node = "/home/box/.local/node22/bin/node"
	var script_path := data_dir.path_join("seed-team.mjs")
	var script := "import { mkdirSync } from 'node:fs';\nimport { DatabaseSync } from 'node:sqlite';\nimport { GameDatabase } from %s;\nconst root = process.argv[process.argv.length - 1];\nmkdirSync(root + '/company-project', { recursive: true });\nconst file = root + '/startup-valley.sqlite';\nlet db = new GameDatabase(file, root + '/company-project');\ndb.journey.hire('mira', 1);\ndb.close();\nconst sql = new DatabaseSync(file);\nsql.prepare(\"UPDATE milestone_progress SET completed = 1 WHERE id = 'website'\").run();\nsql.close();\ndb = new GameDatabase(file, root + '/company-project');\ndb.tycoon.start('crypto', 'newsletter', []);\nconst view = db.tycoon.view().developing;\nconst company = db.journey.state().company;\ndb.close();\nconst team = view && view.team;\nif (company.cashCents !== 0 || company.reputation !== 0 || !view || view.devDays !== 0 || !team || team.enabled !== true || team.reason !== '' || !team.members || team.members.length !== 2 || team.members[0].id !== 'founder' || team.members[0].onTeam !== true || team.members[1].id !== 'mira' || team.members[1].onTeam !== false) { console.error(JSON.stringify({ company: company, view: view })); process.exit(2); }\n" % JSON.stringify(database)
	var file := FileAccess.open(script_path, FileAccess.WRITE)
	if file == null:
		check(false, "Could not write the team seed script")
		return false
	file.store_string(script)
	file.close()
	var output: Array = []
	var code := OS.execute(node, PackedStringArray([tsx, script_path, data_dir]), output, true)
	check(code == 0, "Seeded a newsletter with Mina hired and Founder on the team (%s)" % " ".join(output))
	return code == 0

func _assign_team_proof() -> void:
	var seeded := OS.get_temp_dir().path_join("startup-valley-proof-team-%d-%d" % [OS.get_process_id(), Time.get_ticks_usec()])
	DirAccess.make_dir_recursive_absolute(seeded)
	if not seed_team_offer(seeded):
		return
	await release_company()
	OS.set_environment("STARTUP_VALLEY_DATA_DIR", seeded)
	if not await boot_company():
		return
	var enter := button_named("Continue")
	if enter == null:
		enter = button_named("Start company")
	if enter != null:
		await click(enter)
	await dismiss_onboarding()
	await open_journey()
	var line := label_named("TeamOffer")
	var card := main.company_panel.find_child("PublisherCard", true, false) as Control
	var founder := main.company_panel.find_child("Team_founder", true, false) as Button
	var mina := main.company_panel.find_child("Team_mira", true, false) as Button
	var playtest := label_named("PlaytestOffer")
	check(card != null and line != null and founder != null and mina != null and card.is_ancestor_of(line) and card.is_ancestor_of(founder) and line.text == "Team: Founder", "The journey card names the team")
	check(not founder.disabled and str(founder.get_meta("cozy_variant", "")) == "secondary" and founder.text == "Founder", "Founder is a secondary button")
	check(not mina.disabled and str(mina.get_meta("cozy_variant", "")) == "secondary" and mina.text == "Mina", "Mina is a secondary button")
	var hire := button_named("Hire Theo")
	check(hire != null and str(hire.get_meta("cozy_variant", "")) == "primary", "Hire Theo stays the one primary action beside the team")
	await reveal(line)
	var footer := main.company_panel._footer
	var new_product := button_named("New Product")
	check(playtest != null and playtest.get_global_rect().end.y <= line.get_global_rect().position.y + 1.0, "Team sits under Playtest")
	check(absf(line.get_global_rect().position.y - founder.get_global_rect().position.y) < 48.0, "The team line sits with Founder")
	check(new_product != null and founder.get_global_rect().end.y <= new_product.get_global_rect().position.y, "Team sits above New Product")
	check(footer != null and founder.get_global_rect().end.y <= footer.get_global_rect().position.y and not founder.get_global_rect().intersects(footer.get_global_rect()) and not line.get_global_rect().intersects(footer.get_global_rect()), "Team does not overlap Hire")
	check(line.get_line_count() == 1, "The team line stays on one line")
	check(company_cash() == 0 and company_reputation() == 0 and int(developing().get("devDays", -1)) == 0, "The team offer has not spent cash")
	var header := label_named("OfficeDate")
	check(header != null and header.text.contains("$0.00") and header.text.contains("0 reputation"), "The header stays at $0 and 0 reputation")
	check(not main.job_panel._connection_panel.visible, "Team never opens Connect")
	await snap("78-team-offer", line)
	await click(mina)
	var shown := await wait_until(func() -> bool:
		return not main.company_panel.busy and label_named("TeamOffer") != null and label_named("TeamOffer").text == "Team: Founder, Mina"
	, "Mina joins the team")
	if not shown:
		return
	line = label_named("TeamOffer")
	founder = main.company_panel.find_child("Team_founder", true, false) as Button
	mina = main.company_panel.find_child("Team_mira", true, false) as Button
	await reveal(line)
	new_product = button_named("New Product")
	footer = main.company_panel._footer
	check(founder != null and str(founder.get_meta("cozy_variant", "")) == "secondary", "Founder stays secondary after the change")
	check(mina != null and str(mina.get_meta("cozy_variant", "")) == "secondary", "Mina stays secondary after the change")
	check(new_product != null and line.get_global_rect().end.y <= new_product.get_global_rect().position.y, "The changed team line sits above New Product")
	check(footer != null and line.get_global_rect().end.y <= footer.get_global_rect().position.y and not line.get_global_rect().intersects(footer.get_global_rect()) and not mina.get_global_rect().intersects(footer.get_global_rect()), "The changed team line does not overlap Hire")
	check(line.get_line_count() == 1, "The changed team line stays on one line")
	check(company_cash() == 0 and company_reputation() == 0 and int(developing().get("devDays", -1)) == 0, "Assigning the team changes no cash or day")
	var team_block: Variant = developing().get("team", null)
	check(team_block is Dictionary and bool((team_block as Dictionary).get("enabled", false)), "The payload team stays enabled")
	check(not main.job_panel._connection_panel.visible, "The changed team never opens Connect")
	await snap("79-team-changed", line)

func seed_research_spike_offer(data_dir: String) -> bool:
	var database := ProjectSettings.globalize_path("res://../harness/src/database.ts")
	var tsx := ProjectSettings.globalize_path("res://../harness/node_modules/tsx/dist/cli.mjs")
	var node := OS.get_environment("STARTUP_VALLEY_NODE").strip_edges()
	if node.is_empty():
		for dir: String in OS.get_environment("PATH").split(":"):
			if FileAccess.file_exists(dir.path_join("node")):
				node = dir.path_join("node")
				break
	if node.is_empty():
		node = "/home/box/.local/node22/bin/node"
	var script_path := data_dir.path_join("seed-spike.mjs")
	var script := "import { mkdirSync } from 'node:fs';\nimport { GameDatabase } from %s;\nconst root = process.argv[process.argv.length - 1];\nmkdirSync(root + '/company-project', { recursive: true });\nconst db = new GameDatabase(root + '/startup-valley.sqlite', root + '/company-project');\ndb.tycoon.start('crypto', 'newsletter', []);\nconst view = db.tycoon.view().developing;\nconst company = db.journey.state().company;\ndb.close();\nconst offer = view && view.researchSpike;\nif (company.cashCents !== 0 || company.reputation !== 0 || !view || view.devDays !== 0 || !offer || offer.enabled !== true || offer.pending !== false || offer.used !== false || offer.reason !== '' || offer.points !== 0) { console.error(JSON.stringify({ company: company, view: view })); process.exit(2); }\n" % JSON.stringify(database)
	var file := FileAccess.open(script_path, FileAccess.WRITE)
	if file == null:
		check(false, "Could not write the research spike seed script")
		return false
	file.store_string(script)
	file.close()
	var output: Array = []
	var code := OS.execute(node, PackedStringArray([tsx, script_path, data_dir]), output, true)
	check(code == 0, "Seeded a day-zero newsletter with Research spike (%s)" % " ".join(output))
	return code == 0

func _research_spike_proof() -> void:
	var seeded := OS.get_temp_dir().path_join("startup-valley-proof-spike-%d-%d" % [OS.get_process_id(), Time.get_ticks_usec()])
	DirAccess.make_dir_recursive_absolute(seeded)
	if not seed_research_spike_offer(seeded):
		return
	await release_company()
	OS.set_environment("STARTUP_VALLEY_DATA_DIR", seeded)
	if not await boot_company():
		return
	var enter := button_named("Continue")
	if enter == null:
		enter = button_named("Start company")
	if enter != null:
		await click(enter)
	await dismiss_onboarding()
	await open_journey()
	var line := label_named("ResearchSpikeOffer")
	var card := main.company_panel.find_child("PublisherCard", true, false) as Control
	var spike := main.company_panel.find_child("ResearchSpike", true, false) as Button
	var team := label_named("TeamOffer")
	check(card != null and line != null and spike != null and card.is_ancestor_of(line) and card.is_ancestor_of(spike) and line.text == "Research spike · tomorrow's craft becomes research points", "The journey card names the research spike")
	check(not spike.disabled and str(spike.get_meta("cozy_variant", "")) == "secondary" and spike.text == "Research spike", "Research spike is a secondary button")
	var hire := button_named("Hire Mina")
	check(hire != null and str(hire.get_meta("cozy_variant", "")) == "primary", "Hire Mina stays the one primary action beside the spike")
	await reveal(line)
	var footer := main.company_panel._footer
	var new_product := button_named("New Product")
	check(team != null and team.get_global_rect().end.y <= line.get_global_rect().position.y + 1.0, "Research spike sits under Team")
	check(absf(line.get_global_rect().position.y - spike.get_global_rect().position.y) < 48.0, "The spike line sits with Research spike")
	check(new_product != null and spike.get_global_rect().end.y <= new_product.get_global_rect().position.y, "Research spike sits above New Product")
	check(footer != null and spike.get_global_rect().end.y <= footer.get_global_rect().position.y and not spike.get_global_rect().intersects(footer.get_global_rect()) and not line.get_global_rect().intersects(footer.get_global_rect()), "Research spike does not overlap Hire")
	check(line.get_line_count() == 1, "The spike line stays on one line")
	check(company_cash() == 0 and company_reputation() == 0 and int(developing().get("devDays", -1)) == 0, "The spike offer has not spent cash")
	var header := label_named("OfficeDate")
	check(header != null and header.text.contains("$0.00") and header.text.contains("0 reputation"), "The header stays at $0 and 0 reputation")
	check(not main.job_panel._connection_panel.visible, "Research spike never opens Connect")
	await snap("80-spike-offer", line)
	await click(spike)
	var armed := await wait_until(func() -> bool:
		return not main.company_panel.busy and label_named("ResearchSpikeOffer") != null and label_named("ResearchSpikeOffer").text == "Spike set · tomorrow's craft becomes research points" and main.company_panel.find_child("ResearchSpike", true, false) == null
	, "Research spike marks tomorrow")
	if not armed:
		return
	await end_office_day()
	await open_journey()
	line = label_named("ResearchSpikeOffer")
	await reveal(line)
	new_product = button_named("New Product")
	footer = main.company_panel._footer
	spike = main.company_panel.find_child("ResearchSpike", true, false) as Button
	check(line != null and line.text == "Spike done · +6 research points" and spike == null, "The spike day shows the gained research points")
	check(new_product != null and line.get_global_rect().end.y <= new_product.get_global_rect().position.y, "The done line sits above New Product")
	check(footer != null and line.get_global_rect().end.y <= footer.get_global_rect().position.y and not line.get_global_rect().intersects(footer.get_global_rect()), "The done line does not overlap Hire")
	check(line.get_line_count() == 1, "The done line stays on one line")
	check(int(developing().get("devDays", -1)) == 1 and int(developing().get("design", -1)) == 0 and int(developing().get("tech", -1)) == 0 and int(developing().get("hype", -1)) == 0, "The spike day counts and converts craft")
	var points := label_named("ResearchPoints")
	check(points != null and points.text == "7 research points", "The Research card shows 7 research points")
	check(company_cash() == 0 and company_reputation() == 0, "The spike day leaves cash and fans")
	header = label_named("OfficeDate")
	check(header != null and header.text.contains("Spring 2") and header.text.contains("$0.00") and header.text.contains("0 reputation"), "The header stays at $0 and 0 reputation on Spring 2")
	check(not main.job_panel._connection_panel.visible, "The spike day never opens Connect")
	await snap("81-spike-done", line)

func seed_sale_price_offer(data_dir: String) -> bool:
	var database := ProjectSettings.globalize_path("res://../harness/src/database.ts")
	var tsx := ProjectSettings.globalize_path("res://../harness/node_modules/tsx/dist/cli.mjs")
	var node := OS.get_environment("STARTUP_VALLEY_NODE").strip_edges()
	if node.is_empty():
		for dir: String in OS.get_environment("PATH").split(":"):
			if FileAccess.file_exists(dir.path_join("node")):
				node = dir.path_join("node")
				break
	if node.is_empty():
		node = "/home/box/.local/node22/bin/node"
	var script_path := data_dir.path_join("seed-sale-price.mjs")
	var script := "import { mkdirSync } from 'node:fs';\nimport { GameDatabase } from %s;\nconst root = process.argv[process.argv.length - 1];\nmkdirSync(root + '/company-project', { recursive: true });\nconst file = root + '/startup-valley.sqlite';\nconst db = new GameDatabase(file, root + '/company-project');\ndb.tycoon.start('crypto', 'newsletter', []);\ndb.endDay(1);\ndb.endDay(2);\ndb.tycoon.release('p1');\nconst product = db.tycoon.view().history[0];\nconst company = db.journey.state().company;\ndb.close();\nconst offer = product && product.salePrice;\nif (company.cashCents !== 20700 || company.reputation !== 5 || !product || product.status !== 'released' || product.salesCents !== 20700 || product.fans !== 5 || product.pricePercent !== 100 || !offer || offer.enabled !== true || offer.used !== false || offer.currentPercent !== 100 || offer.reason !== '') { console.error(JSON.stringify({ company: company, product: product })); process.exit(2); }\n" % JSON.stringify(database)
	var file := FileAccess.open(script_path, FileAccess.WRITE)
	if file == null:
		check(false, "Could not write the sale price seed script")
		return false
	file.store_string(script)
	file.close()
	var output: Array = []
	var code := OS.execute(node, PackedStringArray([tsx, script_path, data_dir]), output, true)
	check(code == 0, "Seeded a selling newsletter at $207 with a sale price offer (%s)" % " ".join(output))
	return code == 0

func _sale_price_proof() -> void:
	var seeded := OS.get_temp_dir().path_join("startup-valley-proof-sale-price-%d-%d" % [OS.get_process_id(), Time.get_ticks_usec()])
	DirAccess.make_dir_recursive_absolute(seeded)
	if not seed_sale_price_offer(seeded):
		return
	await release_company()
	OS.set_environment("STARTUP_VALLEY_DATA_DIR", seeded)
	if not await boot_company():
		return
	var enter := button_named("Continue")
	if enter == null:
		enter = button_named("Start company")
	if enter != null:
		await click(enter)
	await dismiss_onboarding()
	await open_journey()
	var line := label_named("SalePriceOffer_p1")
	var card := main.company_panel.find_child("Selling_p1", true, false) as Control
	var cheap := main.company_panel.find_child("SalePrice_p1_80", true, false) as Button
	var premium := main.company_panel.find_child("SalePrice_p1_120", true, false) as Button
	var catalog := main.company_panel.find_child("SalePrice_p1_100", true, false) as Button
	check(card != null and line != null and cheap != null and premium != null and card.is_ancestor_of(line) and card.is_ancestor_of(cheap) and line.text == "Sale price · $9.00 · remaining days", "The Selling card names the sale price")
	check(catalog == null and not cheap.disabled and not premium.disabled and str(cheap.get_meta("cozy_variant", "")) == "secondary" and str(premium.get_meta("cozy_variant", "")) == "secondary" and cheap.text == "−20%" and premium.text == "+20%", "Sale price buttons are secondary and skip the current percent")
	var hire := button_named("Hire Mina")
	check(hire != null and str(hire.get_meta("cozy_variant", "")) == "primary", "Hire Mina stays the one primary action beside the sale price")
	var trailer := label_named("TrailerOffer_p1")
	var patch := button_named("Patch")
	await reveal(line)
	var footer := main.company_panel._footer
	check(trailer != null and trailer.get_global_rect().end.y <= line.get_global_rect().position.y + 1.0, "Sale price sits under the trailer")
	check(patch != null and cheap.get_global_rect().end.y <= patch.get_global_rect().position.y + 1.0, "Sale price sits above Patch")
	check(footer != null and not line.get_global_rect().intersects(footer.get_global_rect()) and not cheap.get_global_rect().intersects(footer.get_global_rect()) and not premium.get_global_rect().intersects(footer.get_global_rect()), "Sale price does not overlap Hire")
	check(line.get_line_count() == 1, "The sale price line stays on one line")
	check(company_cash() == 20700 and company_reputation() == 5, "The sale price offer has not spent cash or fans")
	var header := label_named("OfficeDate")
	check(header != null and header.text.contains("Spring 3") and header.text.contains("$207.00") and header.text.contains("5 reputation"), "The offer still shows Spring 3, $207, and 5 reputation")
	check(not main.job_panel._connection_panel.visible, "Sale price never opens Connect")
	await snap("82-saleprice-offer", line)
	await click(cheap)
	var changed := await wait_until(func() -> bool:
		return not main.company_panel.busy and label_named("SalePriceOffer_p1") != null and label_named("SalePriceOffer_p1").text == "Sale price · −20% · $7.20" and main.company_panel.find_child("SalePrice_p1_80", true, false) == null
	, "Sale price shows −20%")
	if not changed:
		return
	line = label_named("SalePriceOffer_p1")
	await reveal(line)
	patch = button_named("Patch")
	footer = main.company_panel._footer
	check(line.get_line_count() == 1, "The set line stays on one line")
	check(patch != null and line.get_global_rect().end.y <= patch.get_global_rect().position.y + 1.0, "The set line sits above Patch")
	check(footer != null and not line.get_global_rect().intersects(footer.get_global_rect()), "The set line does not overlap Hire")
	check(company_cash() == 20700 and company_reputation() == 5, "The sale price leaves cash and fans")
	header = label_named("OfficeDate")
	check(header != null and header.text.contains("Spring 3") and header.text.contains("$207.00") and header.text.contains("5 reputation"), "The header stays at Spring 3, $207, and 5 reputation")
	check(not main.job_panel._connection_panel.visible, "The sale price never opens Connect")
	await snap("83-saleprice-set", line)

func _proof_money(cents: int) -> String:
	var integer := str(absi(cents) / 100)
	var grouped := ""
	for index: int in range(integer.length()):
		if index > 0 and (integer.length() - index) % 3 == 0:
			grouped += ","
		grouped += integer[index]
	return grouped + ".%02d" % (absi(cents) % 100)

func _office_expansion_proof() -> void:
	var seeded := OS.get_temp_dir().path_join("startup-valley-proof-office-%d-%d" % [OS.get_process_id(), Time.get_ticks_usec()])
	DirAccess.make_dir_recursive_absolute(seeded)
	if not seed_team(seeded):
		return
	await release_company()
	OS.set_environment("STARTUP_VALLEY_DATA_DIR", seeded)
	if not await boot_company():
		return
	var continue_button := button_named("Continue")
	if continue_button != null:
		await click(continue_button)
	await dismiss_onboarding()
	await open_journey()
	var expand := button_named("Expand office")
	check(expand != null and not expand.disabled, "Expand office is enabled for the seeded team")
	check(label_named("OfficeDesks") != null and label_named("OfficeDesks").text == "Desks: 3/4", "The seeded desk line is 3/4")
	await click(expand)
	await wait_until(func() -> bool:
		return not main.company_panel.busy and label_named("OfficeName") != null and label_named("OfficeName").text == "Open Floor"
	, "Expand office opens the Open Floor")
	await snap("14-office-expanded-card", main.company_panel.find_child("OfficeCard", true, false) as Control)
	main.company_panel.hide()
	await frames(8)
	var visible_spares := 0
	for id: String in ["spare-compact-a", "spare-compact-b", "spare-workbench"]:
		var node := main.room.prop_node(id)
		if node != null and node.visible:
			visible_spares += 1
	check(visible_spares == 3, "The Open Floor shows the two compact desks and the shared workbench")
	check(main.room.prop_node("founder-workstation") != null, "The founder desk stays beside the new desks")
	await snap("15-office-new-desks")

func _finish() -> void:
	print("PROOF ", "PASS" if failures.is_empty() else "FAIL %d" % failures.size())
	for failure: String in failures:
		print("FAILURE ", failure)
	var exit_code := 0 if failures.is_empty() else 1
	if main != null:
		main.notification(Node.NOTIFICATION_WM_CLOSE_REQUEST)
		await create_timer(1.2).timeout
	quit(exit_code)
