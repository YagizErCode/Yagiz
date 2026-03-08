extends Camera3D
class_name CameraController
## Touch-friendly camera: drag to pan, pinch to zoom.

@export var pan_speed := 0.5
@export var zoom_speed := 2.0
@export var min_zoom := 10.0
@export var max_zoom := 120.0
@export var initial_height := 50.0

var _touch_positions: Dictionary = {}  # finger_id -> Vector2
var _last_touch_positions: Dictionary = {}
var _is_dragging := false
var _pinch_start_dist := 0.0
var _camera_target := Vector3.ZERO
var _camera_height := 50.0
var _camera_angle := -60.0  # degrees from horizontal


func _ready() -> void:
	_camera_height = initial_height
	_update_camera_transform()


func _update_camera_transform() -> void:
	var angle_rad := deg_to_rad(_camera_angle)
	var offset := Vector3(0, _camera_height * sin(-angle_rad), _camera_height * cos(-angle_rad))
	position = _camera_target + offset
	look_at(_camera_target, Vector3.UP)


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		_handle_touch(event)
	elif event is InputEventScreenDrag:
		_handle_drag(event)
	elif event is InputEventMouseButton:
		_handle_mouse_wheel(event)
	elif event is InputEventMouseMotion:
		_handle_mouse_drag(event)


func _handle_touch(event: InputEventScreenTouch) -> void:
	if event.pressed:
		_touch_positions[event.index] = event.position
		_last_touch_positions[event.index] = event.position
	else:
		_touch_positions.erase(event.index)
		_last_touch_positions.erase(event.index)


func _handle_drag(event: InputEventScreenDrag) -> void:
	_touch_positions[event.index] = event.position

	if _touch_positions.size() == 1:
		# Single finger: pan
		var delta := event.relative * pan_speed * (_camera_height / 50.0)
		_camera_target += Vector3(-delta.x, 0, -delta.y) * 0.1
		_clamp_target()
		_update_camera_transform()
	elif _touch_positions.size() == 2:
		# Two fingers: pinch to zoom
		var keys := _touch_positions.keys()
		var p1: Vector2 = _touch_positions[keys[0]]
		var p2: Vector2 = _touch_positions[keys[1]]
		var current_dist := p1.distance_to(p2)

		if keys[0] in _last_touch_positions and keys[1] in _last_touch_positions:
			var lp1: Vector2 = _last_touch_positions[keys[0]]
			var lp2: Vector2 = _last_touch_positions[keys[1]]
			var last_dist := lp1.distance_to(lp2)
			if last_dist > 10:
				var zoom_delta := (last_dist - current_dist) * 0.1
				_camera_height = clampf(_camera_height + zoom_delta, min_zoom, max_zoom)
				_update_camera_transform()

	for k in _touch_positions:
		_last_touch_positions[k] = _touch_positions[k]


func _handle_mouse_wheel(event: InputEventMouseButton) -> void:
	if event.button_index == MOUSE_BUTTON_WHEEL_UP:
		_camera_height = clampf(_camera_height - zoom_speed * 2.0, min_zoom, max_zoom)
		_update_camera_transform()
	elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
		_camera_height = clampf(_camera_height + zoom_speed * 2.0, min_zoom, max_zoom)
		_update_camera_transform()


func _handle_mouse_drag(event: InputEventMouseMotion) -> void:
	if Input.is_mouse_button_pressed(MOUSE_BUTTON_MIDDLE) or \
	   Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT):
		var delta := event.relative * pan_speed * (_camera_height / 50.0)
		_camera_target += Vector3(-delta.x, 0, -delta.y) * 0.1
		_clamp_target()
		_update_camera_transform()


func _clamp_target() -> void:
	var gs: Node = get_node("/root/GameState")
	_camera_target.x = clampf(_camera_target.x, 0, gs.map_width)
	_camera_target.z = clampf(_camera_target.z, 0, gs.map_height)
	_camera_target.y = 0


func center_on(pos: Vector3) -> void:
	_camera_target = Vector3(pos.x, 0, pos.z)
	_clamp_target()
	_update_camera_transform()
