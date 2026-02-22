extends Control
class_name ResourceBars

## Resource bars UI for stamina and mana
## Displays below health bar with visual indicators

@export var stats_component: StatsComponent

@onready var stamina_bar: ProgressBar = $VBoxContainer/StaminaBar
@onready var mana_bar: ProgressBar = $VBoxContainer/ManaBar
@onready var stamina_label: Label = $VBoxContainer/StaminaLabel
@onready var mana_label: Label = $VBoxContainer/ManaLabel

func _ready() -> void:
	# Auto-find stats component if not set
	if not stats_component:
		stats_component = _find_stats_component()
	
	# Connect to resource changed signals
	if stats_component:
		stats_component.stamina_changed.connect(_on_stamina_changed)
		stats_component.mana_changed.connect(_on_mana_changed)
		
		# Initialize bars
		if stats_component.stats:
			_on_stamina_changed(stats_component.current_stamina, stats_component.stats.max_stamina)
			_on_mana_changed(stats_component.current_mana, stats_component.stats.max_mana)

## Update stamina bar display
func _on_stamina_changed(current: float, maximum: float) -> void:
	if stamina_bar:
		stamina_bar.max_value = maximum
		stamina_bar.value = current
		
		# Flash if depleted
		if current <= 0.0:
			_flash_bar(stamina_bar)
	
	if stamina_label:
		stamina_label.text = "Stamina: %.0f/%.0f" % [current, maximum]

## Update mana bar display
func _on_mana_changed(current: float, maximum: float) -> void:
	if mana_bar:
		mana_bar.max_value = maximum
		mana_bar.value = current
	
	if mana_label:
		mana_label.text = "Mana: %.0f/%.0f" % [current, maximum]

## Flash bar to indicate depletion
func _flash_bar(bar: ProgressBar) -> void:
	var original_modulate := bar.modulate
	bar.modulate = Color(1.0, 0.0, 0.0, 1.0)
	
	get_tree().create_timer(0.2).timeout.connect(func():
		if bar:
			bar.modulate = original_modulate
	)

## Find StatsComponent in scene
func _find_stats_component() -> StatsComponent:
	var player := get_tree().get_first_node_in_group("player")
	if not player:
		return null
	
	for child in player.get_children():
		if child is StatsComponent:
			return child
	
	return null
