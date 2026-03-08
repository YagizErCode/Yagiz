extends Node
class_name CharacterSystem
## Manages characters, dynasties, and their influence.

@onready var gs: Node = get_node("/root/GameState")


func character_tick() -> void:
	if gs.is_event_modal_open:
		return

	for cid in gs.characters:
		var ch: Dictionary = gs.characters[cid]
		if not ch.alive:
			continue
		_apply_character_influence(ch)

	# Random character events
	if gs.rng.randf() < 0.05:
		_random_character_event()


func _apply_character_influence(ch: Dictionary) -> void:
	if not ch.is_ruler or ch.kingdom_id < 0:
		return
	if ch.kingdom_id not in gs.kingdoms:
		return

	var kingdom_id: int = ch.kingdom_id
	# Ruler stats affect kingdom cities
	for cid in gs.cities:
		var city: Dictionary = gs.cities[cid]
		if city.kingdom_id != kingdom_id:
			continue
		# Learning boosts education
		city.education = minf(100.0, city.education + ch.learning * 0.01)
		# Diplomacy boosts stability
		city.stability = minf(100.0, city.stability + ch.diplomacy * 0.005)
		# Martial boosts security
		city.security = minf(100.0, city.security + ch.martial * 0.005)
		# Traits
		if "zealous" in ch.traits:
			if city.faith_share > 0.1:
				city.faith_share = minf(1.0, city.faith_share + 0.002)
		if "cynical" in ch.traits:
			city.faith_share = maxf(0.0, city.faith_share - 0.001)
		if "just" in ch.traits:
			city.stability = minf(100.0, city.stability + 0.1)
		if "cruel" in ch.traits:
			city.stability = maxf(0.0, city.stability - 0.1)


func _random_character_event() -> void:
	var ids := gs.characters.keys()
	if ids.is_empty():
		return
	var ch_id: int = ids[gs.rng.randi() % ids.size()]
	var ch: Dictionary = gs.characters[ch_id]
	if not ch.alive:
		return

	var roll := gs.rng.randf()
	if roll < 0.02:
		# Death
		ch.alive = false
		gs.log_chronicle("%s of House %s has died." % [ch.name, ch.dynasty])
		if ch.is_ruler and ch.kingdom_id in gs.kingdoms:
			_succession(ch.kingdom_id)
	elif roll < 0.05:
		# Gain trait
		var new_traits := ["zealous", "brave", "wise", "charitable", "patient"]
		var t: String = new_traits[gs.rng.randi() % new_traits.size()]
		if t not in ch.traits:
			ch.traits.append(t)
			gs.log_chronicle("%s gained the '%s' trait." % [ch.name, t])
	elif roll < 0.08:
		# Stat change
		var stats := ["learning", "martial", "intrigue", "diplomacy"]
		var s: String = stats[gs.rng.randi() % stats.size()]
		ch[s] = clampi(ch[s] + gs.rng.randi_range(-2, 3), 1, 25)


func _succession(kingdom_id: int) -> void:
	# Create new ruler
	var new_ruler := gs.create_character(kingdom_id, true)
	gs.kingdoms[kingdom_id].ruler_id = new_ruler.id
	gs.log_chronicle("%s of House %s ascends the throne of %s" % [
		new_ruler.name, new_ruler.dynasty, gs.kingdoms[kingdom_id].name])

	# Succession instability
	for cid in gs.cities:
		if gs.cities[cid].kingdom_id == kingdom_id:
			gs.cities[cid].stability = maxf(0.0, gs.cities[cid].stability - 10.0)


func get_ruler_of(kingdom_id: int) -> Dictionary:
	if kingdom_id not in gs.kingdoms:
		return {}
	var ruler_id: int = gs.kingdoms[kingdom_id].ruler_id
	if ruler_id in gs.characters:
		return gs.characters[ruler_id]
	return {}
