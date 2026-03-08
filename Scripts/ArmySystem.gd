extends Node
class_name ArmySystem
## Manages armies, movement, and sieges.

@onready var gs: Node = get_node("/root/GameState")

var army_markers: Dictionary = {}  # army_id -> MeshInstance3D


func army_tick() -> void:
	if gs.is_event_modal_open:
		return

	var to_remove: Array[int] = []
	for aid in gs.armies:
		var army: Dictionary = gs.armies[aid]
		if army.moving:
			_process_movement(army)
		elif army.sieging:
			_process_siege(army)
		if army.size <= 0:
			to_remove.append(aid)
		gs.army_updated.emit(aid)

	for aid in to_remove:
		remove_army(aid)


func _process_movement(army: Dictionary) -> void:
	if army.target_city < 0:
		army.moving = false
		return

	var target_city: Dictionary = gs.cities.get(army.target_city, {})
	if target_city.is_empty():
		army.moving = false
		return

	var direction: Vector3 = (target_city.pos - army.pos).normalized()
	var move_speed := 2.0  # units per tick
	var dist: float = army.pos.distance_to(target_city.pos)

	if dist < move_speed:
		army.pos = target_city.pos + Vector3(0, 0.5, 0)
		army.moving = false
		# Check if enemy city
		if target_city.kingdom_id != army.kingdom_id:
			army.sieging = true
			army.siege_progress = 0.0
			gs.log_chronicle("Army %d begins siege of %s" % [army.id, target_city.name])
		else:
			gs.log_chronicle("Army %d arrived at %s" % [army.id, target_city.name])
	else:
		army.pos += direction * move_speed
		army.pos.y = _get_terrain_height(army.pos.x, army.pos.z) + 0.5

	_update_army_marker(army.id)


func _process_siege(army: Dictionary) -> void:
	if army.target_city < 0:
		army.sieging = false
		return

	var target_city: Dictionary = gs.cities.get(army.target_city, {})
	if target_city.is_empty():
		army.sieging = false
		return

	# Siege progress
	var siege_power := float(army.size) * 0.001
	# Holy war bonus
	if gs.player_religion.doctrines.get("holy_war", false) and army.kingdom_id == -1:
		siege_power *= 1.5
	# Fort reduces siege
	if "fort" in target_city.buildings:
		siege_power *= 0.5
	# Security resistance
	siege_power -= target_city.security * 0.005

	army.siege_progress += maxf(0.01, siege_power)
	target_city.stability = maxf(0.0, target_city.stability - 1.0)

	# Army attrition during siege
	army.size = maxi(0, army.size - gs.rng.randi_range(5, 20))

	if army.siege_progress >= 100.0:
		# City captured!
		_capture_city(army, target_city)
		army.sieging = false
		army.target_city = -1


func _capture_city(army: Dictionary, city: Dictionary) -> void:
	var old_kingdom := city.kingdom_id
	city.kingdom_id = army.kingdom_id
	city.stability *= 0.5
	city.security *= 0.3
	city.population = int(city.population * 0.8)

	# If player army, boost faith
	if army.kingdom_id == -1:
		city.faith_share = minf(1.0, city.faith_share + 0.4)
		city.dominance = minf(1.0, city.dominance + 0.3)

	gs.log_chronicle("%s conquered! (was %s)" % [
		city.name,
		gs.kingdoms[old_kingdom].name if old_kingdom in gs.kingdoms else "Independent"
	])


func raise_army(city_id: int, size: int) -> int:
	if city_id not in gs.cities:
		return -1
	var city: Dictionary = gs.cities[city_id]
	if city.dominance < 0.4:
		return -1

	var cost := size * 0.5
	if gs.player_religion.gold < cost:
		return -1

	gs.player_religion.gold -= cost
	city.population = maxi(100, city.population - size)

	var army := gs.create_army(city_id, -1, size)  # -1 = player
	_create_army_marker(army)
	gs.log_chronicle("Army of %d raised in %s" % [size, city.name])
	return army.id


func move_army(army_id: int, target_city_id: int) -> bool:
	if army_id not in gs.armies or target_city_id not in gs.cities:
		return false
	var army: Dictionary = gs.armies[army_id]
	if army.sieging:
		return false
	army.target_city = target_city_id
	army.moving = true
	army.siege_progress = 0.0
	gs.log_chronicle("Army %d marching to %s" % [army_id, gs.cities[target_city_id].name])
	return true


func remove_army(army_id: int) -> void:
	if army_id in army_markers:
		army_markers[army_id].queue_free()
		army_markers.erase(army_id)
	gs.armies.erase(army_id)


func _create_army_marker(army: Dictionary) -> void:
	var marker := MeshInstance3D.new()
	var mesh := ConeMesh.new()
	mesh.radius = 0.4
	mesh.height = 0.8
	marker.mesh = mesh
	var mat := StandardMaterial3D.new()
	if army.kingdom_id == -1:
		mat.albedo_color = Color(0.9, 0.8, 0.2)
	elif army.kingdom_id in gs.kingdoms:
		mat.albedo_color = gs.kingdoms[army.kingdom_id].color
	else:
		mat.albedo_color = Color(0.5, 0.5, 0.5)
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_PER_VERTEX
	marker.material_override = mat
	marker.position = army.pos
	get_parent().add_child(marker)
	army_markers[army.id] = marker


func _update_army_marker(army_id: int) -> void:
	if army_id not in army_markers or army_id not in gs.armies:
		return
	army_markers[army_id].position = gs.armies[army_id].pos


func update_all_markers() -> void:
	for aid in gs.armies:
		if aid not in army_markers:
			_create_army_marker(gs.armies[aid])
		else:
			_update_army_marker(aid)


func _get_terrain_height(world_x: float, world_z: float) -> float:
	var gx := int(world_x)
	var gy := int(world_z)
	return gs.get_height(gx, gy) * 8.0  # HEIGHT_SCALE
