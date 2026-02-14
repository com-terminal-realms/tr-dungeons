# Design Document: Combat System

## Overview

The combat system is a real-time PvX combat implementation for a MajorMUD-inspired isometric 3D action RPG built in Godot 4. The system provides responsive, satisfying combat through a component-based architecture using signals for loose coupling. The design emphasizes modularity, testability, and clear separation of concerns.

The combat system consists of:
- **Component-based architecture**: Reusable components (CombatComponent, StatsComponent, AbilityController) attached to entities
- **Hitbox/Hurtbox system**: Area3D-based collision detection for damage dealing and receiving
- **State machine**: Finite State Machine (FSM) managing combat states and transitions
- **Resource management**: Health, mana, and stamina systems with regeneration
- **Enemy AI**: Detection, chase, and attack behaviors using NavigationAgent3D
- **Ability system**: Extensible ability framework supporting melee attacks and projectile spells
- **Feedback systems**: Visual and audio feedback for hits, damage, and death

## Architecture

### High-Level Component Diagram

```
Player/Enemy (CharacterBody3D)
├── CollisionShape3D (physics body)
├── MeshInstance3D (visual representation)
├── AnimationPlayer (animations)
├── CombatComponent (combat logic)
│   ├── StatsComponent (health/mana/stamina)
│   ├── StateMachine (state management)
│   └── AbilityController (ability management)
├── HitboxArea3D (deals damage)
│   └── CollisionShape3D
├── HurtboxArea3D (receives damage)
│   └── CollisionShape3D
└── NavigationAgent3D (enemy pathfinding)
```

### Component Responsibilities

**CombatComponent**:
- Coordinates combat actions (attack, dodge, take damage)
- Manages state transitions
- Emits combat-related signals
- Handles death and respawn logic

**StatsComponent**:
- Stores and manages combat statistics (CombatStats resource)
- Handles resource regeneration (mana, stamina)
- Tracks current values (health, mana, stamina)
- Emits resource change signals

**StateMachine**:
- Manages combat states (IDLE, MOVING, ATTACKING, DODGING, CASTING, STUNNED, DEAD)
- Enforces state transition rules
- Delegates behavior to state-specific handlers

**AbilityController**:
- Manages ability instances
- Handles ability activation and cooldowns
- Validates resource costs
- Emits ability-related signals

**HitboxArea3D**:
- Area3D that deals damage when overlapping with HurtboxArea3D
- Configured with collision layers to only hit appropriate targets
- Activated/deactivated during attack animations

**HurtboxArea3D**:
- Area3D that receives damage when overlapping with HitboxArea3D
- Signals parent CombatComponent when hit
- Configured with collision masks to only receive damage from appropriate sources

### Signal Flow

```
Attack Input → CombatComponent.attack()
  ↓
StateMachine.transition_to(ATTACKING)
  ↓
AbilityController.activate_ability("melee_attack")
  ↓
Animation plays → Hitbox enabled at attack frame
  ↓
Hitbox.area_entered(enemy_hurtbox)
  ↓
Enemy.CombatComponent.take_damage(amount, source)
  ↓
Enemy.StatsComponent.reduce_health(amount)
  ↓
Signals emitted: damage_taken, health_changed
  ↓
UI updates, feedback effects play
```

## Components and Interfaces

### CombatStats Resource

```gdscript
# res://scripts/combat/combat_stats.gd
class_name CombatStats
extends Resource

@export var max_health: float = 100.0
@export var max_mana: float = 100.0
@export var max_stamina: float = 100.0
@export var attack_damage: float = 10.0
@export var attack_speed: float = 1.0  # attacks per second
@export var attack_range: float = 2.0
@export var armor: float = 0.0
@export var move_speed: float = 5.0
@export var critical_chance: float = 0.05  # 5%
@export var critical_multiplier: float = 2.0
```

### StatsComponent

```gdscript
# res://scripts/combat/stats_component.gd
class_name StatsComponent
extends Node

signal health_changed(new_health: float, max_health: float)
signal mana_changed(new_mana: float, max_mana: float)
signal stamina_changed(new_stamina: float, max_stamina: float)
signal died()

@export var stats: CombatStats

var current_health: float
var current_mana: float
var current_stamina: float
var stamina_regen_paused: bool = false
var stamina_regen_timer: float = 0.0

func _ready() -> void:
    current_health = stats.max_health
    current_mana = stats.max_mana
    current_stamina = stats.max_stamina

func _process(delta: float) -> void:
    # Mana regeneration (always active)
    if current_mana < stats.max_mana:
        current_mana = min(current_mana + 5.0 * delta, stats.max_mana)
        mana_changed.emit(current_mana, stats.max_mana)
    
    # Stamina regeneration (paused after use)
    if stamina_regen_paused:
        stamina_regen_timer -= delta
        if stamina_regen_timer <= 0.0:
            stamina_regen_paused = false
    else:
        if current_stamina < stats.max_stamina:
            current_stamina = min(current_stamina + 15.0 * delta, stats.max_stamina)
            stamina_changed.emit(current_stamina, stats.max_stamina)

func reduce_health(amount: float) -> void:
    current_health = max(current_health - amount, 0.0)
    health_changed.emit(current_health, stats.max_health)
    if current_health <= 0.0:
        died.emit()

func consume_mana(amount: float) -> bool:
    if current_mana >= amount:
        current_mana -= amount
        mana_changed.emit(current_mana, stats.max_mana)
        return true
    return false

func consume_stamina(amount: float) -> bool:
    if current_stamina >= amount:
        current_stamina -= amount
        stamina_changed.emit(current_stamina, stats.max_stamina)
        stamina_regen_paused = true
        stamina_regen_timer = 1.0
        return true
    return false

func restore_full() -> void:
    current_health = stats.max_health
    current_mana = stats.max_mana
    current_stamina = stats.max_stamina
    health_changed.emit(current_health, stats.max_health)
    mana_changed.emit(current_mana, stats.max_mana)
    stamina_changed.emit(current_stamina, stats.max_stamina)
```

