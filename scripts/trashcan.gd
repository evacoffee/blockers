extends Area2D

var has_dropped: bool = false

@onready var spawnpoint: Marker2D = $spawnpoint
@onready var dropsound: AudioStreamPlayer2D = $dropsound

var heart_scene = preload("res://scenes/heartpickup.tscn")

func _on_body_entered(body: Node2D) -> void:
	if has_dropped:
		return
	
	if body.is_in_group("player"):
		has_dropped = true
		call_deferred("drop_heart")

func drop_heart() -> void:
	var heart = heart_scene.instantiate()
	get_parent().add_child(heart)
	heart.global_position = global_position
	dropsound.play()
	
	var tween := create_tween()
	tween.set_trans(Tween.TRANS_BACK)
	tween.set_ease(Tween.EASE_OUT)
	
	tween.tween_property(heart,"global_position",spawnpoint.global_position,0.5)
