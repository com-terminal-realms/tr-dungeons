## Simple file logger
extends Node

const LOG_FILE = "user://game.log"
var file: FileAccess

func _ready() -> void:
	file = FileAccess.open(LOG_FILE, FileAccess.WRITE)
	if file:
		log("Logger initialized")
		print("Logger: Writing to ", LOG_FILE)
		print("Logger: Full path = ", ProjectSettings.globalize_path(LOG_FILE))

func log(message: String) -> void:
	if file:
		file.store_line(message)
		file.flush()
	print(message)

func _exit_tree() -> void:
	if file:
		file.close()
