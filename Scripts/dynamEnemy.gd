extends CharacterBody2D

const SPEED: float = 15
@onready var sprite_2d: Sprite2D = $Sprite2D

func update_flip(dir: float): 
	sprite_2d.flip_h = dir < 0 


func move(target_pos: Vector2, _delta: float): 
	print("Move Called!")
	var direction = Vector2(
		target_pos.x - global_transform.origin.x,
		target_pos.y - global_transform.origin.y
	).normalized()
	
	velocity.x = direction.x * SPEED
	velocity.y = direction.y * SPEED
	
	update_flip(direction.x)
	
	move_and_slide()
	
	
