extends GPUParticles2D

var timer: float = 0.0

func _process(delta: float) -> void:
	timer -= delta
	if timer <= 0.0:
		timer = randf_range(2.0, 4.0)
		if get_parent().lightoff_on:
			emitting = true
		else:
			emitting = false
