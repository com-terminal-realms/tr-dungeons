extends Node
class_name CombatComponent

## Main combat component coordinating all combat actions
## Manages state transitions, damage calculation, and combat signals

signal damage_taken(amount: float, source: Node)
signal damage_dealt(amount: float, target: Node)

@export var stats_component: StatsComponent
@export var state_machine: StateMachine
@export var ability_controller: AbilityController
@export var hitbox: HitboxArea3D
@export var hurtbox: HurtboxArea3D
@export var animation_player: AnimationPlayer
@export var loot_table: LootTable

var invulnerable: bool = false
var attack_cooldown_timer: float = 0.0

func _ready() -> void:
	# Auto-find components if not set
	if not stats_component:
		stats_component = _find_component(StatsComponent)
	if not state_machine:
		state_machine = _find_component(StateMachine)
	if not ability_controller:
		# AbilityController is a child of CombatComponent, not a sibling
		ability_controller = get_node_or_null("AbilityController")
	if not hitbox:
		hitbox = _find_area3d_by_type(HitboxArea3D)
	if not hurtbox:
		hurtbox = _find_area3d_by_type(HurtboxArea3D)
	if not animation_player:
		animation_player = _find_animation_player_recursive(get_parent())
	
	print("CombatComponent: Found components - Stats:", stats_component != null, " StateMachine:", state_machine != null, " AbilityController:", ability_controller != null)
	
	# Connect signals
	if stats_component:
		stats_component.died.connect(_on_died)
	
	if hurtbox:
		hurtbox.hit_received.connect(_on_hurtbox_hit)
	
	# Disable hitbox by default
	if hitbox:
		hitbox.disable()

func _process(delta: float) -> void:
	# Update attack cooldown
	if attack_cooldown_timer > 0.0:
		attack_cooldown_timer -= delta

## Perform a melee attack
func attack() -> bool:
	print("CombatComponent: attack() called")
	
	if not state_machine:
		print("CombatComponent: No state_machine!")
		return false
	
	if not state_machine.can_attack():
		print("CombatComponent: can_attack() returned false, current state: ", state_machine.current_state)
		return false
	
	if attack_cooldown_timer > 0.0:
		print("CombatComponent: Attack on cooldown: ", attack_cooldown_timer)
		return false
	
	if not stats_component:
		print("CombatComponent: No stats_component!")
		return false
	
	print("CombatComponent: All checks passed, transitioning to ATTACKING state")
	
	# Transition to attacking state
	state_machine.transition_to(StateMachine.State.ATTACKING)
	
	# Activate melee attack ability
	if ability_controller:
		print("CombatComponent: Activating melee_attack ability")
		ability_controller.activate_ability("melee_attack")
	else:
		print("CombatComponent: No ability_controller!")
	
	# Set cooldown based on attack speed
	var attack_speed := stats_component.stats.attack_speed if stats_component.stats else 1.0
	attack_cooldown_timer = 1.0 / attack_speed
	
	# Don't transition back to IDLE immediately - let animation finish
	# The animation_finished callback in MeleeAttack will handle the transition
	
	print("CombatComponent: Attack started, cooldown set to ", attack_cooldown_timer)
	return true

## Perform a dodge roll
func dodge(direction: Vector3) -> bool:
	if not state_machine or not state_machine.can_dodge():
		return false
	
	if not stats_component or not stats_component.consume_stamina(20.0):
		return false
	
	# Transition to dodging state
	state_machine.transition_to(StateMachine.State.DODGING)
	
	# Grant invulnerability frames
	invulnerable = true
	get_tree().create_timer(0.3).timeout.connect(func(): invulnerable = false)
	
	# Apply dodge movement
	var parent := get_parent()
	if parent is CharacterBody3D:
		var dodge_distance := 4.0
		var dodge_duration := 0.3
		parent.velocity = direction.normalized() * (dodge_distance / dodge_duration)
	
	# Play dodge animation
	if animation_player and animation_player.has_animation("dodge"):
		animation_player.play("dodge")
		animation_player.animation_finished.connect(_on_dodge_finished, CONNECT_ONE_SHOT)
	else:
		# No animation, return to idle after duration
		get_tree().create_timer(0.3).timeout.connect(_on_dodge_finished.bind(""))
	
	return true

