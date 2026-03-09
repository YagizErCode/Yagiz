extends Node
class_name SaveSystem
## Simple JSON save/load system.

const SAVE_PATH := "user://faith_empire_save.json"

@onready var gs: Node = get_node("/root/GameState")


func save_game() -> bool:
	var data = gs.to_save_dict()
	var json_str := JSON.stringify(data, "  ")
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file == null:
		push_warning("Could not open save file for writing")
		return false
	file.store_string(json_str)
	file.close()
	gs.log_chronicle("Game saved.")
	return true


func load_game() -> bool:
	if not FileAccess.file_exists(SAVE_PATH):
		push_warning("No save file found")
		return false

	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file == null:
		push_warning("Could not open save file")
		return false

	var json := JSON.new()
	var err := json.parse(file.get_as_text())
	file.close()
	if err != OK:
		push_warning("Save file parse error")
		return false

	var data: Dictionary = json.data
	gs.turn = data.get("turn", 0)
	gs.world_seed = data.get("world_seed", 42)
	if data.has("player_religion"):
		for key in data["player_religion"]:
			gs.player_religion[key] = data["player_religion"][key]
	gs.chronicle = Array(data.get("chronicle", []))
	gs.log_chronicle("Game loaded.")
	return true


static func has_save() -> bool:
	return FileAccess.file_exists(SAVE_PATH)
