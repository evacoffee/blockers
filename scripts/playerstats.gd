extends Node

var health: int = 100
var max_health: int = 100
var flashlight: float = 100.0
var selected_level: int = 1
var highest_level_unlocked: int = 1
var return_level: int = 1

const LEVEL_SAVE_PATH := "user://level_progress.cfg"

func _ready() -> void:
		load_level_progress()

func reset() -> void:
	health = max_health
	flashlight = 100.0

func save_level_progress() -> void:
	var config := ConfigFile.new()
	config.set_value("progress", "highest_level_unlocked", highest_level_unlocked)
	var error := config.save(LEVEL_SAVE_PATH)
	if error != OK:
		print("failed to save level progress")

func load_level_progress() -> void:
	var config := ConfigFile.new()
	var error := config.load(LEVEL_SAVE_PATH)
	if error != OK:
		return
	highest_level_unlocked = config.get_value("progress", "highest_level_unlocked", 1)
