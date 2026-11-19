extends SceneTree

## Headless feature offer with the real worker and an isolated company.
## Skipping the feature leaves the first newsletter alone. Adding it costs one office day.

const MAIN := preload("res://world/main.tscn")
const OFFER := "Feature · TownSquare Bonus Drop · +1 office day, +10% opening demand"
const ADDED := "Feature added · TownSquare Bonus Drop · Building · day 0 of 3"
var main: GameMain
var viewport: SubViewport
var failures: Array[String] = []
var data_dir := ""

func _initialize() -> void:
	OS.unset_environment("STARTUP_VALLEY_NO_WORKER")
	OS.unset_environment("STARTUP_VALLEY_FAKE_PROVIDER")
	OS.set_environment("STARTUP_VALLEY_IGNORE_HOST_CREDENTIALS", "1")
	data_dir = OS.get_temp_dir().path_join("startup-valley-tycoon-feature-%d-%d" % [OS.get_process_id(), Time.get_ticks_usec()])
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

func company_cash() -> int:
	if main == null or main.company_panel == null:
		return 0
	var company: Dictionary = main.company_panel.state.get("company", {}) if main.company_panel.state.get("company") is Dictionary else {}
	return int(company.get("cashCents", 0))

func company_reputation() -> int:
	if main == null or main.company_panel == null:
		return 0
	var company: Dictionary = main.company_panel.state.get("company", {}) if main.company_panel.state.get("company") is Dictionary else {}
	return int(company.get("reputation", 0))

func tycoon_state() -> Dictionary:
	if main == null or main.company_panel == null:
		return {}
	var value: Variant = main.company_panel.state.get("tycoon", {})
	return value as Dictionary if value is Dictionary else {}

func developing() -> Dictionary:
	var value: Variant = tycoon_state().get("developing", {})
	return value as Dictionary if value is Dictionary else {}

func latest_shipped() -> Dictionary:
	var history: Array = tycoon_state().get("history", []) as Array
	if history.is_empty() or not history[0] is Dictionary:
		return {}
	return history[0] as Dictionary

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

func start_newsletter() -> void:
	await open_product()
	check(label_named("FeatureOffer") == null, "The product picker has no feature line")
	await click(button_named("Crypto Alpha"))
	await frames(4)
	await click(button_named("Newsletter"))
	await frames(4)
	await click(button_named("Start development"))
	await wait_until(func() -> bool: return developing().get("name", "") == "Crypto Alpha Newsletter" and not main.company_panel.busy, "Development starts on Crypto Alpha Newsletter")

func boot() -> bool:
	main = MAIN.instantiate()
	main.demo_story_mode = false
	viewport.add_child(main)
	var ready := await wait_until(func() -> bool:
		return main._state_loaded and main._worker_ready and main.company_panel != null and main.company_panel.visible and not main.company_panel.state.is_empty()
	, "Worker bootstrap loads the company")
	if ready:
		main.day_clock.set_speed(0)
	return ready

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

func continue_company() -> void:
	var enter := button_named("Continue")
	if enter == null:
		enter = button_named("Start company")
	if enter != null:
		await click(enter)
	await dismiss_onboarding()
	await open_journey()

func node_bin() -> String:
	var node := OS.get_environment("STARTUP_VALLEY_NODE").strip_edges()
	if node.is_empty():
		for dir: String in OS.get_environment("PATH").split(":"):
			if FileAccess.file_exists(dir.path_join("node")):
				node = dir.path_join("node")
				break
	if node.is_empty():
		node = "/home/box/.local/node22/bin/node"
	return node

