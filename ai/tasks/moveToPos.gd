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
	
	#UPDATE 
	# some mid ass clode that just recalculates every half second
	# this should be changed to some ranged base determiner
	# should be determined by the distance from the player of the last waypoint
	# we can keep the same path if the player isn't moving, 
	# but recalc if the player is a certain distance from that waypoint. not to hard a fix I think
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
	
	# saftey check for recaclulation of paths
	if waypoint_index >= path.size():
		waypoint_index = 0
		blackboard.set_var("waypoint_index", waypoint_index)
	
	if waypoint_index == 0:
		waypoint_index = skip_waypoints_behind(path, waypoint_index)
		blackboard.set_var("waypoint_index", waypoint_index)
	
	# check if we have reached the current waypoint
	# PROBLEMS 
	# enemies always move to the "next" waypoint, which may be behind them 
	# need logic so the enemy will choose the closest node
	# bool to indicate a recalculation 
	# only needs to be applied then
	if current_pos.distance_to(target_pos) <= 16.0:  
		waypoint_index += 1
		blackboard.set_var("waypoint_index", waypoint_index)
	
		#last waypoint reached
		if waypoint_index >= path.size():
			agent.velocity = Vector2.ZERO
			return SUCCESS
		return RUNNING
	
	agent.move(target_pos, _delta)
	return RUNNING
	
	
	
func skip_waypoints_behind(path: Array, start_index: int) -> int:
	if path.is_empty():
		return start_index
	
	var current_pos = agent.global_position
	var direction = agent.velocity.normalized()  # Current movement direction
	
	# If not moving, don't skip anything
	if direction.length() < 0.1:
		return start_index
	
	var index = start_index
	while index < path.size():
		var waypoint_pos: Vector2 = path[index]
		var to_waypoint = (waypoint_pos - current_pos).normalized()
		
		# Check if waypoint is in front of us (dot product > 0)
		var dot = direction.dot(to_waypoint)
		
		if dot > 0:  # Waypoint is in front
			return index
		
		# Waypoint is behind, skip it
		print("Skipping waypoint ", index, " (behind enemy)")
		index += 1
	
	# All waypoints behind? Start from the last one
	return path.size() - 1
