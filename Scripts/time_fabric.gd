extends Node2D

@onready var water_cells := []
@onready var lava_cells := []
@onready var acid_cells := []
@onready var trap_cells := []
@onready var blocked_cells := []
@onready var wall_cells := []
@onready var y_floor = 0.0
@onready var velocity : Vector2 = Vector2(0.0,0.0)

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
		position += velocity * delta
		return
		
	# Apply gravity
	velocity.y += gravity * delta
	
	#Apply velocity
	position += velocity * delta

	#Check if inside any wall cell
	var current_cell := Vector2i(floor(position.x / 16), floor(position.y / 16))
	var inside_wall := current_cell in wall_cells

	#Stop vertical movement only if below floor and not inside wall
	if position.y >= y_floor and not inside_wall and velocity.y > 0.0:
		grounded = true
		velocity = Vector2(0,0)
	
func set_velocity(velocity_in : Vector2):
	velocity = velocity_in

func set_floor(new_floor : float) -> void:
	y_floor = new_floor

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
		velocity = dir.normalized() * (100.0 + (attraction_radius - distance) * 5.0)
	if distance < 5:
		emit_signal("absorbed_by_player",self)
	
func set_arrays(layer_manager : Node, walls_array : Array) -> void:
	water_cells = layer_manager.water_cells
	lava_cells = layer_manager.lava_cells
	acid_cells = layer_manager.acid_cells
	trap_cells = layer_manager.trap_cells
	blocked_cells = layer_manager.blocked_cells
	wall_cells = walls_array
