extends Area2D

var player_in_range: bool = false
var flicker_time: float = 0.0
var normal_energy: float = 1.0
var flicker_enabled: bool = true

@onready var promt: Label = $promt
@onready var refillsound: AudioStreamPlayer2D = $refillsound
@onready var machinelight: PointLight2D = $machinelight

func _ready() -> void:
	promt.visible = false
	normal_energy = machinelight.energy

func _on_body_entered(body: Node2D) -> void:
	if body.name == "player1":
		player_in_range = true
		promt.visible = true

func _on_body_exited(body: Node2D) -> void:
	if body.name == "player1":
		player_in_range = false
		promt.visible = false

func _process(_delta: float) -> void:
	if not player_in_range and flicker_enabled:
		flicker_time -= _delta
		
		if flicker_time <= 0.0:
			flicker_time = randf_range(0.05, 0.3)
			
			if randf() < 0.25:
				machinelight.energy = randf_range(0.1, 0.4)
			else:
				machinelight.energy = randf_range(0.7, normal_energy)
	
	if player_in_range:
		machinelight.energy = normal_energy
		
	if player_in_range and Input.is_action_just_pressed("interact"):
		var player = get_tree().get_first_node_in_group("player")
		if player:
			player.refill_flashlight()
			refillsound.play()
