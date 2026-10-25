extends Area2D

var player_in_range: bool = false
var activated: bool = false

@onready var promt: Label = $promt
@onready var switchsound: AudioStreamPlayer2D = $switchsound

func _ready() -> void:
	promt.visible = false

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player") and not activated:
		player_in_range = true
		promt.visible = true

func _on_body_exited(body: Node2D) -> void:
	if body.is_in_group("player"):
		player_in_range = false
		promt.visible = false

func _process(_delta: float) -> void:
		if player_in_range and not activated:
			if Input.is_action_just_pressed("interact"):
				activate()

func activate() -> void:
	if activated:
		return
		
	activated = true
	
	Input.vibrate_handheld(50, 0.4)
	
	get_tree().current_scene.switch_activated()
	promt.visible = false
	switchsound.play() 
