extends Node2D

const DEFAULT_SPEED = 20.0
@onready var player = $".."
var crosshair_direction = Vector2(1,0)
var last_input_device = "keyboard"

func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)

func _input(event):
	if event is InputEventKey or event is InputEventMouse:
		last_input_device = "keyboard"
	else:
		last_input_device = "controller"

func _process(_delta: float) -> void:
	var input_direction = Input.get_vector("look_Left", "look_Right", "look_Up", "look_Down").normalized()
	if(input_direction != Vector2(0,0)):
		crosshair_direction = input_direction		
	var camera = get_viewport().get_camera_2d()
	var mouse_coords = camera.get_local_mouse_position()
	var direction = mouse_coords.normalized()
	
	if last_input_device == "keyboard":
		if(mouse_coords.length() < 70):
			position = mouse_coords
		else:
			position = direction * 70
	else:
		position = (crosshair_direction * 50)
