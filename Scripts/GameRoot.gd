extends Node3D
## Main game scene bootstrap. Instantiates all systems, wires UI.

@onready var gs: Node = get_node("/root/GameState")

# Systems
var world_generator: WorldGenerator
var religion_system: ReligionSystem
var city_system: CitySystem
var army_system: ArmySystem
var diplomacy_system: DiplomacySystem
var character_system: CharacterSystem
var event_system: EventSystemJSON
var simulation_loop: SimulationLoop
var selection_controller: SelectionController
var camera: CameraController
var ui_controller: UIController


func _ready() -> void:
	_load_start_params()
	_create_systems()
	_create_camera()
	_create_ui()
	_wire_systems()
	_generate_world()
	_finalize()


func _load_start_params() -> void:
	# Read from global if set by StartMenu
	if gs.has_meta("start_params"):
		var params: Dictionary = gs.get_meta("start_params")
		gs.world_seed = params.get("seed", 42)
		gs.rng.seed = gs.world_seed
		gs.player_religion.name = params.get("religion_name", "The Faith")
		gs.player_religion.birthplace_city = params.get("birthplace_region", 0)
		gs.player_religion.axes = params.get("axes", gs.player_religion.axes)
		gs.player_religion.doctrines = params.get("doctrines", gs.player_religion.doctrines)


func _create_systems() -> void:
	world_generator = WorldGenerator.new()
	world_generator.name = "WorldGenerator"
	add_child(world_generator)

	religion_system = ReligionSystem.new()
	religion_system.name = "ReligionSystem"
	add_child(religion_system)

	city_system = CitySystem.new()
	city_system.name = "CitySystem"
	add_child(city_system)

	army_system = ArmySystem.new()
	army_system.name = "ArmySystem"
	add_child(army_system)

	diplomacy_system = DiplomacySystem.new()
	diplomacy_system.name = "DiplomacySystem"
	add_child(diplomacy_system)

	character_system = CharacterSystem.new()
	character_system.name = "CharacterSystem"
	add_child(character_system)

	event_system = EventSystemJSON.new()
	event_system.name = "EventSystem"
	add_child(event_system)

	simulation_loop = SimulationLoop.new()
	simulation_loop.name = "SimulationLoop"
	add_child(simulation_loop)

	selection_controller = SelectionController.new()
	selection_controller.name = "SelectionController"
	add_child(selection_controller)


func _create_camera() -> void:
	camera = CameraController.new()
	camera.name = "MainCamera"
	camera.initial_height = 50.0
	add_child(camera)

	# Environment & lighting
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.1, 0.12, 0.18)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.3, 0.3, 0.35)
	env.ambient_light_energy = 0.5
	env.tonemap_mode = Environment.TONE_MAP_FILMIC

	var world_env := WorldEnvironment.new()
	world_env.environment = env
	add_child(world_env)

	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-45, 30, 0)
	sun.light_energy = 0.8
	sun.shadow_enabled = false  # Mobile friendly
	add_child(sun)


