extends CanvasLayer
class_name UIController
## Wires all UI panels and responds to game events.

@onready var gs: Node = get_node("/root/GameState")

# Panel references - set by GameRoot
var left_panel: Control
var city_panel: Control
var army_panel: Control
var diplomacy_panel: Control
var event_modal: Control
var chronicle_panel: Control
var speed_controls: Control
var sect_panel: Control

# System references
var city_system: CitySystem
var army_system: ArmySystem
var religion_system: ReligionSystem
var diplomacy_system: DiplomacySystem
var event_system: EventSystemJSON
var selection_controller: SelectionController
var world_generator: WorldGenerator

var _current_event: Dictionary = {}


func setup(systems: Dictionary) -> void:
	city_system = systems.get("city")
	army_system = systems.get("army")
	religion_system = systems.get("religion")
	diplomacy_system = systems.get("diplomacy")
	event_system = systems.get("event")
	selection_controller = systems.get("selection")
	world_generator = systems.get("world")

	if selection_controller:
		selection_controller.city_selected.connect(_on_city_selected)
		selection_controller.army_selected.connect(_on_army_selected)
		selection_controller.deselected.connect(_on_deselected)
	if event_system:
		event_system.event_display_requested.connect(_on_event_triggered)

	gs.turn_advanced.connect(_on_turn_advanced)
	gs.faith_updated.connect(_on_faith_updated)
	gs.chronicle_entry.connect(_on_chronicle_entry)
	gs.sect_created.connect(_on_sect_created)


func _on_turn_advanced(_turn: int) -> void:
	_update_left_panel()
	if world_generator:
		for cid in gs.cities:
			world_generator.update_city_marker(cid)
	if army_system:
		army_system.update_all_markers()


func _on_faith_updated() -> void:
	_update_left_panel()


func _update_left_panel() -> void:
	if left_panel == null:
		return
	var gold_label := left_panel.get_node_or_null("VBox/GoldLabel")
	var auth_label := left_panel.get_node_or_null("VBox/AuthLabel")
	var legit_label := left_panel.get_node_or_null("VBox/LegitLabel")
	var spread_label := left_panel.get_node_or_null("VBox/SpreadLabel")
	var turn_label := left_panel.get_node_or_null("VBox/TurnLabel")
	var doctrine_label := left_panel.get_node_or_null("VBox/DoctrineLabel")
	var seed_label := left_panel.get_node_or_null("VBox/SeedLabel")

	if gold_label:
		gold_label.text = "Gold: %d" % int(gs.player_religion.gold)
	if auth_label:
		auth_label.text = "Authority: %d" % int(gs.player_religion.authority)
	if legit_label:
		legit_label.text = "Legitimacy: %d" % int(gs.player_religion.legitimacy)
	if spread_label:
		spread_label.text = "Spread: %.1f%%" % gs.player_religion.spread_rate
	if turn_label:
		turn_label.text = "Turn: %d" % gs.turn
	if seed_label:
		seed_label.text = "Seed: %d" % gs.world_seed
	if doctrine_label:
		var active_docs: Array[String] = []
		for d in gs.player_religion.doctrines:
			if gs.player_religion.doctrines[d]:
				active_docs.append(d)
		doctrine_label.text = "Doctrines: " + (", ".join(active_docs) if not active_docs.is_empty() else "None")


func _on_city_selected(city_id: int) -> void:
	if city_id not in gs.cities:
		return
	_hide_all_panels()
	if city_panel:
		city_panel.visible = true
		_populate_city_panel(city_id)


func _on_army_selected(army_id: int) -> void:
	if army_id not in gs.armies:
		return
	_hide_all_panels()
	if army_panel:
		army_panel.visible = true
		_populate_army_panel(army_id)


func _on_deselected() -> void:
	_hide_all_panels()


func _hide_all_panels() -> void:
	if city_panel:
		city_panel.visible = false
	if army_panel:
		army_panel.visible = false
	if diplomacy_panel:
		diplomacy_panel.visible = false
	if sect_panel:
		sect_panel.visible = false