### StateMachine

```gdscript
# res://scripts/combat/state_machine.gd
class_name StateMachine
extends Node

signal state_changed(old_state: String, new_state: String)

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
var state_handlers: Dictionary = {}

func _ready() -> void:
    # Child nodes are state handlers
    for child in get_children():
        if child.has_method("enter") and child.has_method("exit"):
            state_handlers[child.name] = child

func transition_to(new_state: State) -> bool:
    if not can_transition(current_state, new_state):
        return false
    
    var old_state = current_state
    
    # Exit current state
    if state_handlers.has(State.keys()[current_state]):
        state_handlers[State.keys()[current_state]].exit()
    
    current_state = new_state
    
    # Enter new state
    if state_handlers.has(State.keys()[new_state]):
        state_handlers[State.keys[new_state]].enter()
    
    state_changed.emit(State.keys()[old_state], State.keys()[new_state])
    return true

func can_transition(from: State, to: State) -> bool:
    # DEAD state can only transition to IDLE (respawn)
    if from == State.DEAD:
        return to == State.IDLE
    
    # Cannot transition to DEAD from DEAD
    if from == State.DEAD and to == State.DEAD:
        return false
    
    # STUNNED can only be exited when stun duration expires
    if from == State.STUNNED:
        return to == State.IDLE or to == State.DEAD
    
    # ATTACKING, DODGING, CASTING must complete before transitioning
    # (handled by animation completion callbacks)
    
    return true

func is_in_state(state: State) -> bool:
    return current_state == state

func can_move() -> bool:
    return current_state in [State.IDLE, State.MOVING]

func can_attack() -> bool:
    return current_state in [State.IDLE, State.MOVING]

func can_dodge() -> bool:
    return current_state in [State.IDLE, State.MOVING]

func can_cast() -> bool:
    return current_state in [State.IDLE, State.MOVING]
```

### CombatComponent

```gdscript
# res://scripts/combat/combat_component.gd
class_name CombatComponent
extends Node

signal damage_taken(amount: float, source: Node)
signal damage_dealt(amount: float, target: Node)

@export var stats_component: StatsComponent
@export var state_machine: StateMachine
@export var ability_controller: AbilityController
@export var hitbox: Area3D
@export var hurtbox: Area3D
@export var animation_player: AnimationPlayer

var invulnerable: bool = false
var attack_cooldown: float = 0.0

func _ready() -> void:
    # Connect signals
    stats_component.died.connect(_on_died)
    hurtbox.area_entered.connect(_on_hurtbox_area_entered)
    
    # Disable hitbox by default
    hitbox.monitoring = false

func _process(delta: float) -> void:
    # Update cooldowns
    if attack_cooldown > 0.0:
        attack_cooldown -= delta

func attack() -> void:
    if not state_machine.can_attack():
        return
    
    if attack_cooldown > 0.0:
        return
    
    state_machine.transition_to(StateMachine.State.ATTACKING)
    ability_controller.activate_ability("melee_attack")
    attack_cooldown = 1.0 / stats_component.stats.attack_speed

func dodge(direction: Vector3) -> bool:
    if not state_machine.can_dodge():
        return false
    
    if not stats_component.consume_stamina(20.0):
        return false
    
    state_machine.transition_to(StateMachine.State.DODGING)
    
    # Grant i-frames
    invulnerable = true
    get_tree().create_timer(0.3).timeout.connect(func(): invulnerable = false)
    
    # Perform dodge movement
    var parent = get_parent() as CharacterBody3D
    if parent:
        var dodge_distance = 4.0
        parent.velocity = direction.normalized() * dodge_distance / 0.3
    
    # Play animation
    if animation_player:
        animation_player.play("dodge")
        animation_player.animation_finished.connect(_on_dodge_finished, CONNECT_ONE_SHOT)
    
    return true

func take_damage(amount: float, source: Node = null) -> void:
    if invulnerable:
        return
    
    if state_machine.is_in_state(StateMachine.State.DEAD):
        return
    
    # Calculate final damage
    var final_damage = calculate_damage(amount, source)
    
    # Apply damage
    stats_component.reduce_health(final_damage)
    damage_taken.emit(final_damage, source)
    
    # Trigger feedback
    _trigger_hit_feedback(final_damage, source)

func calculate_damage(base_damage: float, source: Node) -> float:
    var final_damage = base_damage - stats_component.stats.armor
    final_damage = max(final_damage, 1.0)  # Minimum 1 damage
    
    # Check for critical hit
    if source and source.has_method("get_stats"):
        var attacker_stats = source.get_stats()
        if randf() < attacker_stats.critical_chance:
            final_damage *= attacker_stats.critical_multiplier
    
    return final_damage

func _on_hurtbox_area_entered(area: Area3D) -> void:
    # Check if this is a hitbox
    if area.has_method("get_damage"):
        var damage = area.get_damage()
        var source = area.get_parent()
        take_damage(damage, source)

func _on_died() -> void:
    state_machine.transition_to(StateMachine.State.DEAD)
    if animation_player:
        animation_player.play("death")
    
    # Persist corpse for 5 seconds
    get_tree().create_timer(5.0).timeout.connect(_remove_corpse)

func _remove_corpse() -> void:
    get_parent().queue_free()

func _on_dodge_finished(_anim_name: String) -> void:
    state_machine.transition_to(StateMachine.State.IDLE)

func _trigger_hit_feedback(damage: float, source: Node) -> void:
    # Visual feedback: flash red
    # Audio feedback: play hit sound
    # Camera shake (if player)
    # Knockback
    pass  # Implementation details in feedback system
```

