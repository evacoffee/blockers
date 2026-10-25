extends Node

signal achievement_unlocked(title: String, description: String)

const SAVE_PATH := "user://achievements.cfg"

var regular_drone_kills: int = 0
var electric_drone_kills: int = 0
var unlocked_achievements: Array[String] = []


func _ready() -> void:
	load_achievements()

func register_regular_drone_kill() -> void:
	regular_drone_kills += 1
	save_achievements()
	
	if regular_drone_kills >= 10:
		unlock_achievement("drone hunter", "defeat 10 regular drones")
		
	if regular_drone_kills >= 25:
		unlock_achievement("drone hunter II", "defeat 25 regular drones")

func register_electric_drone_kill() -> void:
	electric_drone_kills += 1
	save_achievements()
	
	if electric_drone_kills >= 5:
		unlock_achievement("shock tactics", "defeat 5 electric drones")
		
	if electric_drone_kills >= 15:
		unlock_achievement("shock tactics II", "defeat 15 electric drones")

func unlock_achievement(title: String, description: String) -> void:
	if unlocked_achievements.has(title):
		return
		
	unlocked_achievements.append(title)
	save_achievements()
	achievement_unlocked.emit(title, description)


func save_achievements() -> void:
	var config := ConfigFile.new()
	
	config.set_value("progress", "regular_drone_kills", regular_drone_kills)
	config.set_value("progress", "electric_drone_kills", electric_drone_kills)
	config.set_value("progress", "unlocked", unlocked_achievements)
	
	config.save(SAVE_PATH)


func load_achievements() -> void:
	var config := ConfigFile.new()
	
	var error := config.load(SAVE_PATH)
	if error != OK:
		return
		
	regular_drone_kills = config.get_value("progress", "regular_drone_kills", 0)
	electric_drone_kills = config.get_value("progress", "electric_drone_kills", 0)
	
	var saved_unlocked = config.get_value("progress", "unlocked", [])
	
	unlocked_achievements.clear()
	
	for achievement in saved_unlocked:
		unlocked_achievements.append(str(achievement))

func get_all_achievements() -> Array[Dictionary]:
	return [
		{"title": "drone hunter", "description": "defeat 1 regular drone"},
		{"title": "shock tactics", "description": "defeat 5 electric drones"},
		{"title": "power restored", "description": "activate every power switch in a level"},
		{"title": "a little help", "description": "collect your first healing heart"},
		{"title": "down below", "description": "use a pothole for the first time"},
		{"title": "drone hunter II", "description": "defeat 25 regular drones"},
		{"title": "shock tactics II", "description": "defeat 15 electric drones"},
		{"title": "the end of the road", "description": "complete the final level"}
	]
