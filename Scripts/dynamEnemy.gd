extends CharacterBody2D
const is_elite: bool = false
@export var max_health: int = 10
var current_health: int = 10 

const SPEED: float = 50
@onready var sprite_2d: Sprite2D = $Sprite2D

const attack = preload("res://Scripts/attack.gd")
var bad_bolt = preload("res://Scripts/Attacks/bad_bolt.gd")
var attacks = [attack.create_from_resource("res://Scenes/Attacks/bad_bolt.tscn", bad_bolt)]
signal attack_requested(new_attack : Attack, t_position : Vector2, t_direction : Vector2)

signal enemy_took_damage(damage : int,current_health : int,c_node : Node)
func handle_attack(target_position: Vector2):
	var attack_direction = (target_position - global_position).normalized()
	var attack_position = attack_direction * 20 + global_position
	request_attack(attacks[0], attack_position, attack_direction)

func request_attack(t_attack: Attack, attack_position: Vector2, attack_direction: Vector2):
	emit_signal("attack_requested", t_attack, attack_position, attack_direction)
# import like, takes damage or something like that

func _ready():
	current_health = max_health
	add_to_group("enemy")

func update_flip(dir: float): 
	sprite_2d.flip_h = dir < 0 

func move(target_pos: Vector2, _delta: float): 
	
	var direction = (target_pos - global_position).normalized()
	
	var target_velocity = direction * SPEED
	velocity = velocity.lerp(target_velocity, 0.05)
	
	update_flip(direction.x)
	
	move_and_slide()
	
func _process(_delta):
	queue_redraw()

func die():
	queue_free()

func take_damage(damage : int):
	current_health = current_health - damage
	emit_signal("enemy_took_damage",damage,current_health,self)
	if current_health <= 0:
		die()
		