func _create_ui() -> void:
	ui_controller = UIController.new()
	ui_controller.name = "UIController"
	add_child(ui_controller)

	# === Left Panel (global stats) ===
	var left_panel := _create_panel(Vector2(0, 0), Vector2(280, 350))
	left_panel.name = "LeftPanel"
	var left_vbox := VBoxContainer.new()
	left_vbox.name = "VBox"
	left_vbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT, Control.PRESET_MODE_KEEP_SIZE)
	left_vbox.position = Vector2(10, 10)
	left_vbox.size = Vector2(260, 330)
	for lname in ["TurnLabel", "GoldLabel", "AuthLabel", "LegitLabel", "SpreadLabel", "DoctrineLabel", "SeedLabel"]:
		var l := Label.new()
		l.name = lname
		l.text = lname
		l.add_theme_font_size_override("font_size", 16)
		left_vbox.add_child(l)
	left_panel.add_child(left_vbox)
	ui_controller.add_child(left_panel)
	ui_controller.left_panel = left_panel

	# === City Panel (right side) ===
	var city_panel := _create_panel(Vector2(0, 0), Vector2(320, 500))
	city_panel.name = "CityPanel"
	city_panel.anchor_left = 1.0
	city_panel.anchor_right = 1.0
	city_panel.offset_left = -320
	city_panel.offset_right = 0
	city_panel.visible = false
	var city_vbox := VBoxContainer.new()
	city_vbox.name = "VBox"
	city_vbox.position = Vector2(10, 10)
	city_vbox.size = Vector2(300, 480)
	for lname in ["NameLabel", "KingdomLabel", "StatsLabel", "FaithLabel", "BuildingsLabel"]:
		var l := Label.new()
		l.name = lname
		l.text = lname
		l.add_theme_font_size_override("font_size", 14)
		l.autowrap_mode = TextServer.AUTOWRAP_WORD
		city_vbox.add_child(l)
	# Build scroll
	var build_scroll := ScrollContainer.new()
	build_scroll.name = "BuildScroll"
	build_scroll.custom_minimum_size = Vector2(0, 120)
	var build_container := VBoxContainer.new()
	build_container.name = "BuildContainer"
	build_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	build_scroll.add_child(build_container)
	city_vbox.add_child(build_scroll)
	# Action container
	var action_container := VBoxContainer.new()
	action_container.name = "ActionContainer"
	city_vbox.add_child(action_container)
	city_panel.add_child(city_vbox)
	ui_controller.add_child(city_panel)
	ui_controller.city_panel = city_panel

	# === Army Panel ===
	var army_panel := _create_panel(Vector2(0, 0), Vector2(300, 400))
	army_panel.name = "ArmyPanel"
	army_panel.anchor_left = 1.0
	army_panel.anchor_right = 1.0
	army_panel.offset_left = -300
	army_panel.offset_right = 0
	army_panel.visible = false
	var army_vbox := VBoxContainer.new()
	army_vbox.name = "VBox"
	army_vbox.position = Vector2(10, 10)
	army_vbox.size = Vector2(280, 380)
	var info_label := Label.new()
	info_label.name = "InfoLabel"
	info_label.text = "Army Info"
	info_label.add_theme_font_size_override("font_size", 16)
	army_vbox.add_child(info_label)
	var status_label := Label.new()
	status_label.name = "StatusLabel"
	status_label.text = "Status"
	army_vbox.add_child(status_label)
	var move_scroll := ScrollContainer.new()
	move_scroll.name = "MoveScroll"
	move_scroll.custom_minimum_size = Vector2(0, 250)
	var move_container := VBoxContainer.new()
	move_container.name = "MoveContainer"
	move_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	move_scroll.add_child(move_container)
	army_vbox.add_child(move_scroll)
	army_panel.add_child(army_vbox)
	ui_controller.add_child(army_panel)
	ui_controller.army_panel = army_panel

	# === Diplomacy Panel ===
	var diplo_panel := _create_panel(Vector2(0, 0), Vector2(350, 500))
	diplo_panel.name = "DiplomacyPanel"
	diplo_panel.anchor_left = 0.5
	diplo_panel.anchor_right = 0.5
	diplo_panel.offset_left = -175
	diplo_panel.offset_right = 175
	diplo_panel.anchor_top = 0.1
	diplo_panel.visible = false
	var diplo_vbox := VBoxContainer.new()
	diplo_vbox.name = "VBox"
	diplo_vbox.position = Vector2(10, 10)
	diplo_vbox.size = Vector2(330, 480)
	var diplo_title := Label.new()
	diplo_title.text = "Diplomacy"
	diplo_title.add_theme_font_size_override("font_size", 22)
	diplo_vbox.add_child(diplo_title)
	var diplo_scroll := ScrollContainer.new()
	diplo_scroll.name = "ScrollContainer"
	diplo_scroll.custom_minimum_size = Vector2(0, 380)
	var diplo_list := VBoxContainer.new()
	diplo_list.name = "ListContainer"
	diplo_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	diplo_scroll.add_child(diplo_list)
	diplo_vbox.add_child(diplo_scroll)
	var diplo_close := Button.new()
	diplo_close.text = "Close"
	diplo_close.custom_minimum_size = Vector2(0, 45)
	diplo_close.pressed.connect(func() -> void: diplo_panel.visible = false)
	diplo_vbox.add_child(diplo_close)
	diplo_panel.add_child(diplo_vbox)
	ui_controller.add_child(diplo_panel)
	ui_controller.diplomacy_panel = diplo_panel

	# === Sect Panel ===
	var sect_panel := _create_panel(Vector2(0, 0), Vector2(300, 400))
	sect_panel.name = "SectPanel"
	sect_panel.anchor_left = 0.5
	sect_panel.anchor_right = 0.5
	sect_panel.offset_left = -150
	sect_panel.offset_right = 150
	sect_panel.anchor_top = 0.1
	sect_panel.visible = false
	var sect_vbox := VBoxContainer.new()
	sect_vbox.name = "VBox"
	sect_vbox.position = Vector2(10, 10)
	sect_vbox.size = Vector2(280, 380)
	var sect_title := Label.new()
	sect_title.text = "Sects"
	sect_title.add_theme_font_size_override("font_size", 22)
	sect_vbox.add_child(sect_title)
	var sect_scroll := ScrollContainer.new()
	sect_scroll.name = "ScrollContainer"
	sect_scroll.custom_minimum_size = Vector2(0, 300)
	var sect_list := VBoxContainer.new()
	sect_list.name = "ListContainer"
	sect_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sect_scroll.add_child(sect_list)
	sect_vbox.add_child(sect_scroll)
	var sect_close := Button.new()
	sect_close.text = "Close"
	sect_close.custom_minimum_size = Vector2(0, 45)
	sect_close.pressed.connect(func() -> void: sect_panel.visible = false)
	sect_vbox.add_child(sect_close)
	sect_panel.add_child(sect_vbox)
	ui_controller.add_child(sect_panel)
	ui_controller.sect_panel = sect_panel

	# === Event Modal ===
	var event_modal := ColorRect.new()
	event_modal.name = "EventModal"
	event_modal.color = Color(0, 0, 0, 0.6)
	event_modal.set_anchors_preset(Control.PRESET_FULL_RECT)
	event_modal.visible = false
	event_modal.mouse_filter = Control.MOUSE_FILTER_STOP
	var event_panel_inner := PanelContainer.new()
	event_panel_inner.name = "Panel"
	event_panel_inner.anchor_left = 0.15
	event_panel_inner.anchor_right = 0.85
	event_panel_inner.anchor_top = 0.1
	event_panel_inner.anchor_bottom = 0.9
	event_panel_inner.offset_left = 0
	event_panel_inner.offset_right = 0
	event_panel_inner.offset_top = 0
	event_panel_inner.offset_bottom = 0
	var event_vbox := VBoxContainer.new()
	event_vbox.name = "VBox"
	var event_title := Label.new()
	event_title.name = "TitleLabel"
	event_title.text = "Event"
	event_title.add_theme_font_size_override("font_size", 24)
	event_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	event_vbox.add_child(event_title)
	var event_desc := Label.new()
	event_desc.name = "DescLabel"
	event_desc.text = "Description"
	event_desc.autowrap_mode = TextServer.AUTOWRAP_WORD
	event_desc.add_theme_font_size_override("font_size", 16)
	event_vbox.add_child(event_desc)
	var choices_scroll := ScrollContainer.new()
	choices_scroll.name = "ChoicesScroll"
	choices_scroll.custom_minimum_size = Vector2(0, 200)
	choices_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var choices_container := VBoxContainer.new()
	choices_container.name = "ChoicesContainer"
	choices_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	choices_scroll.add_child(choices_container)
	event_vbox.add_child(choices_scroll)
	event_panel_inner.add_child(event_vbox)
	event_modal.add_child(event_panel_inner)
	ui_controller.add_child(event_modal)
	ui_controller.event_modal = event_modal

	# === Chronicle Panel (bottom) ===
	var chronicle := _create_panel(Vector2(0, 0), Vector2(500, 200))
	chronicle.name = "ChroniclePanel"
	chronicle.anchor_left = 0.0
	chronicle.anchor_right = 0.0
	chronicle.anchor_top = 1.0
	chronicle.anchor_bottom = 1.0
	chronicle.offset_left = 0
	chronicle.offset_right = 500
	chronicle.offset_top = -200
	chronicle.offset_bottom = 0
	chronicle.visible = false
	var chron_vbox := VBoxContainer.new()
	chron_vbox.name = "VBox"
	chron_vbox.position = Vector2(5, 5)
	chron_vbox.size = Vector2(490, 190)
	var chron_title := Label.new()
	chron_title.text = "Chronicle"
	chron_title.add_theme_font_size_override("font_size", 18)
	chron_vbox.add_child(chron_title)
	var chron_scroll := ScrollContainer.new()
	chron_scroll.name = "ScrollContainer"
	chron_scroll.custom_minimum_size = Vector2(0, 150)
	chron_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var chron_log := Label.new()
	chron_log.name = "LogLabel"
	chron_log.text = ""
	chron_log.autowrap_mode = TextServer.AUTOWRAP_WORD
	chron_log.add_theme_font_size_override("font_size", 13)
	chron_log.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	chron_scroll.add_child(chron_log)
	chron_vbox.add_child(chron_scroll)
	chronicle.add_child(chron_vbox)
	ui_controller.add_child(chronicle)
	ui_controller.chronicle_panel = chronicle

	# === Speed Controls (bottom center) ===
	var speed_bar := HBoxContainer.new()
	speed_bar.name = "SpeedControls"
	speed_bar.anchor_left = 0.5
	speed_bar.anchor_right = 0.5
	speed_bar.anchor_top = 1.0
	speed_bar.anchor_bottom = 1.0
	speed_bar.offset_left = -200
	speed_bar.offset_right = 200
	speed_bar.offset_top = -55
	speed_bar.offset_bottom = -5

	var speeds := [["Pause", 0], ["x1", 1], ["x2", 2], ["x3", 3], [">>", -1]]
	for sp in speeds:
		var btn := Button.new()
		btn.text = sp[0]
		btn.custom_minimum_size = Vector2(70, 45)
		btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var cap_speed: int = sp[1]
		btn.pressed.connect(func() -> void:
			if cap_speed == -1:
				simulation_loop.force_next_turn()
			else:
				gs.speed = cap_speed
		)
		speed_bar.add_child(btn)
	ui_controller.add_child(speed_bar)

	# === Top buttons ===
	var top_bar := HBoxContainer.new()
	top_bar.name = "TopBar"
	top_bar.anchor_left = 0.3
	top_bar.anchor_right = 0.9
	top_bar.offset_top = 5
	top_bar.offset_bottom = 50
	var diplo_btn := Button.new()
	diplo_btn.text = "Diplomacy"
	diplo_btn.custom_minimum_size = Vector2(100, 40)
	diplo_btn.pressed.connect(func() -> void: ui_controller.show_diplomacy())
	top_bar.add_child(diplo_btn)
	var sect_btn := Button.new()
	sect_btn.text = "Sects"
	sect_btn.custom_minimum_size = Vector2(80, 40)
	sect_btn.pressed.connect(func() -> void: ui_controller.show_sects())
	top_bar.add_child(sect_btn)
	var chron_btn := Button.new()
	chron_btn.text = "Chronicle"
	chron_btn.custom_minimum_size = Vector2(100, 40)
	chron_btn.pressed.connect(func() -> void: ui_controller.toggle_chronicle())
	top_bar.add_child(chron_btn)
	ui_controller.add_child(top_bar)