func _populate_city_panel(city_id: int) -> void:
	var city: Dictionary = gs.cities[city_id]
	var name_label := city_panel.get_node_or_null("VBox/NameLabel")
	var stats_label := city_panel.get_node_or_null("VBox/StatsLabel")
	var faith_label := city_panel.get_node_or_null("VBox/FaithLabel")
	var buildings_label := city_panel.get_node_or_null("VBox/BuildingsLabel")
	var kingdom_label := city_panel.get_node_or_null("VBox/KingdomLabel")

	if name_label:
		name_label.text = city.name
	if stats_label:
		stats_label.text = "Pop: %d | Wealth: %d | Dev: %d\nEdu: %d | Stab: %d | Sec: %d" % [
			city.population, int(city.wealth), int(city.development),
			int(city.education), int(city.stability), int(city.security)]
	if faith_label:
		faith_label.text = "Faith: %.0f%% | Heresy: %.0f%% | Dom: %.0f%%" % [
			city.faith_share * 100, city.heresy_share * 100, city.dominance * 100]
	if buildings_label:
		buildings_label.text = "Buildings: " + (", ".join(city.buildings) if not city.buildings.is_empty() else "None")
	if kingdom_label:
		var kname := "Independent"
		if city.kingdom_id >= 0 and city.kingdom_id in gs.kingdoms:
			kname = gs.kingdoms[city.kingdom_id].name
		kingdom_label.text = "Kingdom: %s" % kname

	# Build buttons
	var build_container := city_panel.get_node_or_null("VBox/BuildScroll/BuildContainer")
	if build_container:
		for child in build_container.get_children():
			child.queue_free()
		if city.dominance > 0.5:
			for bname in GameState.BUILDING_DATA:
				var bdata: Dictionary = GameState.BUILDING_DATA[bname]
				var btn := Button.new()
				btn.text = "%s ($%d)" % [bname.capitalize(), bdata.cost]
				btn.custom_minimum_size = Vector2(0, 50)
				var captured_city_id := city_id
				var captured_bname := bname
				btn.pressed.connect(func() -> void:
					if city_system and city_system.queue_building(captured_city_id, captured_bname):
						_populate_city_panel(captured_city_id)
				)
				build_container.add_child(btn)

	# Action buttons
	var action_container := city_panel.get_node_or_null("VBox/ActionContainer")
	if action_container:
		for child in action_container.get_children():
			child.queue_free()
		if city.dominance > 0.4:
			# Raise army button
			var raise_btn := Button.new()
			raise_btn.text = "Raise Army (500 troops, $250)"
			raise_btn.custom_minimum_size = Vector2(0, 50)
			var cap_cid := city_id
			raise_btn.pressed.connect(func() -> void:
				if army_system:
					army_system.raise_army(cap_cid, 500)
			)
			action_container.add_child(raise_btn)

			# Holy city button
			if not city.is_holy_city and city.dominance > 0.6:
				var holy_btn := Button.new()
				holy_btn.text = "Declare Holy City"
				holy_btn.custom_minimum_size = Vector2(0, 50)
				var cap_cid2 := city_id
				holy_btn.pressed.connect(func() -> void:
					if religion_system:
						religion_system.declare_holy_city(cap_cid2)
						_populate_city_panel(cap_cid2)
				)
				action_container.add_child(holy_btn)


func _populate_army_panel(army_id: int) -> void:
	var army: Dictionary = gs.armies[army_id]
	var info_label := army_panel.get_node_or_null("VBox/InfoLabel")
	var status_label := army_panel.get_node_or_null("VBox/StatusLabel")

	if info_label:
		var owner := "Your Army"
		if army.kingdom_id >= 0 and army.kingdom_id in gs.kingdoms:
			owner = gs.kingdoms[army.kingdom_id].name
		info_label.text = "%s\nSize: %d troops" % [owner, army.size]
	if status_label:
		if army.sieging:
			status_label.text = "Sieging (%.0f%%)" % army.siege_progress
		elif army.moving:
			status_label.text = "Moving..."
		else:
			status_label.text = "Idle"

	# Move buttons - show list of cities to move to
	var move_container := army_panel.get_node_or_null("VBox/MoveScroll/MoveContainer")
	if move_container and army.kingdom_id == -1:  # Player army
		for child in move_container.get_children():
			child.queue_free()
		if not army.sieging:
			# Show nearest 8 cities
			var sorted_cities: Array[Dictionary] = []
			for cid in gs.cities:
				var city: Dictionary = gs.cities[cid]
				var d: float = army.pos.distance_to(city.pos)
				sorted_cities.append({"id": cid, "name": city.name, "dist": d, "kid": city.kingdom_id})
			sorted_cities.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return a.dist < b.dist)

			var count := 0
			for sc in sorted_cities:
				if count >= 8:
					break
				var btn := Button.new()
				var label := sc.name
				if sc.kid != -1 and sc.kid in gs.kingdoms:
					label += " (%s)" % gs.kingdoms[sc.kid].name
				btn.text = "Move to %s" % label
				btn.custom_minimum_size = Vector2(0, 45)
				var cap_aid := army_id
				var cap_cid: int = sc.id
				btn.pressed.connect(func() -> void:
					if army_system:
						army_system.move_army(cap_aid, cap_cid)
						_populate_army_panel(cap_aid)
				)
				move_container.add_child(btn)
				count += 1


