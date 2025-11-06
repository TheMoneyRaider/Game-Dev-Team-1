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
	
	
func _draw(): 
	if has_node("BTPlayer"):
		var bt = get_node("BTPlayer")
		var path = bt.blackboard.get_var("path", [])
		
		if path.size() > 1: 
			for i in range(path.size() - 1):
				var start = to_local(path[i])
				var end = to_local(path[i + 1])
				draw_line(start, end, Color.YELLOW, 2.0)
			
			for waypoint in path:
				draw_circle(to_local(waypoint), 4, Color.RED)
			
func _process(_delta):
	queue_redraw()
