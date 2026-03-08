extends Node
## Autoloaded global singleton holding all game data.

# ── Signals ──────────────────────────────────────────────────────────────────
signal city_updated(city_id: int)
signal kingdom_updated(kingdom_id: int)
signal faith_updated()
signal event_triggered(event_data: Dictionary)
signal sect_created(sect_data: Dictionary)
signal army_updated(army_id: int)
signal chronicle_entry(text: String)
signal game_over()
signal turn_advanced(turn: int)
signal simulation_paused()
signal simulation_resumed()

# ── Constants ────────────────────────────────────────────────────────────────
const BIOME_OCEAN := 0
const BIOME_COAST := 1
const BIOME_PLAINS := 2
const BIOME_DESERT := 3
const BIOME_SAVANNA := 4
const BIOME_JUNGLE := 5
const BIOME_TAIGA := 6
const BIOME_TUNDRA := 7
const BIOME_MOUNTAIN := 8

const BIOME_NAMES := {
	0: "Ocean", 1: "Coast", 2: "Plains", 3: "Desert",
	4: "Savanna", 5: "Jungle", 6: "Taiga", 7: "Tundra", 8: "Mountain"
}

const BIOME_COLORS := {
	0: Color(0.1, 0.2, 0.5),
	1: Color(0.3, 0.5, 0.7),
	2: Color(0.3, 0.6, 0.2),
	3: Color(0.8, 0.7, 0.3),
	4: Color(0.6, 0.5, 0.2),
	5: Color(0.1, 0.4, 0.15),
	6: Color(0.2, 0.35, 0.25),
	7: Color(0.7, 0.75, 0.8),
	8: Color(0.5, 0.45, 0.4),
}

const BUILDING_DATA := {
	"temple": {"cost": 50, "spread": 0.05, "education": 0, "security": 0, "wealth": 5},
	"school": {"cost": 80, "spread": 0, "education": 10, "security": 0, "wealth": 5},
	"fort": {"cost": 100, "spread": 0, "education": 0, "security": 15, "wealth": -5},
	"cathedral": {"cost": 200, "spread": 0.12, "education": 5, "security": 0, "wealth": 10},
	"trade_hub": {"cost": 120, "spread": 0.02, "education": 0, "security": 0, "wealth": 20},
}

const KINGDOM_COLORS := [
	Color(0.8, 0.2, 0.2), Color(0.2, 0.2, 0.8), Color(0.2, 0.7, 0.2),
	Color(0.8, 0.8, 0.2), Color(0.7, 0.3, 0.7), Color(0.2, 0.7, 0.7),
	Color(0.9, 0.5, 0.1), Color(0.5, 0.5, 0.5), Color(0.6, 0.3, 0.1),
	Color(0.3, 0.8, 0.5), Color(0.8, 0.4, 0.6), Color(0.4, 0.4, 0.8),
]

# ── Game State ───────────────────────────────────────────────────────────────
var world_seed: int = 42
var rng := RandomNumberGenerator.new()
var turn: int = 0
var speed: int = 1  # 0=paused, 1,2,3
var is_event_modal_open: bool = false
var tick_timer: float = 0.0

# Map data
var map_width: int = 200
var map_height: int = 150
var heightmap: PackedFloat32Array = PackedFloat32Array()
var moisturemap: PackedFloat32Array = PackedFloat32Array()
var biomemap: PackedInt32Array = PackedInt32Array()

# Cities
var cities: Dictionary = {}  # id -> city dict
var next_city_id: int = 0

# Kingdoms
var kingdoms: Dictionary = {}  # id -> kingdom dict
var next_kingdom_id: int = 0

