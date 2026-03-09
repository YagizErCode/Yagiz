extends Node
class_name EventSystemJSON
## Loads events from JSON, checks conditions, triggers events with modal pause.

signal event_display_requested(event_data: Dictionary)

@onready var gs: Node = get_node("/root/GameState")

var all_events: Array = []
var pending_chain_event: String = ""


func _ready() -> void:
	_load_events()


func _load_events() -> void:
	var path := "res://Resources/Events/events_pack.json"
	if not FileAccess.file_exists(path):
		push_warning("Events JSON not found at %s" % path)
		return

	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		push_warning("Could not open events JSON")
		return

	var json := JSON.new()
	var err := json.parse(file.get_as_text())
	file.close()
	if err != OK:
		push_warning("JSON parse error: %s" % json.get_error_message())
		return

	var data = json.data
	if data is Dictionary and data.has("events"):
		all_events = data["events"]
	elif data is Array:
		all_events = data
	print("Loaded %d events" % all_events.size())


func event_tick() -> void:
	if gs.is_event_modal_open:
		return

	# Check chain events first
	if not pending_chain_event.is_empty():
		var chain_ev := _find_event(pending_chain_event)
		if not chain_ev.is_empty():
			pending_chain_event = ""
			_trigger_event(chain_ev)
			return
		pending_chain_event = ""

	# Decrease cooldowns
	var expired: Array = []
	for eid in gs.event_cooldowns:
		gs.event_cooldowns[eid] -= 1
		if gs.event_cooldowns[eid] <= 0:
			expired.append(eid)
	for eid in expired:
		gs.event_cooldowns.erase(eid)

	# Random event check
	if gs.rng.randf() > 0.15:
		return

	# Find eligible events
	var eligible: Array[Dictionary] = []
	var total_weight := 0.0
	for ev in all_events:
		var eid: String = str(ev.get("id", ""))
		if eid in gs.event_cooldowns:
			continue
		if _check_conditions(ev):
			var w: float = float(ev.get("weight", 10))
			eligible.append(ev)
			total_weight += w

	if eligible.is_empty():
		return

	# Weighted random selection
	var roll := gs.rng.randf() * total_weight
	var cumulative := 0.0
	for ev in eligible:
		cumulative += float(ev.get("weight", 10))
		if roll <= cumulative:
			_trigger_event(ev)
			return


func _check_conditions(ev: Dictionary) -> bool:
	var conditions = ev.get("conditions", {})
	if not conditions is Dictionary:
		return true

	if conditions.has("min_turn") and gs.turn < int(conditions["min_turn"]):
		return false
	if conditions.has("min_faith_spread"):
		if gs.player_religion.spread_rate < float(conditions["min_faith_spread"]):
			return false
	if conditions.has("min_authority"):
		if gs.player_religion.authority < float(conditions["min_authority"]):
			return false
	if conditions.has("max_authority"):
		if gs.player_religion.authority > float(conditions["max_authority"]):
			return false
	if conditions.has("min_gold"):
		if gs.player_religion.gold < float(conditions["min_gold"]):
			return false
	if conditions.has("has_doctrine"):
		var doc_name: String = conditions["has_doctrine"]
		if not gs.player_religion.doctrines.get(doc_name, false):
			return false
	return true


func _trigger_event(ev: Dictionary) -> void:
	var eid: String = str(ev.get("id", ""))
	var cooldown: int = int(ev.get("cooldown", 5))
	gs.event_cooldowns[eid] = cooldown

	gs.is_event_modal_open = true
	gs.simulation_paused.emit()
	event_display_requested.emit(ev)
	gs.log_chronicle("Event: %s" % str(ev.get("title", "Unknown")))


func apply_choice(ev: Dictionary, choice_index: int) -> void:
	var choices: Array = ev.get("choices", [])
	if choice_index < 0 or choice_index >= choices.size():
		gs.is_event_modal_open = false
		gs.simulation_resumed.emit()
		return

	var choice: Dictionary = choices[choice_index]
	var effects: Dictionary = choice.get("effects", {})

	# Apply effects
	if effects.has("authority"):
		gs.player_religion.authority = clampf(
			gs.player_religion.authority + float(effects["authority"]), 0.0, 100.0)
	if effects.has("legitimacy"):
		gs.player_religion.legitimacy = clampf(
			gs.player_religion.legitimacy + float(effects["legitimacy"]), 0.0, 100.0)
	if effects.has("gold"):
		gs.player_religion.gold += float(effects["gold"])
	if effects.has("spread_rate"):
		gs.player_religion.spread_rate = clampf(
			gs.player_religion.spread_rate + float(effects["spread_rate"]), 0.0, 100.0)
	if effects.has("stability_all"):
		for cid in gs.cities:
			gs.cities[cid].stability = clampf(
				gs.cities[cid].stability + float(effects["stability_all"]), 0.0, 100.0)
	if effects.has("heresy_all"):
		for cid in gs.cities:
			gs.cities[cid].heresy_share = clampf(
				gs.cities[cid].heresy_share + float(effects["heresy_all"]), 0.0, 1.0)
	if effects.has("education_all"):
		for cid in gs.cities:
			gs.cities[cid].education = clampf(
				gs.cities[cid].education + float(effects["education_all"]), 0.0, 100.0)
	if effects.has("security_all"):
		for cid in gs.cities:
			gs.cities[cid].security = clampf(
				gs.cities[cid].security + float(effects["security_all"]), 0.0, 100.0)

	# Doctrine axis modifications
	for axis in ["tolerance", "militarism", "knowledge", "ritual", "commerce", "austerity", "charity"]:
		if effects.has(axis):
			gs.player_religion.axes[axis] = clampi(
				int(gs.player_religion.axes[axis]) + int(effects[axis]), 0, 100)

	gs.log_chronicle("Chose: %s" % str(choice.get("text", "?")))

	# Chain event
	var next_id = choice.get("next_event_id", "")
	if next_id is String and not next_id.is_empty():
		pending_chain_event = next_id
	elif next_id is float or next_id is int:
		pending_chain_event = str(next_id)

	gs.is_event_modal_open = false
	gs.simulation_resumed.emit()
	gs.faith_updated.emit()


func _find_event(event_id: String) -> Dictionary:
	for ev in all_events:
		if str(ev.get("id", "")) == event_id:
			return ev
	return {}