### AbilityController

```gdscript
# res://scripts/combat/ability_controller.gd
class_name AbilityController
extends Node

signal ability_cast(ability_name: String)
signal ability_cooldown_started(ability_name: String, duration: float)
signal ability_cooldown_finished(ability_name: String)

var abilities: Dictionary = {}
var cooldowns: Dictionary = {}

func _ready() -> void:
    # Register abilities from children
    for child in get_children():
        if child is Ability:
            abilities[child.ability_name] = child

func _process(delta: float) -> void:
    # Update cooldowns
    for ability_name in cooldowns.keys():
        cooldowns[ability_name] -= delta
        if cooldowns[ability_name] <= 0.0:
            cooldowns.erase(ability_name)
            ability_cooldown_finished.emit(ability_name)

func activate_ability(ability_name: String) -> bool:
    if not abilities.has(ability_name):
        return false
    
    var ability: Ability = abilities[ability_name]
    
    # Check cooldown
    if cooldowns.has(ability_name):
        return false
    
    # Check resource cost
    var stats_component = get_parent().get_node("StatsComponent") as StatsComponent
    if ability.mana_cost > 0 and not stats_component.consume_mana(ability.mana_cost):
        return false
    
    if ability.stamina_cost > 0 and not stats_component.consume_stamina(ability.stamina_cost):
        return false
    
    # Activate ability
    ability.activate()
    ability_cast.emit(ability_name)
    
    # Start cooldown
    cooldowns[ability_name] = ability.cooldown
    ability_cooldown_started.emit(ability_name, ability.cooldown)
    
    return true

func is_on_cooldown(ability_name: String) -> bool:
    return cooldowns.has(ability_name)

func get_cooldown_remaining(ability_name: String) -> float:
    if cooldowns.has(ability_name):
        return cooldowns[ability_name]
    return 0.0
```

### Ability Base Class

```gdscript
# res://scripts/combat/ability.gd
class_name Ability
extends Node

@export var ability_name: String = "ability"
@export var cooldown: float = 1.0
@export var mana_cost: float = 0.0
@export var stamina_cost: float = 0.0
@export var cast_time: float = 0.0

func activate() -> void:
    # Override in subclasses
    pass

func can_activate() -> bool:
    # Override in subclasses for additional checks
    return true
```

### MeleeAttack Ability

```gdscript
# res://scripts/combat/abilities/melee_attack.gd
class_name MeleeAttack
extends Ability

@export var damage: float = 10.0
@export var attack_range: float = 2.0
@export var attack_arc: float = 90.0  # degrees

func _ready() -> void:
    ability_name = "melee_attack"
    cooldown = 0.5

func activate() -> void:
    var combat_component = get_parent().get_parent() as CombatComponent
    var animation_player = combat_component.animation_player
    
    if animation_player:
        animation_player.play("attack")
        # Enable hitbox during attack frames
        animation_player.animation_started.connect(_on_attack_started, CONNECT_ONE_SHOT)
        animation_player.animation_finished.connect(_on_attack_finished, CONNECT_ONE_SHOT)

func _on_attack_started(_anim_name: String) -> void:
    var combat_component = get_parent().get_parent() as CombatComponent
    combat_component.hitbox.monitoring = true

func _on_attack_finished(_anim_name: String) -> void:
    var combat_component = get_parent().get_parent() as CombatComponent
    combat_component.hitbox.monitoring = false
    combat_component.state_machine.transition_to(StateMachine.State.IDLE)
```

### Fireball Ability