# Player religion
var player_religion: Dictionary = {
	"name": "The Faith",
	"birthplace_city": -1,
	"axes": {
		"tolerance": 50, "militarism": 50, "knowledge": 50,
		"ritual": 50, "commerce": 50, "austerity": 50, "charity": 50,
	},
	"doctrines": {
		"pacifism": false, "holy_war": false, "ritualized_sex": false,
		"mandatory_war": false, "iconoclasm": false, "asceticism": false,
		"syncretism": false, "inquisitions": false,
	},
	"authority": 50.0,
	"legitimacy": 50.0,
	"gold": 500.0,
	"spread_rate": 1.0,
	"holy_cities": [],
}

# Sects
var sects: Array[Dictionary] = []
var next_sect_id: int = 0

# Characters
var characters: Dictionary = {}  # id -> character dict
var next_character_id: int = 0
var player_character: Dictionary = {}

# Armies
var armies: Dictionary = {}  # id -> army dict
var next_army_id: int = 0

# Diplomacy
var pacts: Array[Dictionary] = []  # {kingdom_a, kingdom_b, type}

# Events
var events_data: Array = []  # loaded from JSON
var event_cooldowns: Dictionary = {}  # event_id -> turns remaining
var active_event_chain: String = ""

# Chronicle
var chronicle: Array[String] = []

# Culture names for variety
var culture_names := ["Valdori", "Ashken", "Sunborn", "Frostkin", "Duskwalker",
	"Ironbound", "Thornfolk", "Stormcall", "Sandweaver", "Deepmoor",
	"Flamekeeper", "Mossblood"]

var city_name_prefixes := ["Ash", "Iron", "Storm", "Sun", "Moon", "Dark", "Gold",
	"Silver", "Frost", "Flame", "Thorn", "Deep", "High", "Shadow", "Dawn",
	"Dusk", "Stone", "Wind", "Star", "Blood", "Mist", "Bright", "Swift",
	"Elder", "Crown", "Raven", "Wolf", "Bear", "Dragon", "Serpent"]
var city_name_suffixes := ["hold", "haven", "gate", "falls", "march", "ford",
	"heim", "dale", "watch", "keep", "rest", "peak", "vale", "port", "stead",
	"wall", "bridge", "hollow", "grove", "spire", "reach", "moor", "field",
	"town", "burg", "mouth", "wood", "lake", "bay", "crest"]


func _ready() -> void:
	rng.seed = world_seed


func log_chronicle(text: String) -> void:
	var entry := "Turn %d: %s" % [turn, text]
	chronicle.append(entry)
	chronicle_entry.emit(entry)


func get_biome(x: int, y: int) -> int:
	if x < 0 or x >= map_width or y < 0 or y >= map_height:
		return BIOME_OCEAN
	return biomemap[y * map_width + x]


func get_height(x: int, y: int) -> float:
	if x < 0 or x >= map_width or y < 0 or y >= map_height:
		return 0.0
	return heightmap[y * map_width + x]


func generate_city_name() -> String:
	var p := city_name_prefixes[rng.randi() % city_name_prefixes.size()]
	var s := city_name_suffixes[rng.randi() % city_name_suffixes.size()]
	return p + s


func create_city(pos: Vector3, kingdom_id: int, culture_id: int) -> Dictionary:
	var cid := next_city_id
	next_city_id += 1
	var city := {
		"id": cid,
		"name": generate_city_name(),
		"pos": pos,
		"grid_x": int(pos.x),
		"grid_y": int(pos.z),
		"kingdom_id": kingdom_id,
		"population": rng.randi_range(500, 5000),
		"wealth": rng.randf_range(20.0, 100.0),
		"development": rng.randf_range(10.0, 50.0),
		"education": rng.randf_range(5.0, 40.0),
		"stability": rng.randf_range(40.0, 80.0),
		"security": rng.randf_range(20.0, 60.0),
		"culture_id": culture_id,
		"faith_share": 0.0,
		"heresy_share": 0.0,
		"dominance": 0.0,
		"trade_links": [],
		"build_queue": [],
		"buildings": [],
		"is_holy_city": false,
		"pilgrimage_target": -1,
	}
	cities[cid] = city
	return city


