extends Control

const LEVEL_FONT = preload("res://assets/images/font/Abaddon Bold.ttf")

@onready var levellist: HBoxContainer = $ScrollContainer/levellist
@onready var fade: ColorRect = $fade
@onready var music: AudioStreamPlayer2D = $music
@onready var backbutton: Button = $backbutton


func _ready() -> void:
	fade.color.a = 0.0
	music.play()
	
	playerstats.load_level_progress()
	create_level_buttons()
	
func create_level_buttons() -> void:
	for child in levellist.get_children():
		levellist.remove_child(child)
		child.queue_free()

	var level_numbers: Array[int] = [
		1, 2, 3, 4, 5,
		6, 7, 8, 9, 10,
		11, 12, 13, 14, 15
	]

	for level_number in level_numbers:
		create_level_button(level_number)

	levellist.hide()
	await get_tree().process_frame
	levellist.queue_sort()
	await get_tree().process_frame
	levellist.show()

func create_level_button(level_number: int) -> void:
	var button := Button.new()

	button.text = "level " + str(level_number)
	button.custom_minimum_size = Vector2(220, 120)
	button.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	button.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	
	#fonts overrdies
	button.add_theme_font_override("font", LEVEL_FONT)
	button.add_theme_font_size_override("font_size", 26)
	button.add_theme_color_override("font_color", Color("#FFEACD"))
	button.add_theme_color_override("font_hover_color", Color("#FFFFFF"))
	button.add_theme_color_override("font_pressed_color", Color("#0B2945"))
	
	var normal_style := StyleBoxFlat.new()
	normal_style.bg_color = Color("#0B2945")
	normal_style.border_color = Color("#FFEACD")
	normal_style.set_border_width_all(2)
	normal_style.set_corner_radius_all(12)
	normal_style.content_margin_left = 20
	normal_style.content_margin_right = 20
	normal_style.content_margin_top = 15
	normal_style.content_margin_bottom = 15
	
	var hover_style := normal_style.duplicate()
	hover_style.bg_color = Color("#173F5F")
	
	var pressed_style := normal_style.duplicate()
	pressed_style.bg_color = Color("#FFEACD")
	
	button.add_theme_stylebox_override("normal", normal_style)
	button.add_theme_stylebox_override("hover", hover_style)
	button.add_theme_stylebox_override("pressed", pressed_style)
	
	if level_number > playerstats.highest_level_unlocked:
		button.text = "level " + str(level_number) + "\nLOCKED"
		button.disabled = true
	else:
		button.pressed.connect(_on_level_pressed.bind(level_number))
		
	levellist.add_child(button)


func _on_level_pressed(level_number: int) -> void:
	playerstats.selected_level = level_number
	playerstats.reset()
	
	fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	var tween := create_tween()
	tween.set_trans(Tween.TRANS_SINE)
	tween.set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(fade, "color:a", 1.0, 0.6)
	
	await tween.finished
	
	get_tree().change_scene_to_file("res://scenes/main.tscn")

func _on_back_pressed() -> void:
	fade.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var tween := create_tween()
	tween.set_trans(Tween.TRANS_SINE)
	tween.set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(fade, "color:a", 1.0, 0.6)

	await tween.finished

	playerstats.selected_level = playerstats.return_level
	get_tree().change_scene_to_file("res://scenes/main.tscn")
