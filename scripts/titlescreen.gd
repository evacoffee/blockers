extends Control

@onready var settingspanel: Panel = $settingspanel
@onready var credits_controlpanel: Panel = $credits_controlpanel
@onready var extraspanel: Panel = $extraspanel

@onready var volumeslider: HSlider = $settingspanel/volumeslider
@onready var buttonsound: AudioStreamPlayer2D = $buttonsound

@onready var startbutton: Button = $startbutton
@onready var settingsbutton: Button = $settingsbutton
@onready var creditsbutton: Button = $creditsbutton
@onready var extrasbutton: Button = $extrasbutton

@onready var levelsbutton: Button = $extraspanel/levelsbutton
@onready var achievementsbutton: Button = $extraspanel/achievementsbutton
@onready var extrasclosebutton: Button = $extraspanel/extrasclosebutton

@onready var achievementspanel: Panel = $achievementspanel
@onready var achievementlist: VBoxContainer = $achievementspanel/ScrollContainer/achievementlist
@onready var achievementsclosebutton: Button = $achievementspanel/achievementsclosebutton

const achievement_font = preload("res://assets/images/font/Abaddon Bold.ttf")

func _ready() -> void:
	settingspanel.visible = false
	credits_controlpanel.visible = false
	extraspanel.visible = false
	achievementspanel.visible = false
	
	var is_mobile := OS.has_feature("android") or OS.has_feature("ios")
	levelsbutton.disabled = is_mobile
	achievementsbutton.disabled = is_mobile
	levelsbutton.modulate.a = 0.8 if is_mobile else 1.0
	achievementsbutton.modulate.a = 0.8 if is_mobile else 1.0
	
	var master_volume = AudioServer.get_bus_volume_linear(AudioServer.get_bus_index("Master"))
	volumeslider.value = master_volume * 100
	volumeslider.value_changed.connect(_on_volume_slider_changed)


func _on_volume_slider_changed(value: float) -> void:
	var master_bus = AudioServer.get_bus_index("Master")
	AudioServer.set_bus_volume_linear(master_bus, value / 100.0)


func _on_startbutton_pressed() -> void:
	buttonsound.play()
	await get_tree().create_timer(0.5).timeout
	
	var tween := create_tween()
	tween.set_trans(Tween.TRANS_SINE)
	tween.set_ease(Tween.EASE_IN_OUT)
	tween.tween_property($darkness, "color:a", 1.0, 1.2)
	
	await tween.finished
	await get_tree().create_timer(0.15).timeout
	get_tree().change_scene_to_file("res://scenes/main.tscn")


func _on_settingsbutton_pressed() -> void:
	buttonsound.play()
	settingspanel.visible = true
	credits_controlpanel.visible = false


func _on_settingsclose_pressed() -> void:
	buttonsound.play()
	settingspanel.visible = false


func _on_creditsbutton_pressed() -> void:
	buttonsound.play()
	credits_controlpanel.visible = true
	settingspanel.visible = false


func _on_credits_controlclose_pressed() -> void:
	buttonsound.play()
	credits_controlpanel.visible = false

func _on_extrasbutton_pressed() -> void:
	buttonsound.play()
	extraspanel.visible = true
	settingspanel.visible = false
	credits_controlpanel.visible = false

func _on_extrasclosebutton_pressed() -> void:
	buttonsound.play()
	extraspanel.visible = false

func _on_levelsbutton_pressed() -> void:
	buttonsound.play()
	await get_tree().create_timer(0.15).timeout
	get_tree().change_scene_to_file("res://scenes/levelselect.tscn")

func _on_achievementsbutton_pressed() -> void:
	buttonsound.play()
	extraspanel.visible = false
	achievementspanel.visible = true
	update_achievement_list()

func _on_achievementsclosebutton_pressed() -> void:
	buttonsound.play()
	achievementspanel.visible = false
	extraspanel.visible = true

func _input(event: InputEvent) -> void:
	if event is InputEventScreenTouch and event.pressed:
		if startbutton.get_global_rect().has_point(event.position):
			_on_startbutton_pressed()
		elif settingsbutton.get_global_rect().has_point(event.position):
			_on_settingsbutton_pressed()
		elif creditsbutton.get_global_rect().has_point(event.position):
			_on_creditsbutton_pressed()

func update_achievement_list() -> void:
	for child in achievementlist.get_children():
		child.queue_free()
		
	for achievement in AchievementManager.get_all_achievements():
		var title: String = achievement["title"]
		var description: String = achievement["description"]
		var unlocked: bool = AchievementManager.unlocked_achievements.has(title)
		
		var card := PanelContainer.new()
		card.custom_minimum_size = Vector2(0, 76)
		card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		
		var style := StyleBoxFlat.new()
		style.bg_color = Color("#0B2945")
		style.border_color = Color("#FFEACD")
		style.set_border_width_all(2)
		style.set_corner_radius_all(8)
		style.content_margin_left = 14
		style.content_margin_right = 14
		style.content_margin_top = 8
		style.content_margin_bottom = 8
		card.add_theme_stylebox_override("panel", style)
		
		var text_box := VBoxContainer.new()
		text_box.add_theme_constant_override("separation", 3)
		text_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		
		var title_label := Label.new()
		title_label.text = ("★ " if unlocked else "LOCKED: ") + title
		title_label.add_theme_color_override("font_color", Color("#FFEACD") if unlocked else Color("#A6AFB8"))
		title_label.add_theme_font_size_override("font_size", 18)
		title_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		title_label.autowrap_mode = TextServer.AUTOWRAP_WORD
		
		var description_label := Label.new()
		description_label.text = description
		description_label.add_theme_color_override("font_color", Color("#FFEACD") if unlocked else Color("#A6AFB8"))
		description_label.add_theme_font_size_override("font_size", 14)
		description_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		description_label.autowrap_mode = TextServer.AUTOWRAP_WORD
		
		if achievement_font != null:
			title_label.add_theme_font_override("font", achievement_font)
			description_label.add_theme_font_override("font", achievement_font)
			
		text_box.add_child(title_label)
		text_box.add_child(description_label)
		card.add_child(text_box)
		achievementlist.add_child(card)
