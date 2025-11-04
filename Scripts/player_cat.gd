extends CharacterBody2D
const attack = preload("res://Scripts/attack.gd")

@export var move_speed: float = 100
@export var max_health: float = 100
@export var current_health: float = 100

@export var starting_direction : Vector2 =  Vector2(0,1)

@onready var animation_tree = $AnimationTree
@onready var state_machine = animation_tree.get("parameters/playback")
@onready var crosshair = $Crosshair

var attack_scene : String = "res://Scenes/Attacks/smash.tscn"
var is_purple = true


signal attack_requested(new_attack : Attack)

func _ready():
	update_animation_parameters(starting_direction)

func _physics_process(_delta):
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
			attack_scene = "res://Scenes/Attacks/bolt.tscn"
		else:
			is_purple = true
			attack_scene = "res://Scenes/Attacks/smash.tscn"
	
	if Input.is_action_just_pressed("attack"):
		if(is_purple):
			request_attack(attack_scene)
		else:
			request_attack(attack_scene,false,50,2,10)
	
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

func request_attack(t_attack_scene : String, use_defaults = true,attack_speed : float = 0, damage : int = 0, lifespan : float = 0):
	var attack_direction = (crosshair.position).normalized()
	var attack_position = attack_direction * 20 + global_position
	var new_attack
	if use_defaults == true:
		new_attack = attack.create_attack(t_attack_scene,attack_direction,attack_position)
	else:
		new_attack = attack.create_attack(t_attack_scene,attack_direction,attack_position,false,attack_speed,damage,lifespan)
	emit_signal("attack_requested",new_attack)
