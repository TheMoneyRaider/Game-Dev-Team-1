extends CharacterBody2D
const is_elite: bool = false
var enemy_health: int = 10
var current_health: int = 10 

const SPEED: float = 100
@onready var sprite_2d: Sprite2D = $Sprite2D

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
	

signal takes_damage(damage_taken : int, e_health : int)

func take_damage(damage : int):
	enemy_health = current_health - damage
	emit_signal("takes_damage", damage, current_health)
	
