extends Sprite2D
var mat : ShaderMaterial

func _ready():
	mat = material
func _process(_delta):
	if mat:
		mat.set_shader_parameter("u_time", Time.get_ticks_msec() / 1000.0)
