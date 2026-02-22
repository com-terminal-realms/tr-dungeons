extends Node
class_name StateMachine

## Manages combat state transitions and action permissions
## Enforces state-based rules for combat actions

signal state_changed(old_state: State, new_state: State)

enum State {
	IDLE,
	MOVING,
	ATTACKING,
	DODGING,
	CASTING,
	STUNNED,
	DEAD
}

var current_state: State = State.IDLE

func _ready() -> void:
	current_state = State.IDLE

func transition_to(new_state: State) -> bool:
	if not can_transition(current_state, new_state):
		return false
	
	var old_state = current_state
	current_state = new_state
	state_changed.emit(old_state, new_state)
	return true

func can_transition(from_state: State, to_state: State) -> bool:
	# Dead state is terminal
	if from_state == State.DEAD:
		return false
	
	# Can always transition to dead
	if to_state == State.DEAD:
		return true
	
	# Stunned can only transition to idle or dead
	if from_state == State.STUNNED:
		return to_state == State.IDLE
	
	# Attacking can only transition to idle or dead
	if from_state == State.ATTACKING:
		return to_state == State.IDLE
	
	# Dodging can only transition to idle or dead
	if from_state == State.DODGING:
		return to_state == State.IDLE
	
	# Casting can only transition to idle or dead
	if from_state == State.CASTING:
		return to_state == State.IDLE
	
	# From idle or moving, can transition to any action state
	return true

func can_move() -> bool:
	return current_state in [State.IDLE, State.MOVING]

func can_attack() -> bool:
	var result = current_state in [State.IDLE, State.MOVING]
	print("StateMachine: can_attack() called, current_state=", current_state, " (IDLE=0, MOVING=1), result=", result)
	return result

func can_dodge() -> bool:
	return current_state in [State.IDLE, State.MOVING]

func can_cast() -> bool:
	return current_state in [State.IDLE, State.MOVING]

func is_dead() -> bool:
	return current_state == State.DEAD

func is_busy() -> bool:
	return current_state in [State.ATTACKING, State.DODGING, State.CASTING, State.STUNNED]
