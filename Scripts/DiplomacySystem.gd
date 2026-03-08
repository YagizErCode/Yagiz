extends Node
class_name DiplomacySystem
## Manages inter-kingdom diplomacy, pacts, and wars.

@onready var gs: Node = get_node("/root/GameState")

const PACT_NAP := "non_aggression"
const PACT_TRADE := "trade"
const PACT_TRIBUTE := "tribute"
const PACT_HOLY_WAR := "holy_war"


func diplomacy_tick() -> void:
	if gs.is_event_modal_open:
		return
	_ai_diplomacy()
	_process_wars()


func _ai_diplomacy() -> void:
	# AI kingdoms occasionally form/break pacts
	if gs.rng.randf() > 0.1:
		return

	var kingdom_ids := gs.kingdoms.keys()
	if kingdom_ids.size() < 2:
		return

	var k1_id: int = kingdom_ids[gs.rng.randi() % kingdom_ids.size()]
	var k2_id: int = kingdom_ids[gs.rng.randi() % kingdom_ids.size()]
	if k1_id == k2_id:
		return

	var k1: Dictionary = gs.kingdoms[k1_id]
	var relation: float = k1.relations.get(k2_id, 0.0)

	if relation > 30 and not _has_pact(k1_id, k2_id, PACT_NAP):
		_form_pact(k1_id, k2_id, PACT_NAP)
	elif relation > 50 and not _has_pact(k1_id, k2_id, PACT_TRADE):
		_form_pact(k1_id, k2_id, PACT_TRADE)
	elif relation < -40 and k2_id not in k1.at_war_with:
		_declare_war(k1_id, k2_id)

	# Relations drift
	for kid in kingdom_ids:
		var k: Dictionary = gs.kingdoms[kid]
		for other_id in k.relations:
			k.relations[other_id] += gs.rng.randf_range(-1.0, 1.0)
			k.relations[other_id] = clampf(k.relations[other_id], -100.0, 100.0)


func _process_wars() -> void:
	# AI raises armies and attacks during wars
	if gs.rng.randf() > 0.05:
		return

	for kid in gs.kingdoms:
		var k: Dictionary = gs.kingdoms[kid]
		if k.at_war_with.is_empty():
			continue
		# Find a city to raise army from
		var my_cities: Array[int] = []
		for cid in gs.cities:
			if gs.cities[cid].kingdom_id == kid:
				my_cities.append(cid)
		if my_cities.is_empty():
			continue

		var source_id: int = my_cities[gs.rng.randi() % my_cities.size()]
		var source: Dictionary = gs.cities[source_id]
		if source.population < 1000:
			continue

		# Find enemy city to target
		var enemy_kid: int = k.at_war_with[0]
		var enemy_cities: Array[int] = []
		for cid in gs.cities:
			if gs.cities[cid].kingdom_id == enemy_kid:
				enemy_cities.append(cid)
		if enemy_cities.is_empty():
			# War over, no cities left
			k.at_war_with.erase(enemy_kid)
			continue

		var target_id: int = enemy_cities[gs.rng.randi() % enemy_cities.size()]

		# Create AI army
		var army_size := gs.rng.randi_range(200, int(source.population * 0.3))
		source.population -= army_size
		var army := gs.create_army(source_id, kid, army_size)
		army.target_city = target_id
		army.moving = true


func _form_pact(k1_id: int, k2_id: int, pact_type: String) -> void:
	gs.pacts.append({
		"kingdom_a": k1_id,
		"kingdom_b": k2_id,
		"type": pact_type,
	})
	var k1_name: String = gs.kingdoms[k1_id].name
	var k2_name: String = gs.kingdoms[k2_id].name
	gs.log_chronicle("%s and %s formed a %s pact" % [k1_name, k2_name, pact_type])


func _has_pact(k1_id: int, k2_id: int, pact_type: String) -> bool:
	for p in gs.pacts:
		if p.type == pact_type:
			if (p.kingdom_a == k1_id and p.kingdom_b == k2_id) or \
			   (p.kingdom_a == k2_id and p.kingdom_b == k1_id):
				return true
	return false


func _declare_war(k1_id: int, k2_id: int) -> void:
	var k1: Dictionary = gs.kingdoms[k1_id]
	var k2: Dictionary = gs.kingdoms[k2_id]
	if k2_id not in k1.at_war_with:
		k1.at_war_with.append(k2_id)
	if k1_id not in k2.at_war_with:
		k2.at_war_with.append(k1_id)
	# Remove pacts
	gs.pacts = gs.pacts.filter(func(p: Dictionary) -> bool:
		return not ((p.kingdom_a == k1_id and p.kingdom_b == k2_id) or \
					(p.kingdom_a == k2_id and p.kingdom_b == k1_id)))
	gs.log_chronicle("%s declares war on %s!" % [k1.name, k2.name])


func player_declare_holy_war(target_kingdom_id: int) -> bool:
	if not gs.player_religion.doctrines.get("holy_war", false):
		return false
	if target_kingdom_id not in gs.kingdoms:
		return false
	var k: Dictionary = gs.kingdoms[target_kingdom_id]
	# Player uses kingdom_id -1
	if -1 not in k.at_war_with:
		k.at_war_with.append(-1)
	gs.log_chronicle("Holy War declared against %s!" % k.name)
	return true


func propose_pact(target_kingdom_id: int, pact_type: String) -> bool:
	if target_kingdom_id not in gs.kingdoms:
		return false
	var k: Dictionary = gs.kingdoms[target_kingdom_id]
	# AI decides based on relations and faith spread
	var relation: float = k.relations.get(-1, 0.0)  # -1 = player

	var accept_threshold := 20.0
	if pact_type == PACT_TRADE:
		accept_threshold = 10.0
	elif pact_type == PACT_TRIBUTE:
		accept_threshold = 40.0

	# Faith dominance helps
	var avg_faith := 0.0
	var count := 0
	for cid in gs.cities:
		if gs.cities[cid].kingdom_id == target_kingdom_id:
			avg_faith += gs.cities[cid].faith_share
			count += 1
	if count > 0:
		avg_faith /= count
	accept_threshold -= avg_faith * 30.0

	if relation > accept_threshold or gs.rng.randf() < 0.2:
		_form_pact(-1, target_kingdom_id, pact_type)
		return true
	else:
		gs.log_chronicle("%s rejected our %s proposal" % [k.name, pact_type])
		return false


func get_pacts_for_kingdom(kingdom_id: int) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for p in gs.pacts:
		if p.kingdom_a == kingdom_id or p.kingdom_b == kingdom_id:
			result.append(p)
	return result
