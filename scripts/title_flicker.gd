extends Label

var flicker_timer: float = 0.0
var next_flicker: float = 2.0
var flickering: bool = false

var normal_color := Color("#FFEACD")
var glow_color := Color("#FFD27A")


func _process(delta: float) -> void:
	flicker_timer += delta
	
	if flicker_timer >= next_flicker and not flickering:
		flicker()
		
		flicker_timer = 0.0
		next_flicker = randf_range(2.0, 6.0)


func flicker() -> void:
	flickering = true
	modulate = Color("#FFEACD", 0.65)
	await get_tree().create_timer(0.25).timeout
	modulate = normal_color
	await get_tree().create_timer(0.35).timeout
	modulate = Color("#FFE0A8")
	await get_tree().create_timer(0.18).timeout
	modulate = glow_color
	await get_tree().create_timer(0.30).timeout
	modulate = normal_color
	await get_tree().create_timer(0.45).timeout
	
	flickering = false
