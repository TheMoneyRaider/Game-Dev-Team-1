extends CharacterBody2D
const attack = preload("res://Scripts/attack.gd")

@export var move_speed: float = 100
@export var max_health: float = 10
@export var current_health: float = 10

@export var state_machine : LimboHSM

#States
@onready var idle_state = $LimboHSM/Idle
@onready var move_state = $LimboHSM/Move
@onready var attack_state = $LimboHSM/Attack
@onready var swap_state = $LimboHSM/Swap

@export var starting_direction : Vector2 =  Vector2(0,1)

#@onready var animation_tree = $AnimationTree
#@onready var state_machine = animation_tree.get("parameters/playback")
@onready var crosshair = $Crosshair
@onready var crosshair_sprite = $Crosshair/Sprite2D
@onready var sprite = $Sprite2D
@onready var purple_crosshair = preload("res://art/purple_crosshair.png")
@onready var orange_crosshair = preload("res://art/orange_crosshair.png")
@onready var purple_texture = preload("res://art/Sprout Lands - Sprites - Basic pack/Characters/Basic Purple Spritesheet-export.png")
@onready var orange_texture = preload("res://art/Sprout Lands - Sprites - Basic pack/Characters/Basic Orange Spritesheet-export.png")


var input_device = "0"
var input_direction : Vector2 = Vector2.ZERO

#The scripts for loading default values into the attack
var smash = preload("res://Scripts/Attacks/smash.gd")
var bolt = preload("res://Scripts/Attacks/bolt.gd")
#The list of attacks for playercharacter
var attacks = [attack.create_from_resource("res://Scenes/Attacks/smash.tscn",smash),attack.create_from_resource("res://Scenes/Attacks/bolt.tscn",bolt)]
var is_purple = true


signal attack_requested(new_attack : Attack, t_position : Vector2, t_direction : Vector2)
signal player_took_damage(damage : int, c_health : int, c_node : Node)

func _ready():
	_initialize_state_machine()
	update_animation_parameters(starting_direction)
	add_to_group("player")

func _initialize_state_machine():
	#Define State transitions
	state_machine.add_transition(idle_state,move_state, "to_move")
	state_machine.add_transition(move_state,idle_state, "to_idle")
	
	state_machine.initial_state = idle_state
	state_machine.initialize(self)
	state_machine.set_active(true)

func apply_movement(_delta):
	velocity = input_direction * move_speed

func _physics_process(_delta):
	#Cat input detection
	input_direction = Vector2(
		Input.get_action_strength("right_" + input_device) - Input.get_action_strength("left_" + input_device),
		Input.get_action_strength("down_" + input_device) - Input.get_action_strength("up_" + input_device)
	)
	input_direction = input_direction.normalized()
	
	update_animation_parameters(input_direction)
	# Update velocity
	#velocity = input_direction * move_speed		
	if Input.is_action_just_pressed("swap_" + input_device):
		if(is_purple):
			is_purple = false
			sprite.texture = orange_texture
			crosshair_sprite.texture = orange_crosshair
		else:
			is_purple = true
			sprite.texture = purple_texture
			crosshair_sprite.texture = purple_crosshair
	
	if Input.is_action_just_pressed("attack_" + input_device):
		if(is_purple):
			request_attack(attacks[0])
		else:
			request_attack(attacks[1])
	
	#move and slide function
	move_and_slide()
	

func update_animation_parameters(move_input : Vector2):
	if(move_input != Vector2.ZERO):
		idle_state.move_direction = move_input
		move_state.move_direction = move_input
		

func request_attack(t_attack : Attack):
	var attack_direction = (crosshair.position).normalized()
	var attack_position = attack_direction * 20 + global_position
	emit_signal("attack_requested",t_attack, attack_position, attack_direction)

func take_damage(damage_amount : int):
	current_health = current_health - damage_amount
	emit_signal("player_took_damage",damage_amount,current_health,self)
