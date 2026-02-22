extends Ability
class_name MeleeAttack

## Melee attack ability
## Detects enemies in attack cone and deals damage

@export var damage: float = 10.0
@export var attack_range: float = 2.0
@export var attack_arc: float = 180.0  # degrees - wide arc for easier hitting

var combat_component: CombatComponent = null
var hitbox: HitboxArea3D = null

func _ready() -> void:
	super._ready()
	ability_name = "melee_attack"
	cooldown = 0.5
	
	# Find combat component - MeleeAttack is child of AbilityController which is child of CombatComponent
	# So we need to go up two levels: MeleeAttack -> AbilityController -> CombatComponent
	var ability_controller := get_parent()
	if ability_controller:
		combat_component = ability_controller.get_parent() as CombatComponent
	
	print("MeleeAttack: _ready() - combat_component found: ", combat_component != null)
	
	# Find hitbox
	if combat_component:
		hitbox = combat_component.hitbox
		print("MeleeAttack: hitbox found: ", hitbox != null)

func _execute() -> void:
	super._execute()
	
	print("MeleeAttack: === _EXECUTE() CALLED ===")
	
	if not combat_component:
		print("MeleeAttack: ERROR - No combat_component!")
		return
	
	print("MeleeAttack: combat_component exists: true")
	print("MeleeAttack: combat_component.animation_player = ", combat_component.animation_player)
	
	# Play attack animation
	if combat_component.animation_player:
		print("MeleeAttack: AnimationPlayer found!")
		print("MeleeAttack: Current animation: ", combat_component.animation_player.current_animation)
		print("MeleeAttack: Is playing: ", combat_component.animation_player.is_playing())
		print("MeleeAttack: Available animations: ", combat_component.animation_player.get_animation_list())
		
		if combat_component.animation_player.has_animation("Sword_Attack"):
			print("MeleeAttack: Sword_Attack animation exists")
			print("MeleeAttack: Calling play('Sword_Attack')...")
			combat_component.animation_player.play("Sword_Attack")
			print("MeleeAttack: play() called successfully")
			print("MeleeAttack: Current animation after play: ", combat_component.animation_player.current_animation)
			print("MeleeAttack: Is playing after play: ", combat_component.animation_player.is_playing())
			
			# Get animation details
			var anim = combat_component.animation_player.get_animation("Sword_Attack")
			if anim:
				print("MeleeAttack: Animation length: ", anim.length, " seconds")
				
				# Add timeout fallback
				var anim_length = anim.length
				get_tree().create_timer(anim_length + 0.1).timeout.connect(func():
					if combat_component and combat_component.state_machine:
						if combat_component.state_machine.current_state == StateMachine.State.ATTACKING:
							combat_component.state_machine.transition_to(StateMachine.State.IDLE)
				)
			
			# Only connect if not already connected
			if not combat_component.animation_player.animation_finished.is_connected(_on_attack_finished):
				combat_component.animation_player.animation_finished.connect(_on_attack_finished, CONNECT_ONE_SHOT)
		elif combat_component.animation_player.has_animation("attack"):
			print("MeleeAttack: Using fallback 'attack' animation")
			combat_component.animation_player.play("attack")
			combat_component.animation_player.animation_finished.connect(_on_attack_finished, CONNECT_ONE_SHOT)
		else:
			print("MeleeAttack: ERROR - No attack animation found!")
			print("MeleeAttack: This means animations are not loaded properly")
	else:
		print("MeleeAttack: ERROR - No AnimationPlayer found!")
	
	# Enable hitbox during attack
	if hitbox:
		print("MeleeAttack: Enabling hitbox with damage: ", damage)
		hitbox.set_damage(damage)
		hitbox.enable()
		
		# Disable hitbox after a short duration (attack frame window)
		get_tree().create_timer(0.2).timeout.connect(func(): 
			if hitbox:
				hitbox.disable()
				print("MeleeAttack: Hitbox disabled")
		)
	else:
		print("MeleeAttack: WARNING - No hitbox found")
	
	# Detect enemies in attack cone
	print("MeleeAttack: Calling _detect_and_damage_enemies()")
	_detect_and_damage_enemies()
	print("MeleeAttack: === _EXECUTE() COMPLETE ===")

## Detect enemies in attack cone and deal damage
## Uses Player node rotation to determine forward direction
## Attack cone is 45 degrees (front-facing only, not 360)
func _detect_and_damage_enemies() -> void:
	print("MeleeAttack: _detect_and_damage_enemies() called")
	
	if not combat_component:
		print("MeleeAttack: No combat_component in detect!")
		return
	
	var attacker := combat_component.get_parent()
	if not attacker is Node3D:
		print("MeleeAttack: Attacker is not Node3D!")
		return
	
	var attacker_pos: Vector3 = attacker.global_position
	# Forward direction - using +Z because character model faces backwards
	var attacker_forward: Vector3 = attacker.global_transform.basis.z
	
	print("MeleeAttack: Attacker pos: ", attacker_pos, " forward: ", attacker_forward)
	print("MeleeAttack: Attacker rotation.y: ", attacker.rotation.y)
	print("MeleeAttack: Attacker rotation_degrees.y: ", attacker.rotation_degrees.y)
	print("MeleeAttack: Attack arc setting: ", attack_arc)
	
	# Get all potential targets in the scene
	var targets := get_tree().get_nodes_in_group("enemies")
	if attacker.is_in_group("enemies"):
		# If attacker is enemy, target players
		targets = get_tree().get_nodes_in_group("players")
	
	print("MeleeAttack: Found ", targets.size(), " potential targets")
	
	for target in targets:
		if not target is Node3D:
			continue
		
		var target_node := target as Node3D
		var target_pos := target_node.global_position
		
		# Check distance
		var distance: float = attacker_pos.distance_to(target_pos)
		print("MeleeAttack: Target at ", target_pos, " distance: ", distance, " (range: ", attack_range, ")")
		
		if distance > attack_range:
			print("MeleeAttack: Target too far!")
			continue
		
		# Check if target is in attack cone
		var to_target: Vector3 = (target_pos - attacker_pos).normalized()
		var angle := rad_to_deg(attacker_forward.angle_to(to_target))
		
		print("MeleeAttack: Angle to target: ", angle, " (arc: ", attack_arc / 2.0, ")")
		
		# Check if target is in front-facing cone (90 degrees = 45 degrees each side)
		if angle <= 45.0:  # Front-facing cone only
			# Target is in attack cone, deal damage
			print("MeleeAttack: TARGET IN RANGE! Dealing ", damage, " damage")
			if combat_component:
				combat_component.deal_damage_to(target_node, damage)
		else:
			print("MeleeAttack: Target not in attack arc!")

## Handle attack animation finished
func _on_attack_finished(_anim_name: String) -> void:
	print("MeleeAttack: === _ON_ATTACK_FINISHED CALLED ===")
	print("MeleeAttack: Animation name: ", _anim_name)
	print("MeleeAttack: combat_component exists: ", combat_component != null)
	
	if combat_component and combat_component.state_machine:
		print("MeleeAttack: Transitioning state machine to IDLE")
		var result = combat_component.state_machine.transition_to(StateMachine.State.IDLE)
		print("MeleeAttack: Transition result: ", result)
		print("MeleeAttack: New state: ", combat_component.state_machine.current_state)
	else:
		print("MeleeAttack: ERROR - No combat_component or state_machine!")

## Find CombatComponent in node hierarchy
func _find_combat_component(node: Node) -> CombatComponent:
	for child in node.get_children():
		if child is CombatComponent:
			return child
	return null
