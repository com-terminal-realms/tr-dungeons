extends Control
class_name AbilityCooldownUI

## UI for displaying ability cooldowns
## Shows ability icons with cooldown overlays and resource indicators

@export var ability_controller: AbilityController
@export var stats_component: StatsComponent

@onready var ability_container: HBoxContainer = $HBoxContainer

var ability_displays: Dictionary = {}  # ability_name -> AbilityDisplay

func _ready() -> void:
	# Auto-find components if not set
	if not ability_controller:
		ability_controller = _find_ability_controller()
	if not stats_component:
		stats_component = _find_stats_component()
	
	# Connect to ability controller signals
	if ability_controller:
		ability_controller.ability_cooldown_started.connect(_on_ability_cooldown_started)
		ability_controller.ability_cooldown_finished.connect(_on_ability_cooldown_finished)
		
		# Create displays for all abilities
		for ability_name in ability_controller.abilities:
			_create_ability_display(ability_name)

func _process(_delta: float) -> void:
	# Update cooldown displays
	for ability_name in ability_displays:
		_update_ability_display(ability_name)

## Create UI display for an ability
func _create_ability_display(ability_name: String) -> void:
	if not ability_controller or not ability_container:
		return
	
	var ability: Ability = ability_controller.get_ability(ability_name)
	if not ability:
		return
	
	# Create panel for ability
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(64, 64)
	
	# Create overlay container
	var overlay := Control.new()
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	panel.add_child(overlay)
	
	# Create icon (placeholder)
	var icon := ColorRect.new()
	icon.color = Color(0.3, 0.3, 0.3)
	icon.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.add_child(icon)
	
	# Create cooldown overlay
	var cooldown_overlay := ColorRect.new()
	cooldown_overlay.color = Color(0.0, 0.0, 0.0, 0.7)
	cooldown_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	cooldown_overlay.visible = false
	overlay.add_child(cooldown_overlay)
	
	# Create cooldown label
	var cooldown_label := Label.new()
	cooldown_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	cooldown_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	cooldown_label.set_anchors_preset(Control.PRESET_FULL_RECT)
	cooldown_label.visible = false
	overlay.add_child(cooldown_label)
	
	# Create resource indicator (red border if insufficient resources)
	var resource_indicator := ColorRect.new()
	resource_indicator.color = Color(1.0, 0.0, 0.0, 0.0)  # Transparent by default
	resource_indicator.set_anchors_preset(Control.PRESET_FULL_RECT)
	resource_indicator.mouse_filter = Control.MOUSE_FILTER_IGNORE
	overlay.add_child(resource_indicator)
	
	# Store references
	ability_displays[ability_name] = {
		"panel": panel,
		"icon": icon,
		"cooldown_overlay": cooldown_overlay,
		"cooldown_label": cooldown_label,
		"resource_indicator": resource_indicator
	}
	
	# Add to container
	ability_container.add_child(panel)

## Update ability display
func _update_ability_display(ability_name: String) -> void:
	if not ability_displays.has(ability_name):
		return
	
	var display: Dictionary = ability_displays[ability_name]
	var ability: Ability = ability_controller.get_ability(ability_name)
	
	if not ability:
		return
	
	# Update cooldown
	var cooldown_remaining := ability.get_cooldown_remaining()
	var is_on_cooldown := cooldown_remaining > 0.0
	
	display.cooldown_overlay.visible = is_on_cooldown
	display.cooldown_label.visible = is_on_cooldown
	
	if is_on_cooldown:
		display.cooldown_label.text = "%.1f" % cooldown_remaining
	
	# Update resource indicator
	var has_resources := _check_ability_resources(ability)
	if has_resources:
		display.resource_indicator.color = Color(1.0, 0.0, 0.0, 0.0)  # Transparent
	else:
		display.resource_indicator.color = Color(1.0, 0.0, 0.0, 0.5)  # Red overlay

## Check if player has sufficient resources for ability
func _check_ability_resources(ability: Ability) -> bool:
	if not stats_component:
		return true
	
	# Check mana
	if ability.mana_cost > 0.0 and not stats_component.has_mana(ability.mana_cost):
		return false
	
	# Check stamina
	if ability.stamina_cost > 0.0 and not stats_component.has_stamina(ability.stamina_cost):
		return false
	
	return true

## Handle ability cooldown started
func _on_ability_cooldown_started(ability_name: String, _duration: float) -> void:
	_update_ability_display(ability_name)

## Handle ability cooldown finished
func _on_ability_cooldown_finished(ability_name: String) -> void:
	_update_ability_display(ability_name)

## Find AbilityController in scene
func _find_ability_controller() -> AbilityController:
	var player := get_tree().get_first_node_in_group("player")
	if not player:
		return null
	
	for child in player.get_children():
		if child is CombatComponent:
			return child.ability_controller
	
	return null

## Find StatsComponent in scene
func _find_stats_component() -> StatsComponent:
	var player := get_tree().get_first_node_in_group("player")
	if not player:
		return null
	
	for child in player.get_children():
		if child is StatsComponent:
			return child
	
	return null
