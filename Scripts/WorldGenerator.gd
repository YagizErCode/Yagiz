extends Node3D
class_name WorldGenerator
## Generates the procedural world map: terrain mesh, biomes, cities, kingdoms.

@onready var game_state: Node = get_node("/root/GameState")

var terrain_mesh_instance: MeshInstance3D
var city_markers: Dictionary = {}  # city_id -> MeshInstance3D
var city_labels: Dictionary = {}  # city_id -> Label3D
var resource_markers: Array[MeshInstance3D] = []

const CELL_SIZE := 1.0
const HEIGHT_SCALE := 8.0
const NUM_CITIES_TARGET := 200
const NUM_KINGDOMS := 8


func generate_world() -> void:
	game_state.rng.seed = game_state.world_seed
	_generate_heightmap()
	_assign_biomes()
	_build_terrain_mesh()
	_place_cities()
	_create_kingdoms()
	_assign_cities_to_kingdoms()
	_build_trade_network()
	_place_resource_markers()
	_create_characters()
	game_state.log_chronicle("World generated with seed %d" % game_state.world_seed)


func _generate_heightmap() -> void:
	var w := game_state.map_width
	var h := game_state.map_height
	game_state.heightmap.resize(w * h)
	game_state.moisturemap.resize(w * h)
	game_state.biomemap.resize(w * h)

	var noise := FastNoiseLite.new()
	noise.seed = game_state.world_seed
	noise.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	noise.fractal_type = FastNoiseLite.FRACTAL_FBM
	noise.fractal_octaves = 5
	noise.frequency = 0.012

	var moisture_noise := FastNoiseLite.new()
	moisture_noise.seed = game_state.world_seed + 1000
	moisture_noise.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	moisture_noise.fractal_octaves = 4
	moisture_noise.frequency = 0.015

	for y in h:
		for x in w:
			var nx := float(x)
			var ny := float(y)
			var val := (noise.get_noise_2d(nx, ny) + 1.0) * 0.5

			# Island shaping: lower edges
			var dx := (float(x) / w - 0.5) * 2.0
			var dy := (float(y) / h - 0.5) * 2.0
			var dist := sqrt(dx * dx + dy * dy)
			val -= dist * 0.5
			val = clampf(val, 0.0, 1.0)

			game_state.heightmap[y * w + x] = val

			var mval := (moisture_noise.get_noise_2d(nx, ny) + 1.0) * 0.5
			game_state.moisturemap[y * w + x] = mval


func _assign_biomes() -> void:
	var w := game_state.map_width
	var h := game_state.map_height
	for y in h:
		for x in w:
			var idx := y * w + x
			var height := game_state.heightmap[idx]
			var moisture := game_state.moisturemap[idx]
			var lat := absf(float(y) / h - 0.5) * 2.0  # 0=equator, 1=pole

			var biome: int
			if height < 0.2:
				biome = GameState.BIOME_OCEAN
			elif height < 0.28:
				biome = GameState.BIOME_COAST
			elif height > 0.75:
				biome = GameState.BIOME_MOUNTAIN
			elif lat > 0.7:
				biome = GameState.BIOME_TUNDRA
			elif lat > 0.5:
				biome = GameState.BIOME_TAIGA if moisture > 0.4 else GameState.BIOME_TUNDRA
			elif moisture < 0.3:
				biome = GameState.BIOME_DESERT if lat < 0.4 else GameState.BIOME_PLAINS
			elif moisture < 0.5:
				biome = GameState.BIOME_SAVANNA if lat < 0.3 else GameState.BIOME_PLAINS
			elif moisture > 0.65:
				biome = GameState.BIOME_JUNGLE if lat < 0.35 else GameState.BIOME_TAIGA
			else:
				biome = GameState.BIOME_PLAINS

			game_state.biomemap[idx] = biome