func rules_hold() -> bool:
	var database := ProjectSettings.globalize_path("res://../harness/src/database.ts")
	var tycoon := ProjectSettings.globalize_path("res://../harness/src/tycoon.ts")
	var tsx := ProjectSettings.globalize_path("res://../harness/node_modules/tsx/dist/cli.mjs")
	var root := data_dir.path_join("rules")
	DirAccess.make_dir_recursive_absolute(root)
	var script_path := root.path_join("check-features.mjs")
	var body := """import { mkdirSync } from 'node:fs';
import { GameDatabase } from %s;
import { EVENT_BONUS_FANS, FEATURE_DAY_DELTA, FEATURE_NAME, FEATURE_UNIT_PERCENT, LOCALIZE_COST_CENTS, LOCALIZE_UNIT_PERCENT, PORT_COST_CENTS, RIVAL_UNIT_PERCENT, SALES_WINDOW_DAYS, SEASON_UNIT_BOOST_PERCENT, calendarForDay, openingDemand, requiredDevDays, salesForDay } from %s;
const root = process.argv[process.argv.length - 1];
function fail(detail) { console.error(JSON.stringify(detail)); process.exit(2); }
function open(name) {
  const dir = root + '/' + name;
  mkdirSync(dir + '/company-project', { recursive: true });
  return new GameDatabase(dir + '/startup-valley.sqlite', dir + '/company-project');
}
function staff(db, id) {
  const row = db.journey.db.prepare('SELECT staff_json FROM tycoon_products WHERE id = ?').get(id);
  return JSON.parse(String(row.staff_json));
}
function message(fn) {
  try { fn(); return ''; } catch (error) { return error.message; }
}
function sale(db, dayIndex, reputation, day, extra = {}) {
  const product = [...(db.tycoon.view().developing ? [db.tycoon.view().developing] : []), ...db.tycoon.view().history].find((item) => item.id === 'p1');
  const calendar = calendarForDay(day);
  return salesForDay({
    seed: db.tycoon.view().seed,
    productId: 'p1',
    typeId: product.typeId,
    fit: product.fit,
    score: product.review.score,
    dayIndex,
    reputation,
    unitBoostPercent: calendar.favoredTopics.some((topic) => topic.id === product.topicId) ? SEASON_UNIT_BOOST_PERCENT : 0,
    bonusFans: calendar.event ? EVENT_BONUS_FANS : 0,
    featureDemand: extra.featureDemand ?? true,
    ...(extra.quietPercent === undefined ? {} : { quietPercent: extra.quietPercent }),
  });
}
if (FEATURE_NAME !== 'TownSquare Bonus Drop' || FEATURE_DAY_DELTA !== 1 || FEATURE_UNIT_PERCENT !== 110) fail({ FEATURE_NAME, FEATURE_DAY_DELTA, FEATURE_UNIT_PERCENT });
if (requiredDevDays(2, false) !== 2 || requiredDevDays(2, false, null, true) !== 3 || requiredDevDays(2, false, 'long', true) !== 4 || requiredDevDays(2, true, null, true) !== 2) fail('days');
const base = openingDemand('great', 6, 0);
const featured = Math.max(1, Math.round((base * 110) / 100));
if (openingDemand('great', 6, 0, false, true) !== featured) fail({ base, featured });
if (openingDemand('great', 6, 0, true, true) !== Math.max(1, Math.round((featured * RIVAL_UNIT_PERCENT) / 100))) fail('order');
const bare = open('bare');
if (message(() => bare.tycoon.addFeature()) !== 'No product is on the bench.') fail('bare');
bare.close();
const skip = open('skip');
skip.tycoon.start('crypto', 'newsletter', []);
if (skip.tycoon.view().developing.feature.added !== false || skip.tycoon.view().developing.devDaysRequired !== 2 || staff(skip, 'p1').feature === true) fail(staff(skip, 'p1'));
skip.endDay(1);
skip.endDay(2);
skip.tycoon.release('p1');
if (skip.journey.state().company.cashCents !== 20700 || skip.tycoon.view().history[0].fans !== 5 || skip.tycoon.view().history[0].feature !== null || staff(skip, 'p1').featureDemand === true) fail({ cash: skip.journey.state().company.cashCents, fans: skip.tycoon.view().history[0].fans });
skip.endDay(3);
skip.endDay(4);
if (skip.journey.state().company.cashCents !== 33300 || message(() => skip.tycoon.addFeature()) !== 'No product is on the bench.') fail({ next: skip.journey.state().company.cashCents });
const featureRows = skip.journey.db.prepare(\"SELECT id FROM company_transactions WHERE id LIKE 'tycoon:feature%%'\").all();
if (featureRows.length !== 0) fail(featureRows);
skip.close();
const added = open('added');
added.tycoon.start('crypto', 'newsletter', []);
const cashBefore = added.journey.state().company.cashCents;
added.tycoon.addFeature();
if (added.clockState().day !== 1 || added.journey.state().company.cashCents !== cashBefore || added.tycoon.view().developing.devDays !== 0 || added.tycoon.view().developing.devDaysRequired !== 3 || added.tycoon.view().developing.ready !== false || staff(added, 'p1').feature !== true || staff(added, 'p1').featureDemand === true || staff(added, 'p1').size !== undefined) fail(staff(added, 'p1'));
if (message(() => added.tycoon.addFeature()) !== 'Already added.') fail('second');
if (added.tycoon.view().developing.devDaysRequired !== 3) fail('still');
added.endDay(1);
added.endDay(1);
if (added.clockState().day !== 2 || added.tycoon.view().developing.devDays !== 1) fail({ day: added.clockState().day, dev: added.tycoon.view().developing.devDays });
added.endDay(2);
if (message(() => added.tycoon.release('p1')) !== 'Keep building. This product needs 1 more office day.') fail('early');
added.endDay(3);
added.tycoon.release('p1');
const opened = added.tycoon.view().history[0];
const releaseDay = added.clockState().day;
const bumped = sale(added, 0, 0, releaseDay);
const plain = sale(added, 0, 0, releaseDay, { featureDemand: false });
if (!(bumped.cents > plain.cents) || opened.salesCents !== bumped.cents || opened.fans !== bumped.fans || opened.review.score !== 6 || staff(added, 'p1').featureDemand !== true || opened.feature.added !== true || opened.size !== null) fail({ bumped, plain, opened });
const releaseCents = added.journey.state().company.cashCents;
const releaseFans = added.journey.state().company.reputation;
added.tycoon.tickDay(releaseDay);
added.endDay(releaseDay);
added.endDay(releaseDay);
if (added.clockState().day !== releaseDay + 1 || added.journey.state().company.cashCents !== releaseCents || added.tycoon.view().history[0].salesCents !== releaseCents) fail('replay');
const dayOne = sale(added, 1, releaseFans, releaseDay + 1);
added.endDay(releaseDay + 1);
const fansAfter = releaseFans + dayOne.fans;
const dayTwo = sale(added, 2, fansAfter, releaseDay + 2);
added.endDay(releaseDay + 2);
const fansAfterTwo = fansAfter + dayTwo.fans;
const dayThree = sale(added, 3, fansAfterTwo, releaseDay + 3);
added.endDay(releaseDay + 3);
const windowCents = releaseCents + dayOne.cents + dayTwo.cents + dayThree.cents;
if (added.tycoon.view().history[0].salesCents !== windowCents || added.tycoon.view().history[0].status !== 'complete') fail({ sales: added.tycoon.view().history[0].salesCents, windowCents });
const portDay = added.clockState().day;
const beforePort = added.journey.state().company.cashCents;
added.tycoon.port('p1');
const portSale = sale(added, SALES_WINDOW_DAYS, fansAfterTwo + dayThree.fans, portDay);
added.endDay(portDay);
const ported = added.tycoon.view().history[0];
if (ported.port.cents !== portSale.cents || added.journey.state().company.cashCents !== beforePort - PORT_COST_CENTS + portSale.cents) fail({ ported: ported.port, portSale, cash: added.journey.state().company.cashCents });
const locDay = added.clockState().day;
const afterPortCash = added.journey.state().company.cashCents;
const afterPortFans = added.journey.state().company.reputation;
added.tycoon.localize('p1');
const locSale = sale(added, SALES_WINDOW_DAYS, afterPortFans, locDay, { quietPercent: LOCALIZE_UNIT_PERCENT });
added.endDay(locDay);
const translated = added.tycoon.view().history[0];
if (translated.localization.cents !== locSale.cents || added.journey.state().company.cashCents !== afterPortCash - LOCALIZE_COST_CENTS + locSale.cents || staff(added, 'p1').featureDemand !== true) fail({ loc: translated.localization, locSale });
const saved = added.journey.state().company.cashCents;
const savedSales = translated.salesCents;
const file = root + '/added/startup-valley.sqlite';
const project = root + '/added/company-project';
added.close();
const reopened = new GameDatabase(file, project);
reopened.endDay(locDay);
if (reopened.journey.state().company.cashCents !== saved || reopened.tycoon.view().history[0].salesCents !== savedSales || staff(reopened, 'p1').featureDemand !== true || message(() => reopened.tycoon.addFeature()) !== 'No product is on the bench.') fail('reopen');
reopened.tycoon.start('fitness', 'newsletter', []);
if (reopened.tycoon.view().developing.feature.added !== false || reopened.tycoon.view().developing.devDaysRequired !== 2) fail('next');
reopened.tycoon.addFeature();
if (reopened.tycoon.view().developing.devDaysRequired !== 3 || reopened.tycoon.view().history.find((item) => item.id === 'p1').salesCents !== savedSales) fail('p2');
reopened.close();
const sequel = open('sequel');
sequel.tycoon.start('crypto', 'newsletter', []);
sequel.tycoon.addFeature();
sequel.endDay(1);
sequel.endDay(2);
sequel.endDay(3);
sequel.tycoon.release('p1');
const sequelDay = sequel.clockState().day;
sequel.endDay(sequelDay);
sequel.endDay(sequelDay + 1);
sequel.endDay(sequelDay + 2);
sequel.endDay(sequelDay + 3);
sequel.tycoon.sequel('p1');
if (sequel.tycoon.view().developing.devDaysRequired !== 1 || sequel.tycoon.view().developing.feature.added !== false || staff(sequel, 'p2').feature === true || staff(sequel, 'p1').featureDemand !== true) fail('inherit');
sequel.tycoon.addFeature();
if (sequel.tycoon.view().developing.devDaysRequired !== 2 || sequel.tycoon.view().developing.devDays !== 0) fail('sequel-add');
sequel.close();
""" % [JSON.stringify(database), JSON.stringify(tycoon)]
	var file := FileAccess.open(script_path, FileAccess.WRITE)
	if file == null:
		check(false, "Could not write the feature rules script")
		return false
	file.store_string(body)
	file.close()
	var output: Array = []
	var code := OS.execute(node_bin(), PackedStringArray([tsx, script_path, root]), output, true)
	check(code == 0, "Feature rules hold (%s)" % " ".join(output))
	return code == 0

