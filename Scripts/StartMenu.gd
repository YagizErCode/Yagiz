extends Control
## Start menu: religion creation, doctrine customization, birthplace selection.

@onready var gs: Node = get_node("/root/GameState")

var axes_sliders: Dictionary = {}
var doctrine_checks: Dictionary = {}
var religion_name_input: LineEdit
var seed_input: LineEdit
var region_option: OptionButton


func _ready() -> void:
	_build_ui()


func _build_ui() -> void:
	# Background
	var bg := ColorRect.new()
	bg.color = Color(0.08, 0.06, 0.14)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	# Scroll container for the whole menu
	var scroll := ScrollContainer.new()
	scroll.set_anchors_preset(Control.PRESET_FULL_RECT)
	scroll.offset_left = 50
	scroll.offset_right = -50
	scroll.offset_top = 20
	scroll.offset_bottom = -20
	add_child(scroll)

	var main_vbox := VBoxContainer.new()
	main_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	main_vbox.add_theme_constant_override("separation", 12)
	scroll.add_child(main_vbox)

	# Title
	var title := Label.new()
	title.text = "FAITH EMPIRE SIM"
	title.add_theme_font_size_override("font_size", 36)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_color_override("font_color", Color(0.9, 0.8, 0.3))
	main_vbox.add_child(title)

	var subtitle := Label.new()
	subtitle.text = "Create Your Religion"
	subtitle.add_theme_font_size_override("font_size", 22)
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	main_vbox.add_child(subtitle)

	# Religion name
	var name_hbox := HBoxContainer.new()
	var name_label := Label.new()
	name_label.text = "Religion Name: "
	name_label.add_theme_font_size_override("font_size", 18)
	name_hbox.add_child(name_label)
	religion_name_input = LineEdit.new()
	religion_name_input.text = "The Faith"
	religion_name_input.custom_minimum_size = Vector2(300, 40)
	religion_name_input.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name_hbox.add_child(religion_name_input)
	main_vbox.add_child(name_hbox)

	# Seed
	var seed_hbox := HBoxContainer.new()
	var seed_label := Label.new()
	seed_label.text = "World Seed: "
	seed_label.add_theme_font_size_override("font_size", 18)
	seed_hbox.add_child(seed_label)
	seed_input = LineEdit.new()
	seed_input.text = "42"
	seed_input.custom_minimum_size = Vector2(150, 40)
	seed_hbox.add_child(seed_input)
	main_vbox.add_child(seed_hbox)

	# Birthplace region
	var region_hbox := HBoxContainer.new()
	var region_label := Label.new()
	region_label.text = "Birthplace Region: "
	region_label.add_theme_font_size_override("font_size", 18)
	region_hbox.add_child(region_label)
	region_option = OptionButton.new()
	region_option.custom_minimum_size = Vector2(200, 40)
	region_option.add_item("Central Plains", 0)
	region_option.add_item("Northern Tundra", 1)
	region_option.add_item("Southern Desert", 2)
	region_option.add_item("Eastern Coast", 3)
	region_option.add_item("Western Mountains", 4)
	region_hbox.add_child(region_option)
	main_vbox.add_child(region_hbox)

	# Separator
	main_vbox.add_child(HSeparator.new())

	# Axes header
	var axes_header := Label.new()
	axes_header.text = "Religion Axes (0-100)"
	axes_header.add_theme_font_size_override("font_size", 20)
	main_vbox.add_child(axes_header)

	# Axes sliders
	var axis_names := ["tolerance", "militarism", "knowledge", "ritual", "commerce", "austerity", "charity"]
	for axis_name in axis_names:
		var hbox := HBoxContainer.new()
		var lbl := Label.new()
		lbl.text = axis_name.capitalize() + ": "
		lbl.custom_minimum_size = Vector2(140, 0)
		lbl.add_theme_font_size_override("font_size", 16)
		hbox.add_child(lbl)
		var slider := HSlider.new()
		slider.min_value = 0
		slider.max_value = 100
		slider.value = 50
		slider.step = 1
		slider.custom_minimum_size = Vector2(300, 30)
		slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		hbox.add_child(slider)
		var val_label := Label.new()
		val_label.text = "50"
		val_label.custom_minimum_size = Vector2(40, 0)
		val_label.add_theme_font_size_override("font_size", 16)
		slider.value_changed.connect(func(v: float) -> void: val_label.text = str(int(v)))
		hbox.add_child(val_label)
		main_vbox.add_child(hbox)
		axes_sliders[axis_name] = slider

	# Separator
	main_vbox.add_child(HSeparator.new())

	# Doctrines header
	var doc_header := Label.new()
	doc_header.text = "Doctrines"
	doc_header.add_theme_font_size_override("font_size", 20)
	main_vbox.add_child(doc_header)

	# Doctrine toggles
	var doctrines := ["pacifism", "holy_war", "ritualized_sex", "mandatory_war",
		"iconoclasm", "asceticism", "syncretism", "inquisitions"]
	var doc_descriptions := {
		"pacifism": "Reduces military power but increases diplomacy",
		"holy_war": "Enables holy wars against kingdoms",
		"ritualized_sex": "Increases spread in cities but decreases authority",
		"mandatory_war": "Armies are stronger but stability decreases",
		"iconoclasm": "Reject idols - destroys temples but boosts zeal",
		"asceticism": "Less gold income but more authority",
		"syncretism": "Faster spread but more heresy risk",
		"inquisitions": "Reduces heresy but costs stability",
	}
	for doc_name in doctrines:
		var hbox := HBoxContainer.new()
		var check := CheckBox.new()
		check.text = doc_name.capitalize().replace("_", " ")
		check.add_theme_font_size_override("font_size", 16)
		check.custom_minimum_size = Vector2(200, 35)
		hbox.add_child(check)
		var desc := Label.new()
		desc.text = doc_descriptions.get(doc_name, "")
		desc.add_theme_font_size_override("font_size", 13)
		desc.add_theme_color_override("font_color", Color(0.6, 0.6, 0.7))
		hbox.add_child(desc)
		main_vbox.add_child(hbox)
		doctrine_checks[doc_name] = check

	# Separator
	main_vbox.add_child(HSeparator.new())

	# Start button
	var start_btn := Button.new()
	start_btn.text = "BEGIN YOUR FAITH"
	start_btn.custom_minimum_size = Vector2(400, 60)
	start_btn.add_theme_font_size_override("font_size", 24)
	start_btn.pressed.connect(_on_start_pressed)
	main_vbox.add_child(start_btn)

	# Spacer
	var spacer := Control.new()
	spacer.custom_minimum_size = Vector2(0, 40)
	main_vbox.add_child(spacer)


func _on_start_pressed() -> void:
	var axes := {}
	for axis_name in axes_sliders:
		axes[axis_name] = int(axes_sliders[axis_name].value)

	var doctrines := {}
	for doc_name in doctrine_checks:
		doctrines[doc_name] = doctrine_checks[doc_name].button_pressed

	var seed_val := 42
	if seed_input.text.is_valid_int():
		seed_val = seed_input.text.to_int()

	# Map region selection to approximate city index range
	var region := region_option.selected

	var params := {
		"religion_name": religion_name_input.text if not religion_name_input.text.is_empty() else "The Faith",
		"seed": seed_val,
		"birthplace_region": region,
		"axes": axes,
		"doctrines": doctrines,
	}

	gs.set_meta("start_params", params)
	get_tree().change_scene_to_file("res://Scenes/Main.tscn")
