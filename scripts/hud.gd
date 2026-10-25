extends CanvasLayer

const HEART_SIZE: int = 20
var player
var level_button_hidden := false
var level_start_timer := 0.0

const HEART_FULL = preload("res://assets/images/ui/heart_full.png")
const HEART_HALF = preload("res://assets/images/ui/heart_half.png")
const HEART_EMPTY = preload("res://assets/images/ui/heart_empty.png")
const achievement_font = preload("res://assets/images/font/Abaddon Bold.ttf")

@onready var fadeoverlay: ColorRect = $fadeoverlay
@onready var hearts_container: HBoxContainer = $hearts
@onready var flashlightbar: ProgressBar = $flashlightbar
@onready var switchcounter: Label = $switchcounter
@onready var pausemenu: Panel = $pausemenu
@onready var resumebutton: Button = $pausemenu/resumebutton
@onready var quitbutton: Button = $pausemenu/quitbutton
@onready var powermessage: Label = $powermessage
@onready var levelbutton: Button = $levelbutton
@onready var leveltitle: Label = $leveltitle
@onready var achievementpopup: Panel = $achievementpopup
@onready var achievementtitle: Label = $achievementpopup/achievementtitle
@onready var achievementdescription: Label = $achievementpopup/achievementdescription
@onready var achievementsbutton: Button = $achievementsbutton
@onready var achievementspanel: Panel = $achievementspanel
@onready var achievementlist: VBoxContainer = $achievementspanel/ScrollContainer/achievementlist
@onready var closeachievements: Button = $achievementspanel/closeachievements


func _ready() -> void:
	fadeoverlay.modulate.a = 0.0
	
	process_mode = Node.PROCESS_MODE_ALWAYS
	pausemenu.process_mode = Node.PROCESS_MODE_ALWAYS
	resumebutton.process_mode = Node.PROCESS_MODE_ALWAYS
	quitbutton.process_mode = Node.PROCESS_MODE_ALWAYS
	pausemenu.visible = false
	levelbutton.visible = true
	setup_level_button()
	level_button_hidden = false
	level_start_timer = 0.0
	
	resumebutton.pressed.connect(_on_resume_pressed)
	quitbutton.pressed.connect(_on_quit_pressed)
	
	AchievementManager.achievement_unlocked.connect(_on_achievement_unlocked)
	achievementpopup.visible = false
	
	var is_mobile := OS.has_feature("android") or OS.has_feature("ios")
	levelbutton.disabled = is_mobile
	levelbutton.modulate.a = 0.8 if is_mobile else 1.0
	
	achievementsbutton.disabled = is_mobile
	achievementsbutton.modulate.a = 0.8 if is_mobile else 1.0
	
	achievementspanel.visible = false
	
	achievementspanel.process_mode = Node.PROCESS_MODE_ALWAYS
	closeachievements.process_mode = Node.PROCESS_MODE_ALWAYS
	achievementsbutton.process_mode = Node.PROCESS_MODE_ALWAYS
	
	achievementsbutton.pressed.connect(_open_achievements)
	closeachievements.pressed.connect(_close_achievements)

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause"):
		toggle_pause()

func toggle_pause() -> void:
	get_tree().paused = not get_tree().paused
	pausemenu.visible = get_tree().paused

func _on_resume_pressed() -> void:
	get_tree().paused = false
	pausemenu.visible = false

func _on_quit_pressed() -> void:
	get_tree().paused = false #must upasue before chaging  scine
	pausemenu.visible = false
	playerstats.reset()
	get_tree().change_scene_to_file("res://scenes/titlescreen.tscn")
#-----
#playerset
#-------

func set_player(p) -> void:
	player = p
	levelbutton.visible = true
	setup_level_button()
	level_button_hidden = false
	level_start_timer = 0.0
	if player:
		player.health_changed.connect(_update_health)
		_update_health(player.health)

func _update_health(new_health: int) -> void:
	var hearts = hearts_container.get_children()
	var max_hearts = len(hearts)
	var full = int(float(new_health) / HEART_SIZE)
	var half = 1 if (new_health % HEART_SIZE) > 0 else 0
	var empty = max_hearts - (full + half)
	
	#update full heats
	for i in full:
		hearts[i].texture = HEART_FULL
	#update half he
	if half:
		hearts[full].texture = HEART_HALF
	#update empty hear
	for i in empty:
		hearts[len(hearts) - 1 - i].texture = HEART_EMPTY