## Take damage from a source
func take_damage(amount: float, source: Node = null) -> void:
	if invulnerable:
		return
	
	if state_machine and state_machine.is_dead():
		return
	
	# Calculate final damage
	var final_damage := calculate_damage(amount, source)
	var is_critical := _was_critical_hit(source)
	
	# Apply damage to NEW stats component
	if stats_component:
		stats_component.reduce_health(final_damage)
	
	# ALSO apply damage to OLD Health component for health bar compatibility
	var parent := get_parent()
	if parent:
		for child in parent.get_children():
			if child is Health:
				child.take_damage(int(final_damage))
				break
	
	damage_taken.emit(final_damage, source)
	
	# Track stats if player is taking damage
	if parent and parent.is_in_group("player"):
		if DungeonStatsTracker.instance:
			var source_name: String = source.name if source else "Unknown"
			DungeonStatsTracker.instance.record_player_damage(final_damage, source_name)
	
	# Spawn damage number
	if parent is Node3D:
		DamageNumber.spawn(final_damage, parent.global_position, is_critical)
	
	# Trigger hit feedback
	_trigger_hit_feedback(final_damage, source)

## Calculate damage with armor and critical hits
func calculate_damage(base_damage: float, source: Node) -> float:
	var final_damage := base_damage
	
	# Apply armor reduction
	if stats_component and stats_component.stats:
		final_damage -= stats_component.stats.armor
	
	# Ensure minimum damage of 1
	final_damage = max(1.0, final_damage)
	
	# Check for critical hit from source
	if _was_critical_hit(source):
		var source_stats := _get_source_stats(source)
		if source_stats and source_stats.stats:
			final_damage *= source_stats.stats.critical_multiplier
	
	return final_damage

## Check if attack was a critical hit
func _was_critical_hit(source: Node) -> bool:
	if not source:
		return false
	
	var source_stats := _get_source_stats(source)
	if source_stats and source_stats.stats:
		return randf() < source_stats.stats.critical_chance
	
	return false

## Get stats component from source
func _get_source_stats(source: Node) -> StatsComponent:
	if source.has_method("get_stats_component"):
		return source.get_stats_component()
	return null

## Deal damage to a target
func deal_damage_to(target: Node, damage: float) -> void:
	if not target:
		return
	
	# Find target's combat component
	var target_combat := _find_combat_component(target)
	if target_combat:
		target_combat.take_damage(damage, get_parent())
		damage_dealt.emit(damage, target)
		
		# Track stats if player is attacking
		var attacker := get_parent()
		if attacker and attacker.is_in_group("player"):
			if DungeonStatsTracker.instance:
				var target_name: String = target.name if target else "Unknown"
				DungeonStatsTracker.instance.record_player_attack(true, damage, target_name)
	else:
		# Miss - no combat component found
		var attacker := get_parent()
		if attacker and attacker.is_in_group("player"):
			if DungeonStatsTracker.instance:
				var target_name: String = target.name if target else "Unknown"
				DungeonStatsTracker.instance.record_player_attack(false, 0.0, target_name)

## Get stats component (for external access)
func get_stats_component() -> StatsComponent:
	return stats_component

## Handle hurtbox hit
func _on_hurtbox_hit(hitbox_area: HitboxArea3D) -> void:
	var damage := hitbox_area.get_damage()
	var source := hitbox_area.get_source()
	take_damage(damage, source)

## Handle death
func _on_died() -> void:
	if state_machine:
		state_machine.transition_to(StateMachine.State.DEAD)
	
	var parent := get_parent()
	
	# Track stats
	if parent:
		if parent.is_in_group("player"):
			# Player death
			if DungeonStatsTracker.instance:
				DungeonStatsTracker.instance.record_player_death()
		elif parent.is_in_group("enemies"):
			# Enemy death
			if DungeonStatsTracker.instance:
				var is_boss := parent.is_in_group("boss")
				DungeonStatsTracker.instance.record_enemy_killed(parent.name, is_boss)
	
	# Play death animation
	if animation_player and animation_player.has_animation("death"):
		animation_player.play("death")
	
	# Spawn loot drops
	_spawn_loot_drops()
	
	# Persist corpse for 5 seconds
	get_tree().create_timer(5.0).timeout.connect(_remove_corpse)

## Remove corpse
func _remove_corpse() -> void:
	var parent := get_parent()
	if parent:
		parent.queue_free()

## Spawn loot drops at death location
func _spawn_loot_drops() -> void:
	if not loot_table:
		return
	
	var dropped_items := loot_table.roll()
	if dropped_items.is_empty():
		return
	
	var parent := get_parent()
	if not parent or not parent is Node3D:
		return
	
	var death_position: Vector3 = parent.global_position
	
	# Spawn each dropped item using PickupItem
	for item in dropped_items:
		PickupItem.spawn(item, death_position)

## Handle dodge finished
func _on_dodge_finished(_anim_name: String = "") -> void:
	if state_machine:
		state_machine.transition_to(StateMachine.State.IDLE)

