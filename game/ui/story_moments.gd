class_name StoryMoments
extends RefCounted
## Read-only character dialogue. Product and hiring rules stay in the worker.

static func introduction(employee_id: String) -> String:
	match employee_id:
		"mira": return "You found a whole office! I brought a notebook full of ideas. Want to make something together?"
		"theo": return "Give me a desk and a tricky problem. I think we could build something worth staying up for."
		"creative": return "This place has potential. A little colour, a good idea… I can already picture it."
		_: return "A new desk, a fresh start. I’m glad there’s room for me here."

static func conversation(employee_id: String, state: Dictionary) -> Dictionary:
	var tycoon: Dictionary = state.get("tycoon", {})
	var product: Dictionary = tycoon.get("developing", {}) if tycoon.get("developing") is Dictionary else {}
	if not product.is_empty():
		if bool(product.get("ready", false)):
			return {"line": "It’s ready. All those little ideas finally became something real. Shall we show everyone?", "action": "See what we made"}
		return {"line": "It’s starting to take shape. Let’s give this idea a little care each day and see where it goes.", "action": "See our project"}
	if not (tycoon.get("history", []) as Array).is_empty():
		return {"line": "Remember when this was just an empty room? Now we’ve put something out into the world. I have a few ideas for what comes next.", "action": "Plan our next project"}
	var line := "I saved you a page in my notebook. Let’s start with one small idea—something we’d be proud to put our names on."
	if employee_id != "mira": line = introduction(employee_id)
	return {"line": line, "action": "Plan our first project"}
