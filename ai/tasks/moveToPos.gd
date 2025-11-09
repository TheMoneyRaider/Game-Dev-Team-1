extends BTAction

"""
"blackbaord" is a "space" in a behavior tree that all branches can access
this is like declaring/setting a global variable named "pos" 

"agent" referes to the root node this BT is under, 
in our case the characterbody2d
"""
var recalculate_time: float = .5;
var last_recalc: float = 0.0;


func _tick(_delta: float) -> Status: 
	# takes the random pos determined b4 in "chooseRadnomPos, and moves to it, simple as 
	var path: Array = blackboard.get_var("path", [])
	var waypoint_index: int = blackboard.get_var("waypoint_index", 0)
	
	var current_time = Time.get_ticks_msec() / 1000.0
	if current_time - last_recalc >= recalculate_time: 
		last_recalc = current_time
		return SUCCESS
		
	if path.is_empty() or waypoint_index >= path.size():
		agent.velocity = Vector2.ZERO
		return FAILURE # failure forces tree to recalculate
		
	var target_pos: Vector2 = path[waypoint_index]
	var current_pos: Vector2 = agent.global_position
	
	# debug print
	# print("Target Pos: " + str(target_pos) + "Curent Pos: " + str(current_pos))
	
	# 
	if waypoint_index >= path.size():
		waypoint_index = 0
		blackboard.set_var("waypoint_index", waypoint_index)
	
	# check if we have reached the current waypoint
	if current_pos.distance_to(target_pos) <= 8.0:  
		waypoint_index += 1
		blackboard.set_var("waypoint_index", waypoint_index)
	
		#last waypoint reached
		if waypoint_index >= path.size():
			agent.velocity = Vector2.ZERO
			return SUCCESS
		return RUNNING
	
	agent.move(target_pos, _delta)
	return RUNNING
	