## Trigger hit feedback effects
func _trigger_hit_feedback(damage: float, source: Node) -> void:
	var parent := get_parent()
	if not parent:
		return
	
	# Red flash effect
	_apply_red_flash()
	
	# Camera shake for player
	if parent.is_in_group("player"):
		_apply_camera_shake(damage)
	
	# Knockback
	if parent is CharacterBody3D and source and source is Node3D:
		_apply_knockback(parent, source)
	
	# Hit particles
	_spawn_hit_particles(parent.global_position if parent is Node3D else Vector3.ZERO)
	
	# Play hit sound
	_play_hit_sound()

## Apply red flash to entity
func _apply_red_flash() -> void:
	var parent := get_parent()
	if not parent:
		return
	
	# Find MeshInstance3D to apply material override
	var mesh_instance := _find_mesh_instance(parent)
	if not mesh_instance:
		return
	
	# Create red material override
	var red_material := StandardMaterial3D.new()
	red_material.albedo_color = Color(1.0, 0.3, 0.3, 1.0)
	red_material.emission_enabled = true
	red_material.emission = Color(1.0, 0.0, 0.0, 1.0)
	
	# Apply override
	var original_material := mesh_instance.get_surface_override_material(0)
	mesh_instance.set_surface_override_material(0, red_material)
	
	# Restore after 0.5 seconds
	get_tree().create_timer(0.5).timeout.connect(func():
		if mesh_instance:
			mesh_instance.set_surface_override_material(0, original_material)
	)

## Apply camera shake
func _apply_camera_shake(damage: float) -> void:
	# Find camera in scene
	var camera: Camera3D = get_viewport().get_camera_3d()
	if not camera:
		return
	
	# Calculate shake intensity based on damage
	var intensity: float = min(damage / 50.0, 1.0)  # Max intensity at 50 damage
	
	# Apply shake (simple implementation)
	var original_position: Vector3 = camera.position
	var shake_amount: float = 0.1 * intensity
	
	for i in range(5):
		await get_tree().create_timer(0.02).timeout
		if camera:
			camera.position = original_position + Vector3(
				randf_range(-shake_amount, shake_amount),
				randf_range(-shake_amount, shake_amount),
				0
			)
	
	# Restore original position
	if camera:
		camera.position = original_position

## Apply knockback to entity
func _apply_knockback(body: CharacterBody3D, source: Node3D) -> void:
	var direction := body.global_position.direction_to(source.global_position) * -1.0
	direction.y = 0  # Keep knockback horizontal
	body.velocity += direction.normalized() * 0.5  # 0.5m knockback

## Spawn hit particle effects
func _spawn_hit_particles(position: Vector3) -> void:
	# Create simple particle effect
	var particles := CPUParticles3D.new()
	particles.emitting = true
	particles.one_shot = true
	particles.explosiveness = 1.0
	particles.amount = 10
	particles.lifetime = 0.5
	particles.direction = Vector3.UP
	particles.spread = 45.0
	particles.initial_velocity_min = 2.0
	particles.initial_velocity_max = 4.0
	particles.gravity = Vector3(0, -9.8, 0)
	
	# Red color for blood/impact
	var gradient := Gradient.new()
	gradient.add_point(0.0, Color(1.0, 0.0, 0.0, 1.0))
	gradient.add_point(1.0, Color(0.5, 0.0, 0.0, 0.0))
	particles.color_ramp = gradient
	
	# Add to scene
	get_tree().root.add_child(particles)
	particles.global_position = position
	
	# Remove after lifetime
	get_tree().create_timer(0.6).timeout.connect(func():
		if particles:
			particles.queue_free()
	)

## Play hit sound effect
func _play_hit_sound() -> void:
	# TODO: Implement audio system integration
	# For now, just a placeholder
	pass

## Find MeshInstance3D in node hierarchy
func _find_mesh_instance(node: Node) -> MeshInstance3D:
	if node is MeshInstance3D:
		return node
	
	for child in node.get_children():
		var result := _find_mesh_instance(child)
		if result:
			return result
	
	return null

## Find component of specific type
func _find_component(component_type) -> Node:
	var parent := get_parent()
	if not parent:
		return null
	
	for child in parent.get_children():
		if is_instance_of(child, component_type):
			return child
	
	return null

## Find Area3D of specific type
func _find_area3d_by_type(area_type) -> Area3D:
	var parent := get_parent()
	if not parent:
		return null
	
	for child in parent.get_children():
		if is_instance_of(child, area_type):
			return child
	
	return null

## Find CombatComponent in target node
func _find_combat_component(node: Node) -> CombatComponent:
	# Check direct children
	for child in node.get_children():
		if child is CombatComponent:
			return child
	
	return null

## Find AnimationPlayer recursively in node hierarchy
func _find_animation_player_recursive(node: Node) -> AnimationPlayer:
	if node is AnimationPlayer:
		return node
	
	for child in node.get_children():
		var result := _find_animation_player_recursive(child)
		if result:
			return result
	
	return null
