extends CharacterBody2D
const attack = preload("res://Scripts/attack.gd")

@export var move_speed: float = 100
@export var max_health: float = 10
@export var current_health: float = 10

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

var attacks = [attack.create_from_scene("res://Scenes/Attacks/smash.tscn"),attack.create_from_scene("res://Scenes/Attacks/bolt.tscn")]
var is_purple = true


signal attack_requested(new_attack : Attack, t_position : Vector2, t_direction : Vector2)
signal player_took_damage(damage : int, c_health : int, c_node : Node)

func _ready():
	update_animation_parameters(starting_direction)
	attacks[1].speed = 50
	attacks[1].lifespan = 10

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