```gdscript
# res://scripts/combat/abilities/fireball.gd
class_name Fireball
extends Ability

@export var damage: float = 25.0
@export var projectile_speed: float = 15.0
@export var max_range: float = 20.0
@export var projectile_scene: PackedScene

func _ready() -> void:
    ability_name = "fireball"
    cooldown = 3.0
    mana_cost = 20.0
    cast_time = 0.4

func activate() -> void:
    var combat_component = get_parent().get_parent() as CombatComponent
    var animation_player = combat_component.animation_player
    
    if animation_player:
        animation_player.play("cast")
        # Spawn projectile after cast time
        get_tree().create_timer(cast_time).timeout.connect(_spawn_projectile)

func _spawn_projectile() -> void:
    if not projectile_scene:
        return
    
    var combat_component = get_parent().get_parent() as CombatComponent
    var caster = combat_component.get_parent() as Node3D
    
    var projectile = projectile_scene.instantiate() as Projectile
    get_tree().root.add_child(projectile)
    
    projectile.global_position = caster.global_position + Vector3(0, 1, 0)
    projectile.direction = -caster.global_transform.basis.z
    projectile.damage = damage
    projectile.speed = projectile_speed
    projectile.max_distance = max_range
    projectile.owner_layer = caster.collision_layer
```

### Projectile

```gdscript
# res://scripts/combat/projectile.gd
class_name Projectile
extends Area3D

var direction: Vector3 = Vector3.FORWARD
var speed: float = 15.0
var damage: float = 25.0
var max_distance: float = 20.0
var distance_traveled: float = 0.0
var owner_layer: int = 0

func _ready() -> void:
    area_entered.connect(_on_area_entered)
    body_entered.connect(_on_body_entered)

func _process(delta: float) -> void:
    var movement = direction * speed * delta
    global_position += movement
    distance_traveled += movement.length()
    
    if distance_traveled >= max_distance:
        _explode()

func _on_area_entered(area: Area3D) -> void:
    # Hit a hurtbox
    if area.has_method("take_damage"):
        area.take_damage(damage, self)
        _explode()

func _on_body_entered(_body: Node3D) -> void:
    # Hit a wall or obstacle
    _explode()

func _explode() -> void:
    # Play explosion effect
    # Play explosion sound
    queue_free()
```

### Enemy AI

```gdscript
# res://scripts/combat/enemy_ai.gd
class_name EnemyAI
extends Node

enum AIState {
    IDLE,
    PATROL,
    CHASE,
    ATTACK,
    RETURN
}

@export var detection_radius: float = 10.0
@export var attack_range: float = 2.0
@export var patrol_radius: float = 5.0
@export var attack_cooldown: float = 1.5
@export var attack_windup: float = 0.5

var current_ai_state: AIState = AIState.IDLE
var target: Node3D = null
var spawn_position: Vector3
var attack_timer: float = 0.0
var navigation_agent: NavigationAgent3D
var combat_component: CombatComponent

func _ready() -> void:
    spawn_position = get_parent().global_position
    navigation_agent = get_parent().get_node("NavigationAgent3D")
    combat_component = get_parent().get_node("CombatComponent")

func _process(delta: float) -> void:
    match current_ai_state:
        AIState.IDLE:
            _process_idle(delta)
        AIState.PATROL:
            _process_patrol(delta)
        AIState.CHASE:
            _process_chase(delta)
        AIState.ATTACK:
            _process_attack(delta)
        AIState.RETURN:
            _process_return(delta)

func _process_idle(delta: float) -> void:
    # Look for player
    target = _find_player_in_range(detection_radius)
    if target:
        current_ai_state = AIState.CHASE
    else:
        # Random chance to patrol
        if randf() < 0.01:
            current_ai_state = AIState.PATROL

func _process_patrol(delta: float) -> void:
    # Check for player
    target = _find_player_in_range(detection_radius)
    if target:
        current_ai_state = AIState.CHASE
        return
    
    # Patrol within spawn area
    if not navigation_agent.is_navigation_finished():
        var next_position = navigation_agent.get_next_path_position()
        var parent = get_parent() as CharacterBody3D
        var direction = (next_position - parent.global_position).normalized()
        parent.velocity = direction * combat_component.stats_component.stats.move_speed
        parent.move_and_slide()
    else:
        # Pick new patrol point
        var random_offset = Vector3(
            randf_range(-patrol_radius, patrol_radius),
            0,
            randf_range(-patrol_radius, patrol_radius)
        )
        navigation_agent.target_position = spawn_position + random_offset

func _process_chase(delta: float) -> void:
    if not target or not is_instance_valid(target):
        current_ai_state = AIState.RETURN
        return
    
    var distance_to_target = get_parent().global_position.distance_to(target.global_position)
    
    # Check if player left detection range
    if distance_to_target > detection_radius * 1.5:
        current_ai_state = AIState.RETURN
        target = null
        return
    
    # Check if in attack range
    if distance_to_target <= attack_range:
        current_ai_state = AIState.ATTACK
        return
    
    # Navigate toward player
    navigation_agent.target_position = target.global_position
    var next_position = navigation_agent.get_next_path_position()
    var parent = get_parent() as CharacterBody3D
    var direction = (next_position - parent.global_position).normalized()
    parent.velocity = direction * combat_component.stats_component.stats.move_speed
    parent.move_and_slide()

func _process_attack(delta: float) -> void:
    if not target or not is_instance_valid(target):
        current_ai_state = AIState.RETURN
        return
    
    var distance_to_target = get_parent().global_position.distance_to(target.global_position)
    
    # Check if player moved out of attack range
    if distance_to_target > attack_range:
        current_ai_state = AIState.CHASE
        return
    
    # Face the player
    var parent = get_parent() as Node3D
    var direction_to_target = (target.global_position - parent.global_position).normalized()
    parent.look_at(target.global_position, Vector3.UP)
    
    # Attack on cooldown
    attack_timer -= delta
    if attack_timer <= 0.0:
        _perform_attack()
        attack_timer = attack_cooldown

func _process_return(delta: float) -> void:
    # Return to spawn position
    navigation_agent.target_position = spawn_position
    
    if navigation_agent.is_navigation_finished():
        current_ai_state = AIState.IDLE
        return
    
    var next_position = navigation_agent.get_next_path_position()
    var parent = get_parent() as CharacterBody3D
    var direction = (next_position - parent.global_position).normalized()
    parent.velocity = direction * combat_component.stats_component.stats.move_speed
    parent.move_and_slide()

func _find_player_in_range(radius: float) -> Node3D:
    # Find player within detection radius
    var player = get_tree().get_first_node_in_group("player")
    if player and get_parent().global_position.distance_to(player.global_position) <= radius:
        return player
    return null

func _perform_attack() -> void:
    # Play windup animation
    var animation_player = combat_component.animation_player
    if animation_player:
        animation_player.play("attack_windup")
    
    # Trigger actual attack after windup
    get_tree().create_timer(attack_windup).timeout.connect(func():
        combat_component.attack()
    )
```

