extends Node
class_name CharacterStateMachine

signal state_changed(from_state: CharacterState, to_state: CharacterState)

## The state that the character starts in.
@export var initial_state: CharacterState

## Reference to the currently active state.
var current_state: CharacterState
## Dictionary mapping state names (lowercase) to CharacterState nodes.
var states: Dictionary = {}

func _ready() -> void:
	# Wait for the parent character to be ready so all components are configured.
	await get_parent().ready
	
	# Register all child nodes that inherit from CharacterState.
	for child in get_children():
		if child is CharacterState:
			var state_name = child.name.to_lower()
			states[state_name] = child
			child.character = get_parent() as Character
			child.state_machine = self
	
	# Transition to the initial state.
	if initial_state:
		change_state(initial_state.name)
	elif get_child_count() > 0:
		var first_child = get_child(0)
		if first_child is CharacterState:
			change_state(first_child.name)
		else:
			push_warning("CharacterStateMachine: No valid initial state or child states found!")

func _unhandled_input(event: InputEvent) -> void:
	if current_state:
		current_state.handle_input(event)

func _process(delta: float) -> void:
	if current_state:
		current_state.update(delta)

func _physics_process(delta: float) -> void:
	if current_state:
		current_state.physics_update(delta)

## (case-insensitive).
func change_state(new_state_name: String) -> void:
	var state_key = new_state_name.to_lower()
	if not states.has(state_key):
		push_warning("CharacterStateMachine: State '" + new_state_name + "' not found!")
		return
	
	var next_state: CharacterState = states[state_key]
	if current_state == next_state:
		return
	
	var previous_state = current_state
	if current_state:
		current_state.exit()
		
	# Globally prevent animation priority locking when changing states
	var character = get_parent() as Character
	if character and character.animation_manager:
		character.animation_manager.current_priority = 0
	
	current_state = next_state
	current_state.enter()
	
	state_changed.emit(previous_state, current_state)