func _build_terrain_mesh() -> void:
	var w := game_state.map_width
	var h := game_state.map_height
	var step := 2  # Skip every other vertex for performance
	var cols := w / step
	var rows := h / step

	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)

	for gy in rows:
		for gx in cols:
			var x := gx * step
			var y := gy * step
			if x >= w - step or y >= h - step:
				continue

			var idx00 := y * w + x
			var idx10 := y * w + (x + step)
			var idx01 := (y + step) * w + x
			var idx11 := (y + step) * w + (x + step)

			var h00 := game_state.heightmap[idx00] * HEIGHT_SCALE
			var h10 := game_state.heightmap[idx10] * HEIGHT_SCALE
			var h01 := game_state.heightmap[idx01] * HEIGHT_SCALE
			var h11 := game_state.heightmap[idx11] * HEIGHT_SCALE

			var v00 := Vector3(x * CELL_SIZE, h00, y * CELL_SIZE)
			var v10 := Vector3((x + step) * CELL_SIZE, h10, y * CELL_SIZE)
			var v01 := Vector3(x * CELL_SIZE, h01, (y + step) * CELL_SIZE)
			var v11 := Vector3((x + step) * CELL_SIZE, h11, (y + step) * CELL_SIZE)

			var c00 := _biome_color(game_state.biomemap[idx00], game_state.heightmap[idx00])
			var c10 := _biome_color(game_state.biomemap[idx10], game_state.heightmap[idx10])
			var c01 := _biome_color(game_state.biomemap[idx01], game_state.heightmap[idx01])
			var c11 := _biome_color(game_state.biomemap[idx11], game_state.heightmap[idx11])

			# Triangle 1
			surface.set_color(c00)
			surface.add_vertex(v00)
			surface.set_color(c10)
			surface.add_vertex(v10)
			surface.set_color(c01)
			surface.add_vertex(v01)

			# Triangle 2
			surface.set_color(c10)
			surface.add_vertex(v10)
			surface.set_color(c11)
			surface.add_vertex(v11)
			surface.set_color(c01)
			surface.add_vertex(v01)

	surface.generate_normals()
	var mesh := surface.commit()

	terrain_mesh_instance = MeshInstance3D.new()
	terrain_mesh_instance.mesh = mesh
	var mat := StandardMaterial3D.new()
	mat.vertex_color_use_as_albedo = true
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_PER_VERTEX
	terrain_mesh_instance.material_override = mat
	# Add static body for raycasting
	var body := StaticBody3D.new()
	terrain_mesh_instance.add_child(body)
	body.create_trimesh_collision()
	add_child(terrain_mesh_instance)


func _biome_color(biome: int, height: float) -> Color:
	var base: Color = GameState.BIOME_COLORS.get(biome, Color.MAGENTA)
	# Slight height shading
	var shade := lerpf(0.7, 1.0, height)
	return Color(base.r * shade, base.g * shade, base.b * shade)


func _place_cities() -> void:
	var w := game_state.map_width
	var h := game_state.map_height
	var candidates: Array[Vector2i] = []

	# Collect suitable positions
	for y in range(0, h, 3):
		for x in range(0, w, 3):
			var biome := game_state.get_biome(x, y)
			if biome == GameState.BIOME_OCEAN or biome == GameState.BIOME_MOUNTAIN:
				continue
			var hv := game_state.get_height(x, y)
			if hv < 0.25 or hv > 0.72:
				continue
			# Prefer near water
			var near_water := false
			for dy in range(-3, 4):
				for dx in range(-3, 4):
					if game_state.get_biome(x + dx, y + dy) == GameState.BIOME_OCEAN or \
					   game_state.get_biome(x + dx, y + dy) == GameState.BIOME_COAST:
						near_water = true
						break
				if near_water:
					break
			if near_water or game_state.rng.randf() < 0.3:
				candidates.append(Vector2i(x, y))

	# Poisson-like sampling: pick cities with min distance
	var min_dist := 6.0
	var placed: Array[Vector2i] = []
	# Shuffle candidates
	for i in range(candidates.size() - 1, 0, -1):
		var j := game_state.rng.randi() % (i + 1)
		var tmp := candidates[i]
		candidates[i] = candidates[j]
		candidates[j] = tmp

	for c in candidates:
		if placed.size() >= NUM_CITIES_TARGET:
			break
		var too_close := false
		for p in placed:
			if Vector2(c).distance_to(Vector2(p)) < min_dist:
				too_close = true
				break
		if not too_close:
			placed.append(c)

	# Create city data and markers
	for p in placed:
		var hv := game_state.get_height(p.x, p.y) * HEIGHT_SCALE
		var pos := Vector3(p.x * CELL_SIZE, hv + 0.3, p.y * CELL_SIZE)
		var biome := game_state.get_biome(p.x, p.y)
		var culture := biome % game_state.culture_names.size()
		var city := game_state.create_city(pos, -1, culture)
		_create_city_marker(city)