## Data Models

### Backend Data Storage

The combat system requires persistent storage for configuration data that needs to be shared across game clients and managed centrally. This includes:

- **Enemy type definitions**: Stats, AI behavior parameters, loot table references
- **Loot tables**: Drop probabilities and item configurations
- **Combat stats templates**: Reusable stat configurations for different entity types
- **Ability definitions**: Ability parameters, costs, and effects

**Storage Architecture**:
- **DynamoDB tables** for persistent storage (managed via AWS CDK)
- **Python backend API** for CRUD operations on combat data
- **Godot client** fetches configuration data at runtime via HTTP API
- **Local caching** in Godot for offline play and performance

**Schema Generator Integration**:

The project uses `orb-schema-generator` to generate code from YAML schema definitions:

1. **Schema definitions** in `schemas/models/` define data structures
2. **Generator creates**:
   - Python Pydantic models in `apps/api/models/`
   - CDK constructs in `infrastructure/cdk/resources/`
   - TypeScript interfaces in `apps/web/src/models/` (future web UI)
3. **Configuration** in `schema-generator.yml` at project root

**Required Schemas**:

- `schemas/models/combat_stats.yaml` - CombatStats data model
- `schemas/models/enemy_type.yaml` - Enemy type configuration
- `schemas/models/loot_table.yaml` - Loot drop definitions
- `schemas/models/ability.yaml` - Ability definitions
- `schemas/tables/combat_stats_table.yaml` - DynamoDB table for combat stats
- `schemas/tables/enemy_types_table.yaml` - DynamoDB table for enemy types
- `schemas/tables/loot_tables_table.yaml` - DynamoDB table for loot tables
- `schemas/tables/abilities_table.yaml` - DynamoDB table for abilities

**Data Flow**:

```
Game Start → Godot Client
  ↓
Fetch enemy types from API → Python Backend
  ↓
Query DynamoDB → Enemy Types Table
  ↓
Return JSON → Godot Client
  ↓
Cache locally → Create Godot Resources
  ↓
Spawn enemies with fetched stats
```

### CombatStats Resource

Defined above in Components section. This resource is saved as `.tres` files for local development and can be configured per-entity type. In production, combat stats are fetched from the backend API and converted to Godot resources at runtime.

Example configurations:

**Player Stats** (`res://data/combat_stats/player_stats.tres`):
```
max_health: 100.0
max_mana: 100.0
max_stamina: 100.0
attack_damage: 15.0
attack_speed: 1.5
attack_range: 2.0
armor: 5.0
move_speed: 6.0
critical_chance: 0.1
critical_multiplier: 2.0
```

**Goblin Stats** (`res://data/combat_stats/goblin_stats.tres`):
```
max_health: 50.0
max_mana: 0.0
max_stamina: 0.0
attack_damage: 8.0
attack_speed: 1.0
attack_range: 1.5
armor: 2.0
move_speed: 4.0
critical_chance: 0.05
critical_multiplier: 1.5
```

### Loot Table

```gdscript
# res://scripts/loot/loot_table.gd
class_name LootTable
extends Resource

@export var drops: Array[LootDrop] = []

func roll() -> Array[LootDrop]:
    var results: Array[LootDrop] = []
    for drop in drops:
        if randf() < drop.chance:
            results.append(drop)
    return results
```