func _run() -> void:
	root.content_scale_size = Vector2i(1280, 720)
	root.size = Vector2i(1280, 720)
	viewport = SubViewport.new()
	viewport.size = Vector2i(1280, 720)
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(viewport)
	viewport.notify_mouse_entered()
	if not rules_hold():
		_finish()
		return
	if not await boot():
		_finish()
		return
	await click(button_named("Start company"))
	await wait_until(func() -> bool: return main.company_panel.screen == "journey", "Start company opens Journey")
	check(label_named("FeatureOffer") == null, "No feature line before a product is on the bench")
	check(button_named("Add feature") == null, "No feature button before a product is on the bench")
	check(button_named("Hire Mina") != null and str(button_named("Hire Mina").get_meta("cozy_variant", "")) == "primary", "Hire Mina stays the one primary action")
	await start_newsletter()
	check(main.company_panel.screen == "product" and label_named("FeatureOffer") == null, "The build screen has no feature line")
	await open_journey()
	var offer := label_named("FeatureOffer")
	var card := main.company_panel.find_child("PublisherCard", true, false) as Control
	check(card != null and offer != null and card.is_ancestor_of(offer) and offer.text == OFFER, "The developing card names the feature offer")
	var add := button_named("Add feature")
	check(add != null and add.name == "AddFeature" and not add.disabled and str(add.get_meta("cozy_variant", "")) == "secondary", "Add feature is a secondary action")
	check(button_named("Hire Mina") != null and str(button_named("Hire Mina").get_meta("cozy_variant", "")) == "primary", "Hire Mina stays primary beside the offer")
	check(button_named("Sign publisher") != null and str(button_named("Sign publisher").get_meta("cozy_variant", "")) == "secondary", "Sign publisher stays secondary beside the feature")
	check(button_named("Show preview") != null and str(button_named("Show preview").get_meta("cozy_variant", "")) == "secondary", "Show preview stays secondary beside the feature")
	var new_product := button_named("New Product")
	check(new_product != null and add.get_global_rect().end.y <= new_product.get_global_rect().position.y, "Add feature sits above New Product")
	check(int(developing().get("devDaysRequired", 0)) == 2 and company_cash() == 0, "The offer does not change the two-day build or the cash")
	await end_office_day()
	await open_journey()
	await end_office_day()
	await open_journey()
	check(label_named("FeatureOffer") != null and label_named("FeatureOffer").text == OFFER and button_named("Add feature") != null, "Skipping the feature keeps the offer")
	await open_product()
	await click(button_named("Release"))
	var released := await wait_until(func() -> bool: return main.company_panel.screen == "release" and company_cash() == 20700, "Skipping the feature still pays 20700 cents")
	if released:
		check(company_reputation() == 5, "Skipping the feature still pays 5 fans")
		check(int(latest_shipped().get("salesCents", 0)) == 20700, "Skipping the feature keeps launch sales at 20700 cents")
		check(latest_shipped().get("feature") == null, "An unadded release has no feature")
		await open_journey()
		check(label_named("FeatureOffer") == null and button_named("Add feature") == null, "The offer is gone after release")
		await end_office_day()
		check(company_cash() == 20700, "The release day does not sell twice")
		await open_journey()
		await end_office_day()
		await open_journey()
		check(company_cash() == 33300, "The next office day is still 33300 cents")
		check(int(latest_shipped().get("salesCents", 0)) == 33300, "Feature-free sales stay on the old total")
	await release_company()
	OS.set_environment("STARTUP_VALLEY_DATA_DIR", data_dir)
	if not await boot():
		_finish()
		return
	await continue_company()
	check(company_cash() == 33300 and int(latest_shipped().get("salesCents", 0)) == 33300, "Reopening before a feature keeps 33300 cents")
	check(label_named("FeatureOffer") == null, "Reopening a shipped product still has no offer")
	await start_newsletter()
	await open_journey()
	check(label_named("FeatureOffer") != null and label_named("FeatureOffer").text == OFFER, "The next product offers the feature again")
	add = button_named("Add feature")
	check(add != null and str(add.get_meta("cozy_variant", "")) == "secondary", "Add feature stays secondary on the next product")
	var cash_before := company_cash()
	var fans_before := company_reputation()
	await click(add)
	await wait_until(func() -> bool:
		return not main.company_panel.busy and label_named("FeatureOffer") != null and label_named("FeatureOffer").text == ADDED and int(developing().get("devDaysRequired", 0)) == 3
	, "Adding the feature shows the day line and needs 3 office days")
	check(button_named("Add feature") == null, "An added feature hides the button")
	check(company_cash() == cash_before and company_reputation() == fans_before, "Adding the feature does not change cash or fans")
	check(int(developing().get("devDays", -1)) == 0, "Adding the feature does not spend a dev day")
	check(int(latest_shipped().get("salesCents", 0)) == 33300, "The feature does not change the earlier sale")
	check(button_named("Hire Mina") != null and str(button_named("Hire Mina").get_meta("cozy_variant", "")) == "primary", "Hire Mina stays primary after the feature")
	var feature: Dictionary = developing().get("feature", {}) if developing().get("feature") is Dictionary else {}
	check(bool(feature.get("added", false)) and str(feature.get("name", "")) == "TownSquare Bonus Drop" and int(feature.get("dayDelta", 0)) == 1 and int(feature.get("unitPercent", 0)) == 110, "The worker stores the added feature")
	await release_company()
	OS.set_environment("STARTUP_VALLEY_DATA_DIR", data_dir)
	if not await boot():
		_finish()
		return
	await continue_company()
	check(label_named("FeatureOffer") != null and label_named("FeatureOffer").text == ADDED, "Reopening still shows the added line")
	check(button_named("Add feature") == null, "Reopening does not offer a second feature")
	check(int(developing().get("devDaysRequired", 0)) == 3 and int(developing().get("devDays", -1)) == 0, "Reopening keeps the extra office day")
	check(company_cash() == 33300 and int(latest_shipped().get("salesCents", 0)) == 33300, "Reopening keeps the earlier sale")
	print("TYCOON FEATURES ", "PASS" if failures.is_empty() else "FAIL %d" % failures.size())
	for failure: String in failures:
		print("FAILURE ", failure)
	_finish()

func _finish() -> void:
	var exit_code := 0 if failures.is_empty() else 1
	if main != null:
		main.notification(Node.NOTIFICATION_WM_CLOSE_REQUEST)
		await create_timer(1.2).timeout
	quit(exit_code)