func _create_city_marker(city: Dictionary) -> void:
	# Simple cylinder marker
	var marker := MeshInstance3D.new()
	var cyl := CylinderMesh.new()
	cyl.top_radius = 0.3
	cyl.bottom_radius = 0.4
	cyl.height = 0.6
	marker.mesh = cyl
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.6, 0.6, 0.6)
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_PER_VERTEX
	marker.material_override = mat
	marker.position = city.pos
	marker.name = "City_%d" % city.id

	# Collision for selection
	var area := Area3D.new()
	var col := CollisionShape3D.new()
	var shape := CylinderShape3D.new()
	shape.radius = 0.5
	shape.height = 1.0
	col.shape = shape
	area.add_child(col)
	area.set_meta("city_id", city.id)
	area.collision_layer = 2
	area.collision_mask = 0
	marker.add_child(area)

	# Label
	var label := Label3D.new()
	label.text = city.name
	label.font_size = 32
	label.pixel_size = 0.01
	label.position = Vector3(0, 1.0, 0)
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.modulate = Color(1, 1, 1, 0.9)
	label.outline_size = 8
	marker.add_child(label)

	add_child(marker)
	city_markers[city.id] = marker
	city_labels[city.id] = label


func _create_kingdoms() -> void:
	var kingdom_names := ["Valdoria", "Ashkenheim", "Sunborn Empire", "Frostmarch",
		"Duskhollow", "Ironbound League", "Thornlands", "Stormcall Dominion",
		"Sandweavers", "Deepmoor Realm", "Flameguard", "Mossblood Confederacy"]
	for i in NUM_KINGDOMS:
		var k := game_state.create_kingdom(kingdom_names[i], i)
		# Initialize relations
		for j in NUM_KINGDOMS:
			if j != i:
				k.relations[j] = game_state.rng.randf_range(-30.0, 50.0)


func _assign_cities_to_kingdoms() -> void:
	# Pick capital cities spread across map, then flood-fill assign
	var city_ids := game_state.cities.keys()
	if city_ids.is_empty():
		return

	var kingdom_ids := game_state.kingdoms.keys()
	var capitals: Dictionary = {}  # kingdom_id -> city_id

	# Pick spread-out capitals
	var used_cities: Array[int] = []
	for kid in kingdom_ids:
		var best_city := -1
		var best_dist := 0.0
		for _attempt in 50:
			var cid: int = city_ids[game_state.rng.randi() % city_ids.size()]
			if cid in used_cities:
				continue
			var city: Dictionary = game_state.cities[cid]
			var min_dist := INF
			for uc in used_cities:
				var uc_city: Dictionary = game_state.cities[uc]
				var d: float = city.pos.distance_to(uc_city.pos)
				if d < min_dist:
					min_dist = d
			if used_cities.is_empty() or min_dist > best_dist:
				best_dist = min_dist
				best_city = cid
		if best_city >= 0:
			capitals[kid] = best_city
			used_cities.append(best_city)
			game_state.cities[best_city].kingdom_id = kid

	# Assign remaining cities to nearest capital's kingdom
	for cid in city_ids:
		var city: Dictionary = game_state.cities[cid]
		if city.kingdom_id >= 0:
			continue
		var best_kid := -1
		var best_d := INF
		for kid in capitals:
			var cap_city: Dictionary = game_state.cities[capitals[kid]]
			var d: float = city.pos.distance_to(cap_city.pos)
			if d < best_d:
				best_d = d
				best_kid = kid
		if best_kid >= 0:
			city.kingdom_id = best_kid

	# Update marker colors
	_update_all_city_colors()


func _update_all_city_colors() -> void:
	for cid in game_state.cities:
		update_city_marker(cid)


