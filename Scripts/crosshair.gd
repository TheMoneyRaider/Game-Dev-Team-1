extends Node2D

const DEFAULT_SPEED = 20.0
@onready var Player = $"../PlayerCat"
var crosshair_direction = Vector2(1,0)

func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)

func _process(_delta: float) -> void:
	var input_direction = Input.get_vector("look_Left", "look_Right", "look_Up", "look_Down").normalized()
	if(input_direction != Vector2(0,0)):
		crosshair_direction = input_direction		
	var camera = get_viewport().get_camera_2d()
	var mouse_coords = camera.get_global_mouse_position()
	var direction = (mouse_coords - Player.position).normalized()
	
	if((mouse_coords - Player.position).length() < 50):
		position = mouse_coords
	else:
		position = direction * 50 + Player.position
	#position = (crosshair_direction * 50) + Player.position
