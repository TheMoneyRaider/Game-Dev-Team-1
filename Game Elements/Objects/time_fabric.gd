extends Node2D

@onready var water_cells := []
@onready var lava_cells := []
@onready var acid_cells := []
@onready var trap_cells := []
@onready var blocked_cells := []
@onready var wall_cells := []
@onready var z_floor = 0.0
@onready var velocity : Vector3 = Vector3(0.0,0.0,0.0)
@onready var position_z : = 0.0
@onready var z_ratio = .66

@onready var sprite := $Sprite2D  # Your visual node
var time_passed := 0.0
var freeze_time := 0.0
@export var bob_amplitude := 0.03
@export var bob_speed := 2.0       #Speed of bobbing
@export var gravity := 300.0       # Pixels per second²
var grounded : bool = false

signal absorbed_by_player(timefabric : Node)
func _ready() -> void:
	randomize()
	set_process(false)
	time_passed = randf() * 5
	return

func _process(delta: float) -> void:
	time_passed += delta
	freeze_time += delta
	if freeze_time < .125:
		return
	
	if grounded:
		sprite.offset.y += sin(time_passed * bob_speed) * bob_amplitude
		move_towards_player()
		position += Vector2(velocity.x, velocity.y) * delta
		return
		
	# Apply gravity
	velocity.y += gravity * delta
	velocity.z += gravity * delta
	
	
	_check_if_hitting_wall(delta)
		
	#Apply velocity
	position += Vector2(velocity.x, velocity.y) * delta
	position_z += velocity.z * delta
	
	#Stop all movement if timefabric landed.
	if position_z >= 0 and velocity.y > 0.0:
		velocity = Vector3(0,0,0)
		grounded = true
		
func _check_if_hitting_wall(delta) -> void:
	var current_cell := Vector2i(floor(position.x / 16), floor(position.y / 16))
	var next_cellx := Vector2i(floor((position.x+velocity.x* delta) / 16), floor(position.y / 16))
	var next_celly := Vector2i(floor(position.x / 16), floor((position.y+velocity.y* delta) / 16))
	if next_cellx in blocked_cells or next_cellx in blocked_cells:
		velocity = Vector3(0,0,0)
		grounded=true
		
		
	
	
	
	
	
func set_direction(direction : Vector2):
	#velocity = Vector2(randf_range(-50,50),randf_range(-150,-50))
	var base_dir = direction.normalized()
	#Random directional deviation
	var max_angle = deg_to_rad(20.0)  #20° cone of variation
	var angle_offset = randf_range(-max_angle, max_angle)
	var deviated_dir = base_dir.rotated(angle_offset)

	#Random length, biased toward original ---
	var orig_len = 100
	#Random factor, but biased toward 1.0 by averaging with 1.
	var random_scale = lerp(1.0, randf_range(0.5, 1.5), 0.4)
	var final_len = orig_len * random_scale
	var z = -randf_range(.25, 1.0)
	velocity = Vector3(deviated_dir.x * final_len, deviated_dir.y * final_len-60, z * final_len)


func move_towards_player():
	var layer_manager = get_parent().get_parent()
	var is_multiplayer = layer_manager.is_multiplayer
	if is_multiplayer:
		check_player(layer_manager.player)
		check_player(layer_manager.player_2)
	else:
		check_player(layer_manager.player)
	
func check_player(player : Node):
	var dir = (player.position - position) #direction to the player
	var distance = dir.length()
	var attraction_radius = 60.0
	if distance < attraction_radius:
		var new_vel = dir.normalized() * (100.0 + (attraction_radius - distance) * 5.0)
		velocity = Vector3(new_vel.x,new_vel.y,0)
	if distance < 5:
		emit_signal("absorbed_by_player",self)
	
func set_arrays(layer_manager : Node, walls_array : Array) -> void:
	water_cells = layer_manager.water_cells
	lava_cells = layer_manager.lava_cells
	acid_cells = layer_manager.acid_cells
	trap_cells = layer_manager.trap_cells
	blocked_cells = layer_manager.blocked_cells
	wall_cells = walls_array