func update_city_marker(city_id: int) -> void:
	if city_id not in city_markers:
		return
	var city: Dictionary = game_state.cities[city_id]
	var marker: MeshInstance3D = city_markers[city_id]
	var mat: StandardMaterial3D = marker.material_override

	if city.faith_share > 0.1:
		# Blend kingdom color with faith gold based on faith_share
		var kingdom_color := Color(0.5, 0.5, 0.5)
		if city.kingdom_id >= 0 and city.kingdom_id in game_state.kingdoms:
			kingdom_color = game_state.kingdoms[city.kingdom_id].color
		var faith_color := Color(0.9, 0.8, 0.2)
		mat.albedo_color = kingdom_color.lerp(faith_color, city.faith_share)
	else:
		if city.kingdom_id >= 0 and city.kingdom_id in game_state.kingdoms:
			mat.albedo_color = game_state.kingdoms[city.kingdom_id].color
		else:
			mat.albedo_color = Color(0.5, 0.5, 0.5)

	# Heresy indicator: make emission reddish
	if city.heresy_share > 0.15:
		mat.emission_enabled = true
		mat.emission = Color(0.8, 0.1, 0.1)
		mat.emission_energy_multiplier = city.heresy_share * 2.0
	else:
		mat.emission_enabled = false

	# Update label
	if city_id in city_labels:
		var label: Label3D = city_labels[city_id]
		label.text = "%s (%d)" % [city.name, city.population]


func _build_trade_network() -> void:
	var city_ids := game_state.cities.keys()
	for cid in city_ids:
		var city: Dictionary = game_state.cities[cid]
		# Find nearest cities
		var dists: Array[Dictionary] = []
		for other_id in city_ids:
			if other_id == cid:
				continue
			var other: Dictionary = game_state.cities[other_id]
			var d: float = city.pos.distance_to(other.pos)
			dists.append({"id": other_id, "dist": d})
		dists.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return a.dist < b.dist)

		var num_links := game_state.rng.randi_range(2, 5)
		var links: Array = city.trade_links
		for i in mini(num_links, dists.size()):
			var target_id: int = dists[i].id
			if target_id not in links:
				links.append(target_id)
			# Add reverse link
			var other_city: Dictionary = game_state.cities[target_id]
			if cid not in other_city.trade_links:
				other_city.trade_links.append(cid)


func _place_resource_markers() -> void:
	var resource_types := ["food", "wood", "iron", "gold", "mana"]
	var resource_colors := {
		"food": Color(0.2, 0.8, 0.2),
		"wood": Color(0.4, 0.25, 0.1),
		"iron": Color(0.6, 0.6, 0.65),
		"gold": Color(1.0, 0.85, 0.0),
		"mana": Color(0.5, 0.2, 0.9),
	}
	var w := game_state.map_width
	var h := game_state.map_height

	for _i in 80:
		var x := game_state.rng.randi_range(5, w - 5)
		var y := game_state.rng.randi_range(5, h - 5)
		var biome := game_state.get_biome(x, y)
		if biome == GameState.BIOME_OCEAN:
			continue
		var hv := game_state.get_height(x, y)
		if hv < 0.22:
			continue

		var rtype: String = resource_types[game_state.rng.randi() % resource_types.size()]
		var marker := MeshInstance3D.new()
		var box := BoxMesh.new()
		box.size = Vector3(0.3, 0.3, 0.3)
		marker.mesh = box
		var mat := StandardMaterial3D.new()
		mat.albedo_color = resource_colors[rtype]
		mat.emission_enabled = true
		mat.emission = resource_colors[rtype]
		mat.emission_energy_multiplier = 0.5
		marker.material_override = mat
		marker.position = Vector3(x * CELL_SIZE, hv * HEIGHT_SCALE + 0.5, y * CELL_SIZE)
		add_child(marker)
		resource_markers.append(marker)


func _create_characters() -> void:
	for kid in game_state.kingdoms:
		var ruler := game_state.create_character(kid, true)
		game_state.kingdoms[kid].ruler_id = ruler.id

	# Player prophet
	game_state.player_character = game_state.create_character(-1, false)
	game_state.player_character.name = "The Prophet"
	game_state.player_character.dynasty = "Divine"
	game_state.player_character.is_ruler = false
