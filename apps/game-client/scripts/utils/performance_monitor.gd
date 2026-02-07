## Performance monitoring utility
## Tracks frame time and FPS to ensure 60 FPS target
extends Node

@export var enabled: bool = true
@export var log_interval: float = 5.0  # Log stats every N seconds
@export var target_fps: float = 60.0

var _frame_times: Array[float] = []
var _log_timer: float = 0.0
var _max_frame_time: float = 0.0
var _min_frame_time: float = 999.0

func _ready() -> void:
	if enabled:
		print("PerformanceMonitor: Enabled (target: %.1f FPS, %.2f ms)" % [target_fps, 1000.0 / target_fps])

func _process(delta: float) -> void:
	if not enabled:
		return
	
	# Track frame time
	var frame_time_ms := delta * 1000.0
	_frame_times.append(frame_time_ms)
	_max_frame_time = max(_max_frame_time, frame_time_ms)
	_min_frame_time = min(_min_frame_time, frame_time_ms)
	
	# Log stats at interval
	_log_timer += delta
	if _log_timer >= log_interval:
		_log_performance_stats()
		_log_timer = 0.0
		_frame_times.clear()
		_max_frame_time = 0.0
		_min_frame_time = 999.0

func _log_performance_stats() -> void:
	if _frame_times.is_empty():
		return
	
	# Calculate average frame time
	var total := 0.0
	for ft in _frame_times:
		total += ft
	var avg_frame_time := total / _frame_times.size()
	var avg_fps := 1000.0 / avg_frame_time
	
	# Calculate target frame time
	var target_frame_time := 1000.0 / target_fps
	
	# Log stats
	print("=== Performance Stats (%.1fs) ===" % log_interval)
	print("  Avg FPS: %.1f (%.2f ms)" % [avg_fps, avg_frame_time])
	print("  Min FPS: %.1f (%.2f ms)" % [1000.0 / _max_frame_time, _max_frame_time])
	print("  Max FPS: %.1f (%.2f ms)" % [1000.0 / _min_frame_time, _min_frame_time])
	print("  Target: %.1f FPS (%.2f ms)" % [target_fps, target_frame_time])
	
	# Warn if below target
	if avg_frame_time > target_frame_time:
		push_warning("Performance below target! Avg: %.2f ms, Target: %.2f ms" % [avg_frame_time, target_frame_time])
	
	# Get engine stats
	var static_mem := Performance.get_monitor(Performance.MEMORY_STATIC) / 1024.0 / 1024.0
	var objects := Performance.get_monitor(Performance.OBJECT_COUNT)
	var nodes := Performance.get_monitor(Performance.OBJECT_NODE_COUNT)
	
	print("  Memory: %.1f MB" % static_mem)
	print("  Objects: %d (Nodes: %d)" % [objects, nodes])
	print("================================")

## Get current FPS
func get_current_fps() -> float:
	return Engine.get_frames_per_second()

## Check if performance meets target
func is_performance_acceptable() -> bool:
	if _frame_times.is_empty():
		return true
	
	var total := 0.0
	for ft in _frame_times:
		total += ft
	var avg_frame_time := total / _frame_times.size()
	var target_frame_time := 1000.0 / target_fps
	
	return avg_frame_time <= target_frame_time
