extends CharacterBody2D
const attack = preload("res://Scripts/attack.gd")

@export var move_speed: float = 100
@export var max_health: float = 10
@export var current_health: float = 10
@export var current_dmg_time: float = 0.0
@export var in_instant_trap: bool = false

@export var starting_direction : Vector2 =  Vector2(0,1)

@onready var animation_tree = $AnimationTree
@onready var state_machine = animation_tree.get("parameters/playback")
@onready var crosshair = $Crosshair
@onready var crosshair_sprite = $Crosshair/Sprite2D
@onready var sprite = $Sprite2D
@onready var purple_crosshair = preload("res://art/purple_crosshair.png")
@onready var orange_crosshair = preload("res://art/orange_crosshair.png")
@onready var purple_texture = preload("res://art/Sprout Lands - Sprites - Basic pack/Characters/Basic Purple Spritesheet-export.png")
@onready var orange_texture = preload("res://art/Sprout Lands - Sprites - Basic pack/Characters/Basic Orange Spritesheet-export.png")

#The scripts for loading default values into the attack
var smash = preload("res://Scripts/Attacks/smash.gd")
var bolt = preload("res://Scripts/Attacks/bolt.gd")
#The list of attacks for playercharacter
var attacks = [attack.create_from_resource("res://Scenes/Attacks/smash.tscn",smash),attack.create_from_resource("res://Scenes/Attacks/bolt.tscn",bolt)]
var is_purple = true


signal attack_requested(new_attack : Attack, t_position : Vector2, t_direction : Vector2)
signal player_took_damage(damage : int, c_health : int, c_node : Node)

func _ready():
	update_animation_parameters(starting_direction)
	add_to_group("player")

	attacks[1].speed = 50
	attacks[1].lifespan = 10

func _physics_process(_delta):
	#Trap stuff
	var tile_pos = Vector2i(int(floor(global_position.x / 16)),int(floor(global_position.y / 16)))
	if tile_pos in get_parent().trap_cells:
		var tile_data = get_parent().return_trap_layer(tile_pos).get_cell_tile_data(tile_pos)
		if tile_data:
			var dmg = tile_data.get_custom_data("trap_instant")
			#Instant trap
			if dmg and !in_instant_trap:
				take_damage(dmg)
				in_instant_trap = true
			if !dmg:
				in_instant_trap = false
			#Ongoing trap
			if tile_data.get_custom_data("trap_ongoing"):
				current_dmg_time += _delta
				if current_dmg_time >= tile_data.get_custom_data("trap_ongoing_seconds"):
					current_dmg_time -= tile_data.get_custom_data("trap_ongoing_seconds")
					take_damage(tile_data.get_custom_data("trap_ongoing_dmg"))
			else:
				current_dmg_time = 0
		else:
			current_dmg_time = 0
			in_instant_trap = false
	else:
		current_dmg_time = 0
		in_instant_trap = false
		
	
	
	#Cat input detection
	var input_direction = Vector2(
		Input.get_action_strength("right") - Input.get_action_strength("left"),
		Input.get_action_strength("down") - Input.get_action_strength("up")
	)
	input_direction = input_direction.normalized()
	
	update_animation_parameters(input_direction)
	# Update velocity
	velocity = input_direction * move_speed		
	if Input.is_action_just_pressed("swap"):
		if(is_purple):
			is_purple = false
			sprite.texture = orange_texture
			crosshair_sprite.texture = orange_crosshair
		else:
			is_purple = true
			sprite.texture = purple_texture
			crosshair_sprite.texture = purple_crosshair
	
	if Input.is_action_just_pressed("attack"):
		if(is_purple):
			request_attack(attacks[0])
		else:
			request_attack(attacks[1])
	
	#move and slide function
	move_and_slide()
	
	pick_new_state()
	
func update_animation_parameters(move_input : Vector2):
	if(move_input != Vector2.ZERO):
		animation_tree.set("parameters/Walk/blend_position", move_input)
		animation_tree.set("parameters/Idle/blend_position", move_input)
		
		
		
func pick_new_state():
	if(velocity != Vector2.ZERO):
		state_machine.travel("Walk")
	else:
		state_machine.travel("Idle")

func request_attack(t_attack : Attack):
	var attack_direction = (crosshair.position).normalized()
	var attack_position = attack_direction * 20 + global_position
	emit_signal("attack_requested",t_attack, attack_position, attack_direction)

func take_damage(damage_amount : int):
	current_health = current_health - damage_amount
	emit_signal("player_took_damage",damage_amount,current_health,self)
