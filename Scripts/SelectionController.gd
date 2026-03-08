extends Node
class_name SelectionController
## Handles touch/click raycasting for selecting cities and armies.

signal city_selected(city_id: int)
signal army_selected(army_id: int)
signal deselected()

@onready var gs: Node = get_node("/root/GameState")

var camera: Camera3D
var selected_city_id: int = -1
var selected_army_id: int = -1
var _tap_start_pos := Vector2.ZERO
var _tap_start_time := 0.0
const TAP_MAX_DIST := 20.0
const TAP_MAX_TIME := 0.3


func setup(cam: Camera3D) -> void:
	camera = cam


func _unhandled_input(event: InputEvent) -> void:
	if gs.is_event_modal_open:
		return

	if event is InputEventScreenTouch:
		if event.pressed:
			_tap_start_pos = event.position
			_tap_start_time = Time.get_ticks_msec() / 1000.0
		else:
			var dist := event.position.distance_to(_tap_start_pos)
			var elapsed := Time.get_ticks_msec() / 1000.0 - _tap_start_time
			if dist < TAP_MAX_DIST and elapsed < TAP_MAX_TIME:
				_do_raycast(event.position)

	elif event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			_do_raycast(event.position)


func _do_raycast(screen_pos: Vector2) -> void:
	if camera == null:
		return

	var from := camera.project_ray_origin(screen_pos)
	var dir := camera.project_ray_normal(screen_pos)
	var to := from + dir * 500.0

	var space := camera.get_world_3d().direct_space_state
	if space == null:
		return

	# Check city areas (layer 2)
	var query := PhysicsRayQueryParameters3D.create(from, to)
	query.collision_mask = 2
	query.collide_with_areas = true
	query.collide_with_bodies = false
	var result := space.intersect_ray(query)
	if not result.is_empty():
		var collider = result.get("collider")
		if collider is Area3D and collider.has_meta("city_id"):
			var cid: int = collider.get_meta("city_id")
			_select_city(cid)
			return

	# Check terrain (layer 1)
	query.collision_mask = 1
	query.collide_with_areas = false
	query.collide_with_bodies = true
	result = space.intersect_ray(query)
	if not result.is_empty():
		# Clicked terrain, check nearby armies
		var hit_pos: Vector3 = result.position
		var best_army := -1
		var best_dist := 3.0
		for aid in gs.armies:
			var army: Dictionary = gs.armies[aid]
			var d: float = army.pos.distance_to(hit_pos)
			if d < best_dist:
				best_dist = d
				best_army = aid
		if best_army >= 0:
			_select_army(best_army)
			return

	_deselect()


func _select_city(city_id: int) -> void:
	selected_city_id = city_id
	selected_army_id = -1
	city_selected.emit(city_id)


func _select_army(army_id: int) -> void:
	selected_army_id = army_id
	selected_city_id = -1
	army_selected.emit(army_id)


func _deselect() -> void:
	selected_city_id = -1
	selected_army_id = -1
	deselected.emit()
