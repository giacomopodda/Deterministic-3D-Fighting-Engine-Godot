class_name FighterState
extends Node

## Riferimenti iniettati dalla StateMachine — tipizzati come Node
## per evitare dipendenze circolari. Cast esplicito dove serve.
var fighter: Node
var state_machine: Node

func on_enter(_from: FighterState) -> void:
	pass

func physics_update(_delta: float) -> void:
	pass

func on_exit(_to: FighterState) -> void:
	pass

func change_to(state_name: String) -> void:
	state_machine.change_to(state_name)

func input() -> InputReader:
	return fighter.input_reader as InputReader

func dir_to_opponent() -> Vector3:
	return fighter.get_dir_to_opponent()
