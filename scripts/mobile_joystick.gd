extends Control

@onready var knob: TextureRect = $knob

var touch_id: int = -1
var joystick_center: Vector2
var max_distance: float = 45.0


func _ready() -> void:
	joystick_center = size / 2.0
	knob.position = joystick_center - knob.size / 2.0


func _input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		
		if event.pressed and touch_id == -1:
			if get_global_rect().has_point(event.position):
				touch_id = event.index
				update_joystick(event.position)
				
		elif not event.pressed and event.index == touch_id:
			touch_id = -1
			reset_joystick()
			
	elif event is InputEventScreenDrag:
		
		if event.index == touch_id:
			update_joystick(event.position)


func update_joystick(screen_position: Vector2) -> void:
	var local_position := screen_position - global_position
	var offset := local_position - joystick_center
	
	if offset.length() > max_distance:
		offset = offset.normalized() * max_distance
		
	knob.position = joystick_center + offset - knob.size / 2.0
	
	var direction := offset / max_distance
	
	update_input(direction)


func update_input(direction: Vector2) -> void:
	Input.action_release("left")
	Input.action_release("right")
	Input.action_release("up")
	Input.action_release("down")
	
	if direction.x < -0.25:
		Input.action_press("left")
	if direction.x > 0.25:
		Input.action_press("right")
	if direction.y < -0.25:
		Input.action_press("up")
	if direction.y > 0.25:
		Input.action_press("down")


func reset_joystick() -> void:
	var center_position := joystick_center - knob.size / 2.0
	
	var tween := create_tween()
	tween.set_trans(Tween.TRANS_QUAD)
	tween.set_ease(Tween.EASE_OUT)
	tween.tween_property(knob, "position", center_position, 0.15)
	
	Input.action_release("left")
	Input.action_release("right")
	Input.action_release("up")
	Input.action_release("down")
