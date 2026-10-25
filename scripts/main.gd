extends Node2D

var level: int = 1
var current_level_root: Node = null
var total_switches: int = 0
var activated_switches: int = 0
var daylight_transition_started: bool = false

@onready var darkness: CanvasModulate = $darkness
@onready var level_root: Node2D = $levelroot
@onready var hud = $HUD
@onready var titleclick: AudioStreamPlayer2D = $titleclick
@onready var gamefade: ColorRect = $gamefade


#------------
#stargame
#------------
func _ready() -> void:
	level = playerstats.selected_level
	darkness.visible = true

	_load_level(level)

	gamefade.color.a = 1.0

	await get_tree().create_timer(0.6).timeout
	await turn_on_flashlight()

	var tween := create_tween()
	tween.set_trans(Tween.TRANS_SINE)
	tween.set_ease(Tween.EASE_OUT)
	tween.tween_property(gamefade, "color:a", 0.0, 1.0)
	
	await tween.finished
	
	if level == 15:
		await transition_to_daylight()


#----------
#flashlight
#---------
func turn_on_flashlight() -> void:
	var player = get_tree().get_first_node_in_group("player")

	if not player:
		return

	titleclick.play()

	player.flashlight_start_locked = false
	player.light.energy = 0.0
	player.light.enabled = true

	var light_tween := create_tween()
	light_tween.set_trans(Tween.TRANS_SINE)
	light_tween.set_ease(Tween.EASE_OUT)

	light_tween.tween_property(player.light, "energy", player.flashlight_base_energy, 0.8)

	await light_tween.finished

func transition_to_daylight() -> void:
	if daylight_transition_started:
		return
	
	daylight_transition_started = true
	
	var player = get_tree().get_first_node_in_group("player")
	if not player:
		return
	
	var tween := create_tween()
	tween.set_parallel(true)
	tween.set_trans(Tween.TRANS_SINE)
	tween.set_ease(Tween.EASE_IN_OUT)
	
	tween.tween_property(darkness, "color", Color("ffeacd"), 6.0)
	tween.tween_property(player.light, "energy", 0.0, 6.0)
	
	await tween.finished
	player.light.enabled = false
	player.light.visible = false
	hud.hide_flashlight_hud()
#--------------
#level amage
#-------------
func _load_level(level_number: int) -> void:
	if current_level_root:
		current_level_root.queue_free()

	var level_path = "res://scenes/levels/level_%s.tscn" % level_number

	current_level_root = load(level_path).instantiate()
	level_root.add_child(current_level_root)

	var player = current_level_root.get_node("player1")
	player.light.enabled = false
	total_switches = 0
	activated_switches = 0

	var switches = current_level_root.find_children("powerswitch*", "Area2D", true, false)
	for switch in switches:
		total_switches += 1
		if switch.activated:
			activated_switches += 1
			
	_setup_level(current_level_root)
	if level_number != 15:
		hud.show_flashlight_hud()
		
	hud.update_switch_counter(activated_switches, total_switches)
	hud.show_level_title(level_number)


func _setup_level(_level_root: Node) -> void:
	var player = _level_root.get_node("player1")
	$HUD.set_player(player)
	player.died.connect(_on_player_died)
	
	var camera = player.get_node_or_null("Camera2D")
	if camera:
		camera.enabled = true
		camera.make_current()
		
	var exit = current_level_root.get_node_or_null("exit")
	if exit:
		exit.body_entered.connect(_on_exit_body_entered)


#--------------
#exit
#---------------
func _on_exit_body_entered(body: Node2D) -> void:
	if body.name != "player1":
		return

	# If there are swichs, ALL ARE ATIVATED PATRICIA
	if total_switches > 0 and activated_switches < total_switches:
		return
	level += 1
	
	playerstats.highest_level_unlocked = max(playerstats.highest_level_unlocked, level)
	playerstats.save_level_progress()

	var tween := create_tween()
	tween.set_trans(Tween.TRANS_SINE)
	tween.set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(gamefade, "color:a", 1.0, 0.8)

	await tween.finished
	_load_level(level)
	await get_tree().create_timer(0.3).timeout
	await turn_on_flashlight()

	var reveal_tween := create_tween()
	reveal_tween.set_trans(Tween.TRANS_SINE)
	reveal_tween.set_ease(Tween.EASE_OUT)
	reveal_tween.tween_property(gamefade, "color:a", 0.0, 1.0)


#---------------
#death
#--------------
func _on_player_died() -> void:
	await get_tree().create_timer(1.0).timeout
	await hud.fade(1.0)
	
	level = 1
	playerstats.reset()
	playerstats.selected_level = 1
	
	_load_level(level)
	
	await get_tree().create_timer(0.3).timeout
	await turn_on_flashlight()
	
	await hud.fade(0.0)


#------------
# power switch
#--------------
func switch_activated() -> void:
	activated_switches += 1
	hud.update_switch_counter(activated_switches, total_switches)
	
	if activated_switches == total_switches and total_switches > 0:
		hud.show_power_restored()
		AchievementManager.unlock_achievement("power restored", "activate every power switch in a level")