func _create_panel(pos: Vector2, sz: Vector2) -> PanelContainer:
	var panel := PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.1, 0.1, 0.15, 0.85)
	style.corner_radius_top_left = 8
	style.corner_radius_top_right = 8
	style.corner_radius_bottom_left = 8
	style.corner_radius_bottom_right = 8
	style.border_width_top = 1
	style.border_width_bottom = 1
	style.border_width_left = 1
	style.border_width_right = 1
	style.border_color = Color(0.3, 0.3, 0.4, 0.8)
	panel.add_theme_stylebox_override("panel", style)
	panel.position = pos
	panel.size = sz
	panel.mouse_filter = Control.MOUSE_FILTER_STOP
	return panel


func _wire_systems() -> void:
	selection_controller.setup(camera)
	simulation_loop.setup(religion_system, city_system, army_system,
		diplomacy_system, character_system, event_system)
	ui_controller.setup({
		"city": city_system,
		"army": army_system,
		"religion": religion_system,
		"diplomacy": diplomacy_system,
		"event": event_system,
		"selection": selection_controller,
		"world": world_generator,
	})


func _generate_world() -> void:
	world_generator.generate_world()

	# Seed faith at birthplace
	var birthplace = gs.player_religion.birthplace_city
	if birthplace >= 0 and birthplace in gs.cities:
		religion_system.seed_faith_at_city(birthplace)
	else:
		# Pick first city
		var first_id = gs.cities.keys()[0] if not gs.cities.is_empty() else -1
		if first_id >= 0:
			religion_system.seed_faith_at_city(first_id)
			gs.player_religion.birthplace_city = first_id


func _finalize() -> void:
	# Center camera on birthplace
	var bp = gs.player_religion.birthplace_city
	if bp >= 0 and bp in gs.cities:
		camera.center_on(gs.cities[bp].pos)
	else:
		camera.center_on(Vector3(gs.map_width * 0.5, 0, gs.map_height * 0.5))

	gs.speed = 1
	gs.log_chronicle("The %s has been founded!" % gs.player_religion.name)
