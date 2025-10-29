extends BTAction

func _tick(_delta: float) -> Status: 
	var pos: Vector2 = agent.global_position
	
	var x: = randf_range(-15.0, 15.0)
	var y: = randf_range(-15.0, 15.0)
	
	if x < 0:
		x += - 10
	else: 
		x += 10
	
	if y < 0:
		y += -10
	else:
		y += 10
		
	pos += Vector2(x,y)
	
	
	print("Player Pos: " + str(agent.global_transform.origin) + "Random Pos: " + str(pos))
	
	blackboard.set_var("pos", pos)
	
	return SUCCESS

"""
make it so it stays in/returns to it's "spawn bubble" at some point 
"""
