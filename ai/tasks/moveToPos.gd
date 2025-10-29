extends BTAction

"""
"blackbaord" is a "space" in a behavior tree that all branches can access
this is like declaring/setting a global variable named "pos" 

"agent" referes to the root node this BT is under, 
in our case the characterbody2d
"""

func _tick(_delta: float) -> Status: 
	var target_pos: Vector2 = blackboard.get_var("pos")
	var current_pos: Vector2 = agent.global_position
	
	print("Target Pos: " + str(target_pos) + "Curent Pos: " + str(current_pos))
	
	if Vector2(current_pos.x, current_pos.y).distance_to(Vector2(target_pos.x, target_pos.y)) <= .5: 
		agent.velocity = Vector2.ZERO
		return SUCCESS
	
	agent.move(target_pos, _delta)
	return RUNNING
	