func fade(to_alpha: float) -> void:
	var tween := create_tween()
	tween.tween_property(fadeoverlay, "modulate:a", to_alpha, 1.5)
	await tween.finished

#----
#light
#----
func update_flashlight(amount: float) -> void:
	flashlightbar.value = amount

func hide_flashlight_hud() -> void:
	flashlightbar.visible = false

func show_flashlight_hud() -> void:
	flashlightbar.visible = true
#----
#switches
#-------
func update_switch_counter(activated: int, total: int) -> void:
	switchcounter.text = "POWER: " + str(activated) + " / " + str(total)

func show_power_restored() -> void:
	powermessage.text = "ALL POWER RESTORED"
	powermessage.visible = true
	powermessage.modulate.a = 0.0
	
	var tween := create_tween()
	tween.tween_property(powermessage, "modulate:a", 1.0, 0.3)
	
	await get_tree().create_timer(5.0).timeout
	var fade_tween := create_tween()
	fade_tween.tween_property(powermessage, "modulate:a", 0.0, 0.5)
	
	await fade_tween.finished
	powermessage.visible = false

func show_level_title(level_number: int) -> void:
	leveltitle.text = "LEVEL " + str(level_number)
	leveltitle.visible = true
	leveltitle.modulate.a = 0.0
	
	var fade_in := create_tween()
	fade_in.tween_property(leveltitle, "modulate:a", 1.0, 0.5)
	
	await get_tree().create_timer(1.5).timeout
	
	var fade_out = create_tween()
	fade_out.tween_property(leveltitle, "modulate:a", 0.0, 0.7)
	
	await fade_out.finished
	leveltitle.visible = false
#----------------
#levelselect
#----------------

func show_level_button() -> void:
	levelbutton.visible = true
	setup_level_button()
	level_button_hidden = false
	level_start_timer = 0.0

func _on_levelbutton_pressed() -> void:
	var player1 = get_tree().get_first_node_in_group("player")
	if player1:
		playerstats.return_level = get_tree().current_scene.level
	get_tree().change_scene_to_file("res://scenes/levelselect.tscn")

func setup_level_button() -> void:
	var is_mobile: bool = OS.has_feature("android") or OS.has_feature("ios")
	levelbutton.disabled = is_mobile
	levelbutton.modulate.a = 0.7 if is_mobile else 1.0

#-----------------------------
#acheivements
#-----------------------------
func _on_achievement_unlocked(title: String, description: String) -> void:
	achievementtitle.text = " ACHIEVEMENT UNLOCKED! \n" + title
	achievementdescription.text = description
	
	achievementtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	achievementtitle.autowrap_mode = TextServer.AUTOWRAP_WORD
	
	achievementdescription.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	achievementdescription.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	achievementdescription.autowrap_mode = TextServer.AUTOWRAP_WORD
	
	achievementpopup.visible = true
	achievementpopup.modulate.a = 0.0
	achievementpopup.scale = Vector2(0.85, 0.85)
	achievementpopup.pivot_offset = achievementpopup.size / 2.0
	
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(achievementpopup, "modulate:a", 1.0, 4.0)
	tween.tween_property(achievementpopup, "scale", Vector2.ONE, 4.0)
	
	tween.set_parallel(false)
	tween.tween_interval(16.0)
	
	tween.set_parallel(true)
	tween.tween_property(achievementpopup, "modulate:a", 0.0, 4.0)
	tween.tween_property(achievementpopup, "scale", Vector2(0.9, 0.9), 4.0)
	
	tween.finished.connect(_hide_achievement_popup)

func _hide_achievement_popup() -> void:
	achievementpopup.visible = false

func _open_achievements() -> void:
	if OS.has_feature("android") or OS.has_feature("ios"):
		return
	
	get_tree().paused = true
	pausemenu.visible = false
	achievementspanel.visible = true
	
	for child in achievementlist.get_children():
		achievementlist.remove_child(child)
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

func _close_achievements() -> void:
	achievementspanel.visible = false
	get_tree().paused = false
