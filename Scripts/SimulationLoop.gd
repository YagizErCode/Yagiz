extends Node
class_name SimulationLoop
## Main game loop that ticks all systems each turn.

@onready var gs: Node = get_node("/root/GameState")

var religion_system: ReligionSystem
var city_system: CitySystem
var army_system: ArmySystem
var diplomacy_system: DiplomacySystem
var character_system: CharacterSystem
var event_system: EventSystemJSON

const TICK_INTERVAL := 2.0  # seconds between ticks at x1 speed


func setup(rs: ReligionSystem, cs: CitySystem, as_: ArmySystem,
		ds: DiplomacySystem, chs: CharacterSystem, es: EventSystemJSON) -> void:
	religion_system = rs
	city_system = cs
	army_system = as_
	diplomacy_system = ds
	character_system = chs
	event_system = es


func _process(delta: float) -> void:
	if gs.is_event_modal_open or gs.speed == 0:
		return

	gs.tick_timer += delta * gs.speed
	if gs.tick_timer >= TICK_INTERVAL:
		gs.tick_timer -= TICK_INTERVAL
		_do_tick()


func _do_tick() -> void:
	gs.turn += 1

	# Run all systems
	if religion_system:
		religion_system.spread_tick()
		religion_system.process_pilgrimages()
	if city_system:
		city_system.city_tick()
	if army_system:
		army_system.army_tick()
	if diplomacy_system:
		diplomacy_system.diplomacy_tick()
	if character_system:
		character_system.character_tick()
	if event_system:
		event_system.event_tick()

	gs.turn_advanced.emit(gs.turn)


func force_next_turn() -> void:
	if gs.is_event_modal_open:
		return
	gs.tick_timer = 0.0
	_do_tick()
