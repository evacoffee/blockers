extends Area2D

var player_in_range: bool = false

@export var destination: Marker2D

@onready var promt: Label = $promt

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	promt.visible = false

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		player_in_range = true
		promt.visible = true

func _on_body_exited(body: Node2D) -> void:
	if body.is_in_group("player"):
		player_in_range = false
		promt.visible = false

func _process(_delta: float) -> void:
	if player_in_range and Input.is_action_just_pressed("pothole"):
		var player = get_tree().get_first_node_in_group("player")
		
		if player != null and destination != null:
			AchievementManager.unlock_achievement( "down below", "use a pothole for the first time")
			player.global_position = destination.global_position