func create_kingdom(name: String, color_idx: int) -> Dictionary:
	var kid := next_kingdom_id
	next_kingdom_id += 1
	var kingdom := {
		"id": kid,
		"name": name,
		"color": KINGDOM_COLORS[color_idx % KINGDOM_COLORS.size()],
		"ruler_id": -1,
		"culture_id": kid % culture_names.size(),
		"relations": {},  # other_kingdom_id -> float (-100..100)
		"at_war_with": [],
	}
	kingdoms[kid] = kingdom
	return kingdom


func create_character(kingdom_id: int, is_ruler: bool) -> Dictionary:
	var cid := next_character_id
	next_character_id += 1
	var traits_pool := ["zealous", "cynical", "brave", "craven", "wise", "foolish",
		"just", "cruel", "gregarious", "shy", "patient", "wrathful",
		"charitable", "greedy", "temperate", "gluttonous"]
	var num_traits := rng.randi_range(2, 4)
	var traits: Array[String] = []
	for i in num_traits:
		var t := traits_pool[rng.randi() % traits_pool.size()]
		if t not in traits:
			traits.append(t)
	var ch := {
		"id": cid,
		"name": _random_character_name(),
		"dynasty": _random_dynasty_name(),
		"kingdom_id": kingdom_id,
		"is_ruler": is_ruler,
		"learning": rng.randi_range(3, 20),
		"martial": rng.randi_range(3, 20),
		"intrigue": rng.randi_range(3, 20),
		"diplomacy": rng.randi_range(3, 20),
		"traits": traits,
		"alive": true,
	}
	characters[cid] = ch
	return ch


func _random_character_name() -> String:
	var firsts := ["Aldric", "Beren", "Cassius", "Darian", "Elara", "Freya",
		"Galen", "Helena", "Ivar", "Jorah", "Kira", "Lyra", "Marcus",
		"Nadia", "Orin", "Petra", "Quinn", "Rowan", "Seren", "Theron",
		"Ulric", "Vera", "Wren", "Xander", "Yara", "Zara"]
	return firsts[rng.randi() % firsts.size()]


func _random_dynasty_name() -> String:
	var houses := ["Blackthorn", "Ironvale", "Goldcrest", "Stormwind",
		"Ashford", "Silvermane", "Darkhollow", "Sunspear", "Frostborne",
		"Ravenwood", "Thornwall", "Deepwater"]
	return houses[rng.randi() % houses.size()]


func create_army(city_id: int, kingdom_id: int, size: int) -> Dictionary:
	var aid := next_army_id
	next_army_id += 1
	var city: Dictionary = cities[city_id]
	var army := {
		"id": aid,
		"kingdom_id": kingdom_id,
		"size": size,
		"pos": Vector3(city.pos.x, city.pos.y + 0.5, city.pos.z),
		"target_city": -1,
		"origin_city": city_id,
		"sieging": false,
		"siege_progress": 0.0,
		"moving": false,
		"move_progress": 0.0,
	}
	armies[aid] = army
	return army


func to_save_dict() -> Dictionary:
	# Convert state to serializable dictionary
	var data := {
		"turn": turn,
		"world_seed": world_seed,
		"player_religion": player_religion.duplicate(true),
		"gold": player_religion.gold,
		"sects": [],
		"chronicle": chronicle.duplicate(),
	}
	# Cities
	var city_array := []
	for c in cities.values():
		var cd: Dictionary = c.duplicate(true)
		cd["pos_x"] = c.pos.x
		cd["pos_y"] = c.pos.y
		cd["pos_z"] = c.pos.z
		cd.erase("pos")
		city_array.append(cd)
	data["cities"] = city_array
	# Kingdoms
	var king_array := []
	for k in kingdoms.values():
		var kd: Dictionary = k.duplicate(true)
		kd["color_r"] = k.color.r
		kd["color_g"] = k.color.g
		kd["color_b"] = k.color.b
		kd.erase("color")
		king_array.append(kd)
	data["kingdoms"] = king_array
	return data
