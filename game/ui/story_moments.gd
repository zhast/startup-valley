class_name StoryMoments
extends RefCounted
## Read-only character dialogue. Product and hiring rules stay in the worker.

static func introduction(employee_id: String) -> String:
	match employee_id:
		"mira": return "I turn little ideas into things people love. Let’s make one!"
		"theo": return "Give me a desk and a tricky problem. I think we could build something worth staying up for."
		"creative": return "This place has potential. A little colour, a good idea… I can already picture it."
		_: return "A new desk, a fresh start. I’m glad there’s room for me here."

static func role(employee_id: String) -> String:
	match employee_id:
		"mira": return "Product designer"
		"theo": return "Growth & operations"
		"creative": return "Artist & storyteller"
		_: return "Your teammate"

static func portrait(employee_id: String) -> Texture2D:
	# Face and shoulders from our existing character art, with an integer crop.
	var texture := CharacterArt.bust_portrait(employee_id)
	texture.region.size.y = minf(texture.region.size.y, 128.0)
	return texture

static func conversation(employee_id: String, state: Dictionary) -> Dictionary:
	var tycoon: Dictionary = state.get("tycoon", {})
	var product: Dictionary = tycoon.get("developing", {}) if tycoon.get("developing") is Dictionary else {}
	if not product.is_empty():
		if bool(product.get("ready", false)):
			return {"line": "We made it! Ready to show everyone?", "action": "See what we made"}
		return {"line": "It’s taking shape. Come see what we’re making!", "action": "See our project"}
	if not (tycoon.get("history", []) as Array).is_empty():
		return {"line": "Our first release! I’m already dreaming about the next one.", "action": "Plan our next project"}
	var line := "I saved you a page. What shall we make together?"
	if employee_id != "mira": line = introduction(employee_id)
	return {"line": line, "action": "Plan our first project"}

static func goal(state: Dictionary) -> Dictionary:
	if state.is_empty(): return {}
	var tycoon: Dictionary = state.get("tycoon", {})
	var product: Dictionary = tycoon.get("developing", {}) if tycoon.get("developing") is Dictionary else {}
	var history: Array = tycoon.get("history", []) as Array
	var hired := false
	for candidate: Dictionary in state.get("candidates", []):
		if bool(candidate.get("hired", false)): hired = true
	var completed := 4 if not history.is_empty() else 3 if bool(product.get("ready", false)) else 2 if not product.is_empty() else 1 if hired else 0
	var result := {"chapter": "A studio begins", "completed": completed, "total": 4, "mode": "product"}
	if not hired:
		result.merge({"title": "Welcome Mina", "detail": "Your first teammate is waiting at the door.", "action": "Meet Mina", "mode": "journey"}, true)
	elif not product.is_empty():
		if bool(product.get("ready", false)):
			result.merge({"title": "Share what you made", "detail": "Your project is ready. Time for its big day!", "action": "Release our project"})
		else:
			result.merge({"title": "Bring your idea to life", "detail": "Day %d of %d · %d%% ready" % [int(product.get("devDays", 0)), int(product.get("devDaysRequired", 1)), int(product.get("progress", 0))], "action": "Continue our project"})
	elif history.is_empty():
		result.merge({"title": "Choose your first project", "detail": "One small idea, made together with Mina.", "action": "Plan with Mina"})
	else:
		result.merge({"title": "Dream a little bigger", "detail": "First release complete! What will you make next?", "action": "Plan our next project"})
	return result

static func milestones(state: Dictionary) -> Array[Dictionary]:
	var current := goal(state)
	var completed := int(current.get("completed", 0))
	var result: Array[Dictionary] = []
	var names := ["A teammate arrives", "An idea takes shape", "Ready for the world", "Our first release"]
	for index: int in range(names.size()):
		result.append({"title": names[index], "complete": index < completed, "current": index == completed})
	return result