```gdscript
# res://scripts/loot/loot_drop.gd
class_name LootDrop
extends Resource

@export var item_id: String
@export var chance: float = 1.0
@export var min_quantity: int = 1
@export var max_quantity: int = 1

func get_quantity() -> int:
    return randi_range(min_quantity, max_quantity)
```

### Damage Event

```gdscript
# res://scripts/combat/damage_event.gd
class_name DamageEvent
extends RefCounted

var amount: float
var source: Node
var target: Node
var is_critical: bool
var damage_type: String  # "physical", "magical", etc.

func _init(p_amount: float, p_source: Node, p_target: Node, p_is_critical: bool = false, p_damage_type: String = "physical"):
    amount = p_amount
    source = p_source
    target = p_target
    is_critical = p_is_critical
    damage_type = p_damage_type
```

## Correctness Properties

*A property is a characteristic or behavior that should hold true across all valid executions of a system—essentially, a formal statement about what the system should do. Properties serve as the bridge between human-readable specifications and machine-verifiable correctness guarantees.*


### Property 1: Attack Cooldown Enforcement

*For any* combatant, when an attack is triggered, no additional attacks should be possible until the cooldown period expires.

**Validates: Requirements 1.2**

### Property 2: Damage Detection in Attack Cone

*For any* enemy position and player facing direction, the enemy should be detected by the attack if and only if it is within the 2-meter cone in front of the player.

**Validates: Requirements 1.3**

### Property 3: Damage Dealing to Detected Enemies

*For any* enemy detected within the attack cone during an attack, that enemy should receive damage.

**Validates: Requirements 1.4**

### Property 4: Attack Prevention During Attack State

*For any* combatant in ATTACKING state, attack inputs should be rejected.

**Validates: Requirements 1.9**

### Property 5: Health Bounds Invariant

*For any* combatant at any time, current_health should be greater than or equal to 0 and less than or equal to max_health.

**Validates: Requirements 2.3, 2.4**

### Property 6: Damage Application

*For any* combatant and damage amount, calling take_damage should reduce current_health by the calculated final damage amount (accounting for armor and critical hits).

**Validates: Requirements 2.2**

### Property 7: Death Trigger on Zero Health

*For any* combatant, when current_health reaches 0, the combatant should transition to DEAD state.

**Validates: Requirements 2.8**

### Property 8: Enemy Detection Radius

*For any* enemy and player position, the enemy should transition to CHASE state if and only if the player is within the detection radius.

**Validates: Requirements 3.3**

### Property 9: Enemy Attack Range Transition

*For any* enemy in CHASE state, the enemy should transition to ATTACK state if and only if the player is within attack range.

**Validates: Requirements 3.5**

### Property 10: Enemy Return to Idle

*For any* enemy in CHASE or ATTACK state, the enemy should transition back to IDLE state when the player moves beyond detection_radius * 1.5.

**Validates: Requirements 3.8**

### Property 11: Dodge I-Frames

*For any* player performing a dodge roll, the player should be invulnerable to damage for 0.3 seconds after the dodge is triggered.

**Validates: Requirements 4.3**

### Property 12: Dodge Distance

*For any* dodge roll, the player should move exactly 4 meters in the dodge direction.

**Validates: Requirements 4.4**

### Property 13: Dodge Stamina Consumption

*For any* dodge roll, the player's current_stamina should decrease by exactly 20.

**Validates: Requirements 4.8**

### Property 14: Dodge Prevention During Dodge State

*For any* player in DODGING state, attack inputs should be rejected.

**Validates: Requirements 4.7**

### Property 15: Resource Regeneration

*For any* resource (mana or stamina) below its maximum, the resource should regenerate at its specified rate per second when regeneration is active.

**Validates: Requirements 5.4, 7.3**

### Property 16: Stamina Regeneration Pause

*For any* stamina consumption event, stamina regeneration should be paused for exactly 1 second.

**Validates: Requirements 5.5**

### Property 17: Resource Validation for Actions

*For any* action requiring a resource cost, the action should be prevented if current resource is less than the cost.

**Validates: Requirements 5.7, 7.5**

### Property 18: Fireball Projectile Creation

*For any* fireball cast, a projectile should be created moving at 15 meters per second toward the cursor position.

**Validates: Requirements 6.2**

### Property 19: Projectile Damage on Hit

*For any* projectile hitting an enemy, the enemy should receive the projectile's damage amount.

**Validates: Requirements 6.3**

### Property 20: Ability Cooldown

*For any* ability activation, the ability should not be usable again until the cooldown period expires.

**Validates: Requirements 6.4**

### Property 21: Ability Resource Consumption

*For any* ability with a resource cost, activating the ability should reduce the appropriate resource (mana or stamina) by the cost amount.

**Validates: Requirements 6.5**

### Property 22: Projectile Lifetime

*For any* projectile, the projectile should be destroyed when it hits an enemy, hits a wall, or travels 20 meters.

**Validates: Requirements 6.9**

### Property 23: Knockback Application

*For any* enemy hit by an attack, the enemy should be displaced 0.5 meters away from the attacker.

**Validates: Requirements 8.3**

### Property 24: Respawn Resource Restoration

