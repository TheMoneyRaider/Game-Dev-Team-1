extends Node2D

const DEFAULT_SPEED = 20.0
@onready var player = $".."
var crosshair_direction = Vector2(1,0)
var player_input_device = "key"


func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)
	player_input_device = player.input_device

func _process(_delta: float) -> void:
	var input_direction = Vector2.ZERO
	if(player_input_device != "key"):
		input_direction = Input.get_vector("look_left_" + player_input_device, "look_right_" + player_input_device, "look_up_" + player_input_device, "look_down_" + player_input_device).normalized()
		if(input_direction != Vector2(0,0)):
			crosshair_direction = input_direction
			
	
	var camera = get_tree().get_root().get_node("LayerManager/game_container/game_viewport/game_root/Camera2D")
	var viewport_size = get_tree().get_root().get_node("LayerManager/game_container/game_viewport").size
	var mouse_pos_viewport = get_tree().get_root().get_mouse_position()
	var mouse_coords = camera.get_global_transform().affine_inverse().basis_xform(mouse_pos_viewport - Vector2(viewport_size/2))
	var direction = (mouse_coords).normalized()
	if player_input_device == "key":
		if((mouse_coords).length() < 70):
			global_position = player.global_position + mouse_coords
		else:
			Input.warp_mouse(camera.get_global_transform().basis_xform(direction * 70) + Vector2(viewport_size/2))
			global_position = player.global_position + (direction * 70)
	else:
		position = (crosshair_direction * 50)
