extends Node
class_name ReligionSystem
## Manages faith spread, sects, schisms, and holy cities.

@onready var gs: Node = get_node("/root/GameState")


func spread_tick() -> void:
	if gs.is_event_modal_open:
		return

	var religion: Dictionary = gs.player_religion
	var base_rate: float = religion.spread_rate * 0.01

	# Doctrine modifiers
	var doc: Dictionary = religion.doctrines
	var axes: Dictionary = religion.axes
	if doc.get("syncretism", false):
		base_rate *= 1.3
	if doc.get("inquisitions", false):
		base_rate *= 1.15
	if doc.get("pacifism", false):
		base_rate *= 0.85
	base_rate *= (1.0 + axes.get("charity", 50) * 0.002)
	base_rate *= (1.0 + axes.get("commerce", 50) * 0.001)

	for cid in gs.cities:
		var city: Dictionary = gs.cities[cid]
		if city.faith_share <= 0.001:
			continue

		# Spread to trade-linked cities
		for link_id in city.trade_links:
			if link_id not in gs.cities:
				continue
			var target: Dictionary = gs.cities[link_id]
			var spread_amount := base_rate * city.faith_share

			# Distance factor
			var dist: float = city.pos.distance_to(target.pos)
			spread_amount *= maxf(0.1, 1.0 - dist * 0.005)

			# Population density bonus
			spread_amount *= (1.0 + float(city.population) * 0.00005)

			# Culture similarity bonus
			if city.culture_id == target.culture_id:
				spread_amount *= 1.3

			# Resistance
			var resistance := target.education * 0.003 + target.stability * 0.002 + target.security * 0.002
			if axes.get("tolerance", 50) > 60:
				resistance *= 0.8
			spread_amount = maxf(0.0, spread_amount - resistance * 0.01)

			# Apply
			target.faith_share = clampf(target.faith_share + spread_amount, 0.0, 1.0)

			# Update dominance
			target.dominance = target.faith_share * (religion.authority / 100.0)

	# Heresy spread
	_heresy_tick()

	# Check for schisms
	_schism_check()

	# Update authority and legitimacy
	_update_global_stats()

	gs.faith_updated.emit()


func _heresy_tick() -> void:
	for cid in gs.cities:
		var city: Dictionary = gs.cities[cid]
		if city.faith_share < 0.2:
			continue

		# Heresy grows when stability/authority low
		var heresy_growth := 0.0
		if city.stability < 40:
			heresy_growth += (40.0 - city.stability) * 0.0005
		if gs.player_religion.authority < 40:
			heresy_growth += (40.0 - gs.player_religion.authority) * 0.0003

		# Inquisitions reduce heresy but cost stability
		if gs.player_religion.doctrines.get("inquisitions", false):
			heresy_growth -= 0.005
			city.stability = maxf(0.0, city.stability - 0.2)

		city.heresy_share = clampf(city.heresy_share + heresy_growth, 0.0, 0.5)

		# Heresy eats into faith
		if city.heresy_share > 0.1:
			city.faith_share = maxf(0.0, city.faith_share - city.heresy_share * 0.01)


func _schism_check() -> void:
	if gs.player_religion.authority > 35:
		return
	if gs.rng.randf() > 0.02:  # 2% chance per tick when authority low
		return

	# Find city with high heresy to be the sect origin
	var best_city_id := -1
	var best_heresy := 0.2
	for cid in gs.cities:
		var city: Dictionary = gs.cities[cid]
		if city.heresy_share > best_heresy and city.faith_share > 0.3:
			best_heresy = city.heresy_share
			best_city_id = cid

	if best_city_id < 0:
		return

	_create_sect(best_city_id)


func _create_sect(origin_city_id: int) -> void:
	var sid := gs.next_sect_id
	gs.next_sect_id += 1

	var sect_prefixes := ["Reformed", "True", "Purified", "Ancient", "Radical",
		"Mystic", "Ascendant", "Orthodox", "Heterodox", "Illuminated"]
	var sect_name := sect_prefixes[sid % sect_prefixes.size()] + " " + gs.player_religion.name

	# Modified axes
	var new_axes: Dictionary = gs.player_religion.axes.duplicate()
	for key in new_axes:
		new_axes[key] = clampi(int(new_axes[key]) + gs.rng.randi_range(-15, 15), 0, 100)

	var sect := {
		"id": sid,
		"name": sect_name,
		"origin_city": origin_city_id,
		"axes": new_axes,
		"followers": 0,
		"cities": [origin_city_id],
	}
	gs.sects.append(sect)

	# Convert origin city
	var city: Dictionary = gs.cities[origin_city_id]
	city.heresy_share = maxf(0.0, city.heresy_share - 0.1)
	city.faith_share = maxf(0.0, city.faith_share - 0.15)

	gs.log_chronicle("Schism! %s sect formed in %s" % [sect_name, city.name])
	gs.sect_created.emit(sect)


func _update_global_stats() -> void:
	var total_faith := 0.0
	var total_cities := 0
	var dominated := 0

	for cid in gs.cities:
		var city: Dictionary = gs.cities[cid]
		total_faith += city.faith_share
		total_cities += 1
		if city.dominance > 0.5:
			dominated += 1

	if total_cities > 0:
		gs.player_religion.spread_rate = total_faith / total_cities * 100.0
		# Authority decay/growth
		var auth_change := (float(dominated) / total_cities - 0.3) * 2.0
		gs.player_religion.authority = clampf(gs.player_religion.authority + auth_change, 0.0, 100.0)
		# Legitimacy based on spread + authority
		gs.player_religion.legitimacy = clampf(
			gs.player_religion.spread_rate * 0.5 + gs.player_religion.authority * 0.5,
			0.0, 100.0)


func seed_faith_at_city(city_id: int) -> void:
	if city_id in gs.cities:
		gs.cities[city_id].faith_share = 0.8
		gs.cities[city_id].dominance = 0.5
		# Also seed neighbors a bit
		for link_id in gs.cities[city_id].trade_links:
			if link_id in gs.cities:
				gs.cities[link_id].faith_share = maxf(gs.cities[link_id].faith_share, 0.15)


func declare_holy_city(city_id: int) -> bool:
	if city_id not in gs.cities:
		return false
	var city: Dictionary = gs.cities[city_id]
	if city.dominance < 0.6:
		return false
	if city.is_holy_city:
		return false
	city.is_holy_city = true
	gs.player_religion.holy_cities.append(city_id)
	gs.log_chronicle("%s declared a Holy City!" % city.name)
	return true


func process_pilgrimages() -> void:
	for holy_id in gs.player_religion.holy_cities:
		if holy_id not in gs.cities:
			continue
		var holy_city: Dictionary = gs.cities[holy_id]
		# Cities with faith send pilgrims
		for cid in gs.cities:
			if cid == holy_id:
				continue
			var city: Dictionary = gs.cities[cid]
			if city.faith_share < 0.3:
				continue
			# Pilgrimage generates gold and authority
			var pilgrim_value := city.faith_share * city.population * 0.0001
			gs.player_religion.gold += pilgrim_value
			gs.player_religion.authority = minf(100.0, gs.player_religion.authority + pilgrim_value * 0.01)
			# Boost spread along trade path
			for link_id in city.trade_links:
				if link_id in gs.cities:
					gs.cities[link_id].faith_share = minf(1.0, gs.cities[link_id].faith_share + 0.002)
