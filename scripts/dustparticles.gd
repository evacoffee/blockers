extends GPUParticles2D

var camera: Camera2D
var flashlight: PointLight2D

func _ready() -> void:
	emitting = true

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	if not is_instance_valid(camera):
		camera = get_tree().current_scene.find_child("Camera2D", true, false)
		if camera:
			global_position = camera.global_position
			
	if not is_instance_valid(flashlight):
		flashlight = get_tree().current_scene.find_child("light", true, false)
		if flashlight:
			var distance = global_position.distance_to(flashlight.global_position)
			if distance < 180:
				speed_scale = 0.3
			else:
				speed_scale = 1.0
