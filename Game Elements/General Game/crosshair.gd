extends Node2D

const DEFAULT_SPEED = 20.0
@onready var player = $".."
var crosshair_direction = Vector2(1,0)
var player_input_device = "key"
var mouse_sensitivity = 1.0

func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)
	player_input_device = player.input_device
	load_mouse_sensitivity()
	
func load_mouse_sensitivity():
	var config = ConfigFile.new()
	var err = config.load("user://settings.cfg")
	
	if err == OK:
		mouse_sensitivity = config.get_value("controls", "mouse_sensitivity", 1.0)
	else: 
		mouse_sensitivity = 1.0

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
	
	mouse_coords = mouse_coords * mouse_sensitivity
	const CIRCLE_RADIUS = 70
	
	if player_input_device == "key":
		if((mouse_coords).length() < CIRCLE_RADIUS):
			global_position = player.global_position + mouse_coords
		else:
			var clamped_offset = direction * CIRCLE_RADIUS
			global_position = player.global_position + clamped_offset
			
			var offset_unscaled = clamped_offset / mouse_sensitivity
			var viewport_clamped = camera.get_global_transform().basis_xform(offset_unscaled) + Vector2(viewport_size/2)
			Input.warp_mouse(viewport_clamped)
	else:
		position = (crosshair_direction * 50)
