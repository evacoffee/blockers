extends CanvasLayer

@onready var attackbutton: TextureButton = $attackbutton
@onready var interactbutton: TextureButton = $interactbutton
@onready var potholebutton: TextureButton = $potholebutton

var pressed_scale := 0.88


func _ready() -> void:
	if not DisplayServer.is_touchscreen_available():
		visible = false
		return

	attackbutton.button_down.connect(_attack_down)
	attackbutton.button_up.connect(_attack_up)

	interactbutton.button_down.connect(_interact_down)
	interactbutton.button_up.connect(_interact_up)

	potholebutton.button_down.connect(_pothole_down)
	potholebutton.button_up.connect(_pothole_up)

func _attack_down() -> void:
	press_visual(attackbutton)
	Input.action_press("attack")
	Input.vibrate_handheld(40)

func _attack_up() -> void:
	release_visual(attackbutton)
	Input.action_release("attack")

func _interact_down() -> void:
	press_visual(interactbutton)
	Input.action_press("interact")
	Input.vibrate_handheld(25)

func _interact_up() -> void:
	release_visual(interactbutton)
	Input.action_release("interact")

func _pothole_down() -> void:
	press_visual(potholebutton)
	Input.action_press("pothole")
	Input.vibrate_handheld(25)

func _pothole_up() -> void:
	release_visual(potholebutton)
	Input.action_release("pothole")

func press_visual(button: TextureButton) -> void:
	var tween := create_tween()
	tween.set_trans(Tween.TRANS_QUAD)
	tween.set_ease(Tween.EASE_OUT)

	tween.tween_property(button, "scale", Vector2.ONE * pressed_scale, 0.06)

func release_visual(button: TextureButton) -> void:
	var tween := create_tween()
	tween.set_trans(Tween.TRANS_BACK)
	tween.set_ease(Tween.EASE_OUT)

	tween.tween_property(button, "scale", Vector2.ONE, 0.12)

func vibrate(duration: int = 30, strength: float = 0.3) -> void:
	if DisplayServer.is_touchscreen_available():
		Input.vibrate_handheld(duration, strength)
