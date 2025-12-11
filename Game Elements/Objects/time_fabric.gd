extends Node2D

@onready var water_cells := []
@onready var lava_cells := []
@onready var acid_cells := []
@onready var trap_cells := []
@onready var blocked_cells := []
@onready var wall_cells := []
var velocity := Vector3.ZERO
var position_z := 0.0
var grounded := false
var rotation_speed := 0.0
var jump_cooldown := 0.0
var time_passed = 0.0
var freeze_time = 0.0

# Exported variables to tweak behavior
@export var gravity := 300.0           # Pixels/sec² downward
@export var bounce_damping := 0.5      # Vertical bounce loss
@export var horizontal_damping := 0.8  # Horizontal speed lost on bounce
@export var max_rotation_speed := 720  # Degrees/sec
@export var bob_amplitude := 4.0       # Pixels of jitter when grounded
@export var bob_speed := 10.0          # Frequency of jitter
@export var min_jump_interval := 0.3   # Minimum seconds between automatic hops
@export var max_jump_interval := 1.2   # Maximum seconds between automatic hops

signal absorbed_by_player(timefabric : Node)
func _ready() -> void:
	randomize()
	set_process(false)
	time_passed = randf() * 5
	return
func _process(delta: float) -> void:
	time_passed += delta
	freeze_time += delta
	if freeze_time < 0.2:
		return

	if not grounded:
		# --- In air: apply gravity ---
		velocity.z += gravity * delta
		position += Vector2(velocity.x, velocity.y) * delta
		position_z += velocity.z * delta

		# Rotate sprite while in air
		$Sprite2D.rotation += deg_to_rad(rotation_speed * delta)

		# Ground collision
		if position_z >= 0.0:
			position_z = 0.0
			if abs(velocity.z) > 20:
				# Bounce slightly on impact
				velocity.z *= -bounce_damping
				velocity.x *= horizontal_damping
				velocity.y *= horizontal_damping
				rotation_speed = randf_range(-max_rotation_speed, max_rotation_speed)
			else:
				# Landed fully, start hopping phase
				grounded = true
				velocity = Vector3.ZERO
				rotation_speed = 0.0
				jump_cooldown = randf_range(min_jump_interval, max_jump_interval)

	else:
		# --- Grounded: jitter + automatic hops ---
		$Sprite2D.position.y = sin(time_passed / 100.0 * bob_speed) * bob_amplitude

		jump_cooldown -= delta
		if jump_cooldown <= 0.0:
			perform_random_hop()
		
		
		
func perform_random_hop():
	# Small random horizontal velocity
	var angle = randf() * TAU
	var speed = randf_range(40, 100)  # smaller than initial toss
	var dir = Vector2(cos(angle), sin(angle))
	velocity.x = dir.x * speed
	velocity.y = dir.y * speed
	velocity.z = -randf_range(80, 150)  # small hop upward

	# Random rotation
	rotation_speed = randf_range(-max_rotation_speed, max_rotation_speed)
	grounded = false
	
func _check_if_hitting_wall(delta) -> void:
	var next_cellx := Vector2i(floor((position.x+velocity.x* delta) / 16), floor(position.y / 16))
	var next_celly := Vector2i(floor(position.x / 16), floor((position.y+velocity.y* delta) / 16))
	if next_cellx in blocked_cells or next_celly in blocked_cells:
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
	var layer_manager = get_tree().get_root().get_node("LayerManager")
	var is_multiplayer = layer_manager.is_multiplayer
	if is_multiplayer:
		check_player(layer_manager.player1)
		check_player(layer_manager.player2)
	else:
		check_player(layer_manager.player1)
	
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