func _on_event_triggered(ev: Dictionary) -> void:
	_current_event = ev
	if event_modal == null:
		return
	event_modal.visible = true

	var title_label := event_modal.get_node_or_null("Panel/VBox/TitleLabel")
	var desc_label := event_modal.get_node_or_null("Panel/VBox/DescLabel")
	var choices_container := event_modal.get_node_or_null("Panel/VBox/ChoicesScroll/ChoicesContainer")

	if title_label:
		title_label.text = str(ev.get("title", "Event"))
	if desc_label:
		desc_label.text = str(ev.get("description", ""))
	if choices_container:
		for child in choices_container.get_children():
			child.queue_free()

		var choices: Array = ev.get("choices", [])
		for i in choices.size():
			var choice: Dictionary = choices[i]
			var btn := Button.new()
			var effects: Dictionary = choice.get("effects", {})
			var effect_text := ""
			for key in effects:
				effect_text += " [%s: %s]" % [key, str(effects[key])]
			btn.text = str(choice.get("text", "OK")) + effect_text
			btn.custom_minimum_size = Vector2(0, 60)
			btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			var cap_i := i
			var cap_ev := ev
			btn.pressed.connect(func() -> void:
				if event_system:
					event_system.apply_choice(cap_ev, cap_i)
				event_modal.visible = false
			)
			choices_container.add_child(btn)


func _on_chronicle_entry(text: String) -> void:
	if chronicle_panel == null:
		return
	var log_label := chronicle_panel.get_node_or_null("VBox/ScrollContainer/LogLabel")
	if log_label:
		log_label.text += text + "\n"
		# Auto scroll
		var scroll := chronicle_panel.get_node_or_null("VBox/ScrollContainer")
		if scroll is ScrollContainer:
			await get_tree().process_frame
			scroll.scroll_vertical = int(scroll.get_v_scroll_bar().max_value)


func _on_sect_created(sect_data: Dictionary) -> void:
	# Could open sect panel
	pass


func show_diplomacy() -> void:
	_hide_all_panels()
	if diplomacy_panel:
		diplomacy_panel.visible = true
		_populate_diplomacy_panel()


func _populate_diplomacy_panel() -> void:
	var list_container := diplomacy_panel.get_node_or_null("VBox/ScrollContainer/ListContainer")
	if list_container == null:
		return

	for child in list_container.get_children():
		child.queue_free()

	for kid in gs.kingdoms:
		var k: Dictionary = gs.kingdoms[kid]
		var vbox := VBoxContainer.new()
		var label := Label.new()
		var pacts := diplomacy_system.get_pacts_for_kingdom(kid) if diplomacy_system else []
		var pact_text := ""
		for p in pacts:
			pact_text += " [%s]" % p.type
		var war_text := " AT WAR" if -1 in k.at_war_with else ""
		label.text = "%s%s%s" % [k.name, pact_text, war_text]
		label.add_theme_font_size_override("font_size", 18)
		vbox.add_child(label)

		var hbox := HBoxContainer.new()
		# NAP button
		var nap_btn := Button.new()
		nap_btn.text = "NAP"
		nap_btn.custom_minimum_size = Vector2(70, 40)
		var cap_kid := kid
		nap_btn.pressed.connect(func() -> void:
			if diplomacy_system:
				diplomacy_system.propose_pact(cap_kid, "non_aggression")
				_populate_diplomacy_panel()
		)
		hbox.add_child(nap_btn)
		# Trade button
		var trade_btn := Button.new()
		trade_btn.text = "Trade"
		trade_btn.custom_minimum_size = Vector2(70, 40)
		var cap_kid2 := kid
		trade_btn.pressed.connect(func() -> void:
			if diplomacy_system:
				diplomacy_system.propose_pact(cap_kid2, "trade")
				_populate_diplomacy_panel()
		)
		hbox.add_child(trade_btn)
		# Holy War button
		if gs.player_religion.doctrines.get("holy_war", false):
			var hw_btn := Button.new()
			hw_btn.text = "Holy War"
			hw_btn.custom_minimum_size = Vector2(90, 40)
			var cap_kid3 := kid
			hw_btn.pressed.connect(func() -> void:
				if diplomacy_system:
					diplomacy_system.player_declare_holy_war(cap_kid3)
					_populate_diplomacy_panel()
			)
			hbox.add_child(hw_btn)

		vbox.add_child(hbox)
		list_container.add_child(vbox)


func show_sects() -> void:
	_hide_all_panels()
	if sect_panel:
		sect_panel.visible = true
		_populate_sect_panel()


func _populate_sect_panel() -> void:
	var list_container := sect_panel.get_node_or_null("VBox/ScrollContainer/ListContainer")
	if list_container == null:
		return
	for child in list_container.get_children():
		child.queue_free()

	if gs.sects.is_empty():
		var label := Label.new()
		label.text = "No sects have formed yet."
		list_container.add_child(label)
		return

	for sect in gs.sects:
		var label := Label.new()
		label.text = "%s (cities: %d)" % [sect.name, sect.cities.size()]
		label.add_theme_font_size_override("font_size", 18)
		list_container.add_child(label)


func toggle_chronicle() -> void:
	if chronicle_panel:
		chronicle_panel.visible = not chronicle_panel.visible