*For any* player respawn, current_health and current_mana should be restored to their maximum values.

**Validates: Requirements 9.4**

### Property 25: Enemy Reset on Respawn

*For any* player respawn, all enemies in the current room should be reset to their initial state (position, health, AI state).

**Validates: Requirements 9.5**

### Property 26: Loot Drop Generation

*For any* enemy death, items should be generated according to the enemy's loot table probabilities.

**Validates: Requirements 10.2**

### Property 27: Item Pickup on Proximity

*For any* dropped item, when the player enters the 2-meter pickup radius, the item should be automatically picked up.

**Validates: Requirements 10.5**

### Property 28: Gold Accumulation

*For any* gold pickup, the player's total gold should increase by the gold amount.

**Validates: Requirements 10.7**

### Property 29: Combat Stats Serialization Round-Trip

*For any* valid CombatStats resource, saving to disk then loading should produce an equivalent resource with all properties preserved.

**Validates: Requirements 11.3**

### Property 30: Damage Calculation Formula

*For any* attack with base damage, ability multiplier, and target armor, final_damage should equal max(1, (base_damage * ability_multiplier) - armor).

**Validates: Requirements 12.1, 12.2**

### Property 31: Critical Hit Damage Multiplier

*For any* attack that is a critical hit, final_damage should be multiplied by the attacker's critical_multiplier.

**Validates: Requirements 12.3**

### Property 32: Critical Hit Probability

*For any* large number of attacks with a given critical_chance, the proportion of critical hits should converge to the critical_chance value (statistical property).

**Validates: Requirements 12.4**

### Property 33: Combat Signal Emission

*For any* combat event (damage taken, damage dealt, health changed, mana changed, stamina changed, death, ability cast, cooldown started, cooldown finished), the appropriate signal should be emitted with correct parameters.

**Validates: Requirements 13.1, 13.2, 13.3, 13.4, 13.5, 13.6, 13.7, 13.8, 13.9**

### Property 34: State Machine Action Permissions

*For any* combatant state, only the actions permitted by that state should be executable (IDLE/MOVING allow all actions, ATTACKING/DODGING/CASTING/STUNNED restrict actions, DEAD prevents all actions).

**Validates: Requirements 14.2, 14.3, 14.4, 14.5, 14.6, 14.7, 14.8**

### Property 35: Hitbox Collision Layer Isolation

*For any* hitbox, it should only collide with hurtboxes on the appropriate opposing layer (player hitboxes with enemy hurtboxes, enemy hitboxes with player hurtboxes).

**Validates: Requirements 15.8**

## Error Handling

### Combat Errors

**Invalid State Transitions**:
- Attempting to transition to an invalid state should be rejected silently
- State machine should log warnings for debugging but not crash
- Current state should be maintained if transition is invalid

**Resource Underflow**:
- Attempting to consume more resources than available should fail gracefully
- Action should be prevented, not partially executed
- UI should provide feedback about insufficient resources

**Null References**:
- All combat components should validate references in _ready()
- Missing required components should log errors and disable combat functionality
- Graceful degradation: missing optional components (animations, effects) should not crash

**Damage Calculation Edge Cases**:
- Negative damage should be clamped to 0
- Damage exceeding max_health should be clamped to current_health
- Division by zero in calculations should be prevented with guards

### AI Errors

**Navigation Failures**:
- If NavigationAgent3D fails to find path, enemy should return to IDLE state
- Pathfinding errors should be logged but not crash the game
- Enemy should retry pathfinding after a delay

**Target Loss**:
- If target becomes invalid (null, freed, out of scene), enemy should transition to RETURN state
- Enemy should not crash when target reference is lost
- Graceful handling of player death during chase

**Spawn Area Validation**:
- Patrol points should be validated to be within navigation mesh
- Invalid patrol points should be rejected and new ones generated
- Enemy should not get stuck outside walkable areas

### Ability Errors

**Missing Projectile Scene**:
- If projectile scene is not assigned, ability should fail gracefully
- Error should be logged with clear message
- Cooldown and resource cost should not be consumed if ability fails

**Animation Missing**:
- If animation is not found, ability should still execute core logic
- Visual feedback should be skipped, not crash
- Log warning about missing animation

**Cooldown Desync**:
- If cooldown timer becomes negative, clamp to 0
- If cooldown dictionary grows unbounded, implement cleanup
- Prevent memory leaks from abandoned cooldowns

## Testing Strategy

### Dual Testing Approach

The combat system requires both unit tests and property-based tests for comprehensive coverage:

**Unit Tests**:
- Specific examples demonstrating correct behavior
- Edge cases (zero health, zero stamina, maximum values)
- Error conditions (invalid states, null references, missing components)
- Integration points between components
- Animation callbacks and timing-sensitive logic

**Property-Based Tests**:
- Universal properties across all inputs (see Correctness Properties section)
- Randomized combat scenarios with many iterations
- Statistical properties (critical hit rates, loot drop probabilities)
- Invariants that must hold at all times (health bounds, resource bounds)

### Testing Framework

