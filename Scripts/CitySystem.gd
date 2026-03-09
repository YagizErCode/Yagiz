extends Node
class_name CitySystem
## Manages city building, economy, and trade.

@onready var gs: Node = get_node("/root/GameState")


func city_tick() -> void:
	if gs.is_event_modal_open:
		return

	for cid in gs.cities:
		var city: Dictionary = gs.cities[cid]
		_process_buildings(city)
		_process_economy(city)
		_process_population(city)
		_process_stability(city)
		gs.city_updated.emit(cid)


func _process_buildings(city: Dictionary) -> void:
	if city.build_queue.is_empty():
		return
	# Process first item in queue
	var building_name: String = city.build_queue[0]
	var bdata: Dictionary = GameState.BUILDING_DATA.get(building_name, {})
	if bdata.is_empty():
		city.build_queue.pop_front()
		return

	# Check if player can afford (for dominated cities)
	if city.dominance > 0.5:
		if gs.player_religion.gold >= bdata.cost:
			gs.player_religion.gold -= bdata.cost
			city.buildings.append(building_name)
			city.build_queue.pop_front()
			gs.log_chronicle("%s built in %s" % [building_name.capitalize(), city.name])
			_apply_building_effects(city, building_name)
	else:
		# AI builds with city wealth
		if city.wealth >= bdata.cost:
			city.wealth -= bdata.cost
			city.buildings.append(building_name)
			city.build_queue.pop_front()
			_apply_building_effects(city, building_name)


func _apply_building_effects(city: Dictionary, building_name: String) -> void:
	var bdata: Dictionary = GameState.BUILDING_DATA.get(building_name, {})
	city.education += bdata.get("education", 0)
	city.security += bdata.get("security", 0)
	city.wealth += bdata.get("wealth", 0)
	# Spread bonus applied in ReligionSystem


func _process_economy(city: Dictionary) -> void:
	# Base income
	var income = city.population * 0.002 + city.development * 0.1
	# Trade income
	income += city.trade_links.size() * 2.0
	# Building bonuses
	if "trade_hub" in city.buildings:
		income *= 1.3
	city.wealth += income * 0.1
	city.wealth = clampf(city.wealth, 0.0, 9999.0)

	# Tax for player if dominated
	if city.dominance > 0.5:
		var tax = income * 0.05 * city.dominance
		gs.player_religion.gold += tax


func _process_population(city: Dictionary) -> void:
	var growth_rate := 0.001
	if city.stability > 60:
		growth_rate += 0.001
	if "school" in city.buildings:
		growth_rate += 0.0005
	if city.wealth > 50:
		growth_rate += 0.0005
	# War penalty
	if city.security < 20:
		growth_rate -= 0.002
	city.population = maxi(100, int(city.population * (1.0 + growth_rate)))
	city.population = mini(city.population, 50000)


func _process_stability(city: Dictionary) -> void:
	# Stability recovery
	if city.security > 40:
		city.stability = minf(100.0, city.stability + 0.1)
	# Heresy causes unrest
	city.stability -= city.heresy_share * 0.5
	# Development
	if city.education > 30:
		city.development = minf(100.0, city.development + 0.05)
	city.stability = clampf(city.stability, 0.0, 100.0)


func queue_building(city_id: int, building_name: String) -> bool:
	if city_id not in gs.cities:
		return false
	var city: Dictionary = gs.cities[city_id]
	if city.dominance < 0.5:
		return false
	if building_name not in GameState.BUILDING_DATA:
		return false
	var bdata: Dictionary = GameState.BUILDING_DATA[building_name]
	if gs.player_religion.gold < bdata.cost:
		return false
	city.build_queue.append(building_name)
	return true


func add_trade_link(city_id: int, target_id: int) -> bool:
	if city_id not in gs.cities or target_id not in gs.cities:
		return false
	var city: Dictionary = gs.cities[city_id]
	if target_id in city.trade_links:
		return false
	city.trade_links.append(target_id)
	gs.cities[target_id].trade_links.append(city_id)
	gs.log_chronicle("Trade route established between %s and %s" % [
		city.name, gs.cities[target_id].name])
	return true


func remove_trade_link(city_id: int, target_id: int) -> bool:
	if city_id not in gs.cities or target_id not in gs.cities:
		return false
	var city: Dictionary = gs.cities[city_id]
	if target_id not in city.trade_links:
		return false
	city.trade_links.erase(target_id)
	gs.cities[target_id].trade_links.erase(city_id)
	gs.log_chronicle("Trade route severed between %s and %s" % [
		city.name, gs.cities[target_id].name])
	return true
