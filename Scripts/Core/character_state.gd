extends Node
class_name CharacterState

## Reference to the character node that this state controls.
var character: Character

## Reference to the state machine managing this state.
var state_machine: CharacterStateMachine

## Called when the state is entered.
func enter() -> void:
	pass

## Called when the state is exited.
func exit() -> void:
	pass

## Called during the _unhandled_input hook.
func handle_input(_event: InputEvent) -> void:
	pass

## Called during the _process hook.
func update(_delta: float) -> void:
	pass

## Called during the _physics_process hook.
func physics_update(_delta: float) -> void:
	pass
