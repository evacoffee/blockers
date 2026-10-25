extends Area2D

const HEAL_AMOUNT: int = 20

@onready var heartpick: AudioStreamPlayer2D = $heartpick

var collected: bool = false

func _on_body_entered(body: Node2D) -> void:
	if collected:
		return

	if body.is_in_group("player"):
		collected = true
		body.heal(HEAL_AMOUNT)
		heartpick.play()
		
		AchievementManager.unlock_achievement("a little help", "collect your first healing heart")
		
		set_deferred("monitoring", false)

		var tween := create_tween()
		tween.set_parallel(true)
		tween.tween_property(self, "scale", Vector2.ZERO, 0.2)
		tween.tween_property(self, "modulate:a", 0.0, 0.2)

		await tween.finished
		queue_free()