**GUT (Godot Unit Test)**:
- Use GUT 9.2.1+ for Godot 4 compatibility
- Organize tests in `tests/unit/` and `tests/property/` directories
- Run tests with: `godot --headless --script addons/gut/gut_cmdln.gd`

**Property Test Configuration**:
- Minimum 100 iterations per property test
- Use GUT's parameterized test support for property tests
- Tag each property test with: `# Feature: combat-system, Property N: [property name]`

### Test Organization

```
tests/
├── unit/
│   ├── test_combat_stats.gd
│   ├── test_stats_component.gd
│   ├── test_state_machine.gd
│   ├── test_combat_component.gd
│   ├── test_ability_controller.gd
│   ├── test_melee_attack.gd
│   ├── test_fireball.gd
│   ├── test_projectile.gd
│   ├── test_enemy_ai.gd
│   ├── test_loot_table.gd
│   └── test_damage_calculation.gd
├── property/
│   ├── test_health_invariants.gd
│   ├── test_resource_management.gd
│   ├── test_damage_properties.gd
│   ├── test_ability_properties.gd
│   ├── test_state_machine_properties.gd
│   └── test_ai_properties.gd
└── integration/
    ├── test_player_combat.gd
    ├── test_enemy_combat.gd
    └── test_combat_scenarios.gd
```

### Unit Test Examples

**Example: Testing Damage Calculation**
```gdscript
# tests/unit/test_damage_calculation.gd
extends GutTest

func test_damage_calculation_basic():
    var stats = CombatStats.new()
    stats.armor = 5.0
    
    var combat = CombatComponent.new()
    var final_damage = combat.calculate_damage(20.0, null)
    
    assert_eq(final_damage, 15.0, "Should subtract armor from damage")

func test_damage_calculation_minimum():
    var stats = CombatStats.new()
    stats.armor = 100.0
    
    var combat = CombatComponent.new()
    var final_damage = combat.calculate_damage(10.0, null)
    
    assert_eq(final_damage, 1.0, "Should enforce minimum 1 damage")

func test_critical_hit_multiplier():
    var attacker_stats = CombatStats.new()
    attacker_stats.critical_multiplier = 2.0
    
    var combat = CombatComponent.new()
    # Simulate critical hit
    var base_damage = 20.0
    var final_damage = base_damage * attacker_stats.critical_multiplier
    
    assert_eq(final_damage, 40.0, "Should double damage on critical")
```

### Property Test Examples

**Example: Health Bounds Invariant**
```gdscript
# tests/property/test_health_invariants.gd
# Feature: combat-system, Property 5: Health Bounds Invariant
extends GutTest

func test_health_never_exceeds_bounds():
    # Run 100 iterations with random values
    for i in range(100):
        var stats = CombatStats.new()
        stats.max_health = randf_range(50.0, 200.0)
        
        var stats_component = StatsComponent.new()
        stats_component.stats = stats
        stats_component._ready()
        
        # Apply random damage
        var damage = randf_range(0.0, stats.max_health * 2.0)
        stats_component.reduce_health(damage)
        
        # Verify invariant
        assert_true(stats_component.current_health >= 0.0, 
                    "Health should never be negative")
        assert_true(stats_component.current_health <= stats.max_health, 
                    "Health should never exceed maximum")
```

**Example: Resource Regeneration**
```gdscript
# tests/property/test_resource_management.gd
# Feature: combat-system, Property 15: Resource Regeneration
extends GutTest

func test_mana_regeneration_rate():
    # Run 100 iterations with random starting mana
    for i in range(100):
        var stats = CombatStats.new()
        stats.max_mana = 100.0
        
        var stats_component = StatsComponent.new()
        stats_component.stats = stats
        stats_component._ready()
        
        # Set random starting mana
        stats_component.current_mana = randf_range(0.0, 50.0)
        var initial_mana = stats_component.current_mana
        
        # Simulate 1 second of regeneration
        var delta = 0.016  # 60 FPS
        var frames = 60
        for frame in range(frames):
            stats_component._process(delta)
        
        # Verify regeneration (5 mana per second)
        var expected_mana = min(initial_mana + 5.0, stats.max_mana)
        assert_almost_eq(stats_component.current_mana, expected_mana, 0.1,
                        "Mana should regenerate at 5 per second")
```

### Integration Test Strategy

**Combat Scenarios**:
- Player attacks enemy until death
- Enemy chases and attacks player
- Player dodges enemy attack with i-frames
- Player casts fireball and hits multiple enemies
- Player dies and respawns
- Enemy drops loot and player picks it up

**Performance Tests**:
- Multiple enemies (10+) attacking simultaneously
- Many projectiles (20+) in flight
- Rapid ability usage with cooldowns
- State machine transitions under load

### Test Coverage Goals

- **Unit Tests**: 80%+ coverage of core combat logic
- **Property Tests**: All 35 correctness properties implemented
- **Integration Tests**: All major combat scenarios covered
- **Edge Cases**: All error conditions tested

### Continuous Testing

- Run unit tests before every commit (enforced by pre-commit hook)
- Run property tests nightly (100+ iterations each)
- Run integration tests before merging to main
- Monitor test execution time (target < 30 seconds for unit tests)
