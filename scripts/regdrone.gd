extends CharacterBody2D

const SPEED: float = 100.0
const KNOCKBACK_FORCE: float = 100.0
const HEART_DROP_CHANCE: float = 0.75

var target = null
var health: int = 100
var strength: int = 5
var is_alive = true
var target_in_range: bool = false
var original_sprite_color: Color
var heart_scene = preload("res://scenes/heartpickup.tscn")
var last_player_position: Vector2

@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D
@onready var take_damage_sound: AudioStreamPlayer2D = $takedamage
@onready var health_bar: Node2D = $heathbar
@onready var attacktimer: Timer = $attacktimer

func _ready() -> void:
	original_sprite_color = animated_sprite_2d.modulate

func _physics_process(delta: float) -> void:
	if is_alive and target:
		_attack(delta)

func _attack(delta: float) -> void:
	var direction = (target.position - position).normalized()
	position += direction * SPEED * delta
	animated_sprite_2d.play("attack")

func take_damage(damage: int, attacker_position: Vector2) -> void:
	health -= damage
	
	animated_sprite_2d.modulate = Color.WHITE
	var flash_tween := create_tween()
	flash_tween.tween_property(animated_sprite_2d, "modulate", original_sprite_color, 0.12)
	
	health_bar.update_health(health)
	if health <= 0:
		_die()
	else:
		take_damage_sound.play()
		#kockabck
		var knockback_direction = (position - attacker_position).normalized()
		var target_position = position + knockback_direction * KNOCKBACK_FORCE
		
		var tween = create_tween()
		tween.set_ease(Tween.EASE_OUT)
		tween.set_trans(Tween.TRANS_CUBIC)
		tween.tween_property(self, "position", target_position, 0.5)


func _die() -> void:
	if not is_alive:
		return
		
	is_alive = false
	AchievementManager.register_regular_drone_kill()
	
	if is_instance_valid(target):
		last_player_position = target.global_position
	elif last_player_position == Vector2.ZERO:
		var player = get_tree().get_first_node_in_group("player")
		if player:
			last_player_position = player.global_position
	
	call_deferred("drop_heart")
	target = null
	target_in_range = false
	
	animated_sprite_2d.play("die")
	
	take_damage_sound.pitch_scale = 0.5
	take_damage_sound.play()
	
	$CollisionShape2D.set_deferred("disabled", true)
	$sight/CollisionShape2D.set_deferred("disabled", true)
	$hitbox/CollisionShape2D.set_deferred("disabled", true)
	
	attacktimer.stop()
	
	await animated_sprite_2d.animation_finished
	
	for i in range(3):
		animated_sprite_2d.modulate.a = 0.25
		await get_tree().create_timer(0.08).timeout
		
		animated_sprite_2d.modulate.a = 1.0
		await get_tree().create_timer(0.08).timeout
		
	var dissolve_material := animated_sprite_2d.material as ShaderMaterial
	
	if dissolve_material:
		dissolve_material.set_shader_parameter("dissolve_amount", 0.0)
		
		var dissolve_tween := create_tween()
		dissolve_tween.tween_method(
			func(value:float):
				dissolve_material.set_shader_parameter("dissolve_amount", value),
			0.0,
			1.0,
			0.8,
		)
		await  dissolve_tween.finished
	else:
		#shouldnt be no else if ts works
		var dissolve_tween := create_tween()
		dissolve_tween.tween_property(animated_sprite_2d, "modulate:a", 0.0, 0.8)
		await dissolve_tween.finished
	queue_free()

func _on_sight_body_entered(body: Node2D) -> void:
	if body.name == "player1":
		target = body

func _on_sight_body_exited(body: Node2D) -> void:
	if body.name == "player1" and is_alive:
		target = null
		animated_sprite_2d.play("idle")

func _on_hitbox_body_entered(body: Node2D) -> void:
	if not is_alive:
		return
		
	if body.name == "player1":
		target_in_range = true
		body.take_damage(strength)
		attacktimer.start()

func _on_hitbox_body_exited(body: Node2D) -> void:
	if not is_alive:
		return
		
	if body.name == "player1":
		target_in_range = false
		attacktimer.stop()

func _on_attacktimer_timeout() -> void:
	if not is_alive:
		return
		
	if target and target_in_range:
		target.take_damage(strength)

#-----------------------------
# heart drop thingy
#-----------------------------
func drop_heart() -> void:
	if randf() >= HEART_DROP_CHANCE:
		return
	
	var heart = heart_scene.instantiate()
	get_parent().add_child(heart)
	heart.global_position = global_position
	
	var direction := Vector2.DOWN
	
	if is_instance_valid(target):
		direction = (last_player_position - global_position).normalized()
	
	var target_position = global_position + direction * 40.0
	
	var tween := create_tween()
	tween.set_trans(Tween.TRANS_BACK)
	tween.set_ease(Tween.EASE_OUT)
	tween.tween_property(heart, "global_position", target_position, 0.5)
