extends CharacterBody2D
const is_elite: bool = false
@export var max_health: int = 10
var current_health: int = 10 

const SPEED: float = 100
@onready var sprite_2d: Sprite2D = $Sprite2D

# import like, takes damage or something like that

func on_ready():
	current_health = max_health
	

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
	if current_health <= 0:
		die()
		
