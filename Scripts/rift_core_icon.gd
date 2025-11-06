extends Sprite2D
func _process(_delta):
	if material:
		material.set_shader_parameter("u_time", Time.get_ticks_msec() / 1000.0)
