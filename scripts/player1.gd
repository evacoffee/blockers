extends CharacterBody2D

signal health_changed(new_health: int)
signal died

const SPEED = 300.0 
const MAX_FLASHLIGHT: float = 100.0
const FLASHLIGHT_DRAIN: float = 1.0

var flashlight: float = MAX_FLASHLIGHT
var flashlight_ficker_time: float = 0.0
var flashlight_base_energy: float
var flashlight_start_locked: bool = true
var last_direction: Vector2 = Vector2.RIGHT
var is_attacking: bool = false
var hitbox_offset: Vector2
var strength: int = 20
var max_health: int
var health: int
var alive: bool = true

@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D
@onready var swing_spear_sound: AudioStreamPlayer2D = $swingspear
@onready var hitbox: Area2D = $hitbox
@onready var light: PointLight2D = $light
@onready var take_damage_sound: AudioStreamPlayer2D = $takedamage
@onready var damagecooldown: Timer = $damagecooldown
@onready var lightoff_on: AudioStreamPlayer2D = $lightoff_on
@onready var camera_2d: Camera2D = $Camera2D
@onready var hitparticles: GPUParticles2D = $hitparticles

func _ready() -> void:
	#load jhealth from singleton
	health = playerstats.health
	max_health = playerstats.max_health
	#lado flashlight
	flashlight = playerstats.flashlight
	flashlight_base_energy = light.energy
	#initialize hitbox ffset
	hitbox_offset = hitbox.position
	light.enabled = false

func _physics_process(delta: float) -> void:
	hitbox.monitoring = false
	if alive:
		if Input.is_action_just_pressed("attack") and not is_attacking:
			attack()
		drain_flashlight(delta)
		#skip movment if attacking
		if is_attacking:
			velocity = Vector2.ZERO 
			return
			
		process_movement()
		process_animation()
		move_and_slide()

# -------------------------
# movement & animations
# -------------------------
func process_movement() -> void:
	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	var direction := Input.get_vector("left", "right", "up", "down")
	if direction != Vector2.ZERO:
		velocity = direction * SPEED
		last_direction = direction
		update_hitbox_offset()
	else: 
		velocity = Vector2.ZERO

func process_animation() -> void:
	#disable hitbox until an attack is trig
	hitbox.monitoring = false
	if is_attacking:
		return
	if velocity != Vector2.ZERO: 
		play_animation("run", last_direction)
	else:
		play_animation("idle", last_direction)
	
func play_animation(prefix: String, dir: Vector2) -> void:
	if dir.x != 0:
		animated_sprite_2d.flip_h = dir.x < 0
		animated_sprite_2d.play(prefix + "_right")
	elif dir.y < 0:
		animated_sprite_2d.play(prefix + "_up")
	elif dir.y > 0:
		animated_sprite_2d.play(prefix + "_down")
		
#------------------------------
#attacking
#------------------------------
func attack() -> void:
	is_attacking = true
	hitbox.monitoring = true
	swing_spear_sound.play()
	play_animation("attack", last_direction)

func _on_animated_sprite_2d_animation_finished() -> void:
	if is_attacking:
		is_attacking = false

# -----------------------
# hitbox
# -----------------------
func update_hitbox_offset() -> void:
	var x := hitbox_offset.x
	var y := hitbox_offset.y
	
	match last_direction: 
		Vector2.LEFT:
			hitbox.position = Vector2(-x, y)
		Vector2.RIGHT:
			hitbox.position = Vector2(x, y)
		Vector2.UP:
			hitbox.position = Vector2(y, -x)
		Vector2.DOWN:
			hitbox.position = Vector2(-y, x)


func _on_hitbox_body_entered(body: Node2D) -> void:
	if not is_attacking:
		return
		
	if body.name.begins_with("elecdrone"):
		body.take_damage(strength, position)
		play_hitparticles(body.global_position)
		shake_camera(3.0, 0.12)
		
	elif body.name.begins_with("regdrone"):
		body.take_damage(strength, position)
		play_hitparticles(body.global_position)
		shake_camera(3.0, 0.12)

func take_damage(amount: int) -> void:
	if alive: 
		if damagecooldown.time_left > 0:
			return
		
		take_damage_sound.play()
		
		if DisplayServer.is_touchscreen_available():
			Input.vibrate_handheld(60, 0.5)
			
		health -= amount
		playerstats.health = health
		emit_signal("health_changed", health)
		if health <= 0:
			die()
		#make player invi
		damagecooldown.start()

func heal(amount: int) -> void:
	if not alive:
		return
	
	health += amount
	health = min(health, max_health)
	
	playerstats.health = health
	emit_signal("health_changed", health)

func die() -> void:
	animated_sprite_2d.play("dying")
	alive = false
	await animated_sprite_2d.animation_finished
	died.emit()

#-----
#lgiht
#-------
func drain_flashlight(delta: float) -> void:
	flashlight -= FLASHLIGHT_DRAIN * delta
	flashlight = max(flashlight, 0.0)
	
	playerstats.flashlight = flashlight
	
	if flashlight <= 0.0:
		if light.enabled:
			light.enabled = false
			lightoff_on.play()
	else:
		if not light.enabled and not flashlight_start_locked:
			light.enabled = true
			lightoff_on.play()
		
		flashlight_ficker_time += delta
		
		var flicker_strength: float = 0.0
		
		if flashlight <= 10.0:
			flicker_strength = 0.35
		elif flashlight <= 25.0:
			flicker_strength = 0.15
		
		if flicker_strength > 0.0:
			var flicker := sin(flashlight_ficker_time * 18.0)
			light.energy = flashlight_base_energy * (1.0 - abs(flicker) * flicker_strength)
		else:
			light.energy = flashlight_base_energy
	
	var hud = get_tree().get_first_node_in_group("hud")
	if hud:
		hud.update_flashlight(flashlight)

func refill_flashlight() -> void:
	flashlight = MAX_FLASHLIGHT
	playerstats.flashlight = flashlight
	
	if not light.enabled:
		light.enabled = true
		lightoff_on.play()

#--------------------
# camera shakeing
#--------------------
func shake_camera(intensity: float = 3.0, duration: float = 0.12) -> void:
	var original_offset := camera_2d.offset
	var tween := create_tween()
	
	for i in range(4):
		var random_offset := Vector2(randf_range(-intensity, intensity), randf_range(-intensity, intensity))
		
		tween.tween_property(camera_2d, "offset", random_offset, duration / 8.0)
		
		tween.tween_property(camera_2d, "offset", original_offset, duration / 8.0)
		
	tween.finished.connect(func(): camera_2d.offset = original_offset)

#---------------------
#spear particles
#---------------------
func play_hitparticles(hit_position: Vector2) -> void:
	hitparticles.global_position = hit_position
	hitparticles.restart()
	hitparticles.emitting = true
