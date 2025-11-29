extends Node2D

var input_device = "key"

func set_input_device(device : String):
	input_device = device

func _process(_delta: float) -> void:
	position = get_global_mouse_position()
