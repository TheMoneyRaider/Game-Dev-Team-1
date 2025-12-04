extends Node2D

const DEFAULT_SPEED = 20.0
@onready var player = $".."
var crosshair_direction = Vector2(1,0)
var player_input_device = "key"
var mouse_sensitivity = 1.0
var debug_mode = false
var mouse_clamping_enabled = true

func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)
	player_input_device = player.input_device
	load_settings()
	
func _input(event):
	if event.is_action_pressed("toggle_mouse_clamp"):
		mouse_clamping_enabled = !mouse_clamping_enabled
	
func load_settings():
	var config = ConfigFile.new()
	var err = config.load("user://settings.cfg")
	
	if err == OK:
		mouse_sensitivity = config.get_value("controls", "mouse_sensitivity", 1.0)
		debug_mode = config.get_value("debug", 'enabled', false)
	else: 
		mouse_sensitivity = 1.0
		debug_mode = false

func _process(_delta: float) -> void:
	var input_direction = Vector2.ZERO
	if(player_input_device != "key"):
		input_direction = Input.get_vector("look_left_" + player_input_device, "look_right_" + player_input_device, "look_up_" + player_input_device, "look_down_" + player_input_device).normalized()
		if(input_direction != Vector2(0,0)):
			crosshair_direction = input_direction
	
	var camera = get_viewport().get_camera_2d()
	var mouse_coords = camera.get_global_mouse_position()
	var direction  = (mouse_coords - player.global_position).normalized()
	
	var CIRCLE_RADIUS = 70
	
	if player_input_device == "key":
		if((mouse_coords - player.global_position).length() < CIRCLE_RADIUS):
			global_position = mouse_coords
		else:
			
			var clamped_offset = direction * CIRCLE_RADIUS
			global_position = player.global_position + clamped_offset
			
			if mouse_clamping_enabled:
				var unscaled_offset = clamped_offset / mouse_sensitivity
				var target_mouse_world = player.global_position + unscaled_offset
				var screen_pos = camera.get_viewport().get_screen_transform() * camera.get_canvas_transform() * target_mouse_world
				Input.warp_mouse(screen_pos)
	else:
		position = (crosshair_direction * 50)
