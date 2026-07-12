class_name StateMachine
extends Node

signal state_changed(from: FighterState, to: FighterState)

var current_state: FighterState = null
var _states: Dictionary = {}
var fighter: Node

func _ready() -> void:
	for child in get_children():
		if child is FighterState:
			_states[child.name] = child
			child.state_machine = self
			

func init(fighter_ref: Node, initial_state_name: String) -> void:
	fighter = fighter_ref
	for child in get_children():
		if child is FighterState:
			child.fighter = fighter_ref
			child.state_machine = self
	change_to(initial_state_name)

func change_to(state_name: String) -> void:
	assert(_states.has(state_name), "StateMachine: stato '%s' non esiste!" % state_name)
	var new_state: FighterState = _states[state_name]
	if current_state == new_state:
		return
	var prev: FighterState = current_state
	if current_state != null:
		current_state.on_exit(new_state)
	current_state = new_state
	current_state.on_enter(prev)
	state_changed.emit(prev, new_state)

func process_physics(delta: float) -> void:
	if current_state != null:
		current_state.physics_update(delta)

func get_state(state_name: String) -> FighterState:
	return _states.get(state_name, null)

func is_in_state(state_name: String) -> bool:
	return current_state != null and current_state.name == state_name
