extends BTAction

"""
"blackbaord" is a "space" in a behavior tree that all branches can access
this is like declaring/setting a global variable named "pos" 

"agent" referes to the root node this BT is under, 
in our case the characterbody2d
"""
const recalc_distance_threshold: float = 48.0
@export var player_idx: String = "player_idx"

func _tick(_delta: float) -> Status: 
	# takes the random pos determined b4 in "chooseRadnomPos, and moves to it, simple as 
	
	var path: Array = blackboard.get_var("path", [])
	var waypoint_index: int = blackboard.get_var("waypoint_index", 0)
	var path_target_pos: Vector2 = blackboard.get_var("target_pos", Vector2.ZERO)

	var p_index = blackboard.get_var(player_idx)
	var players = agent.get_tree().get_nodes_in_group("player")
	var current_player_pos: Vector2 = players[p_index].global_position if players else Vector2.ZERO

	if blackboard.get_var("path_recalculated", false):	
		waypoint_index = skip_waypoints_behind(path, 0)
		blackboard.set_var("waypoint_index", waypoint_index)
		blackboard.set_var("path_recalculated", false)
			
	if current_player_pos != Vector2.ZERO and path_target_pos != Vector2.ZERO:
		var player_moved_distance = path_target_pos.distance_to(current_player_pos)
		
		if player_moved_distance > recalc_distance_threshold:
			#print("Player moved", player_moved_distance)
			return SUCCESS
			
		#if int(Time.get_ticks_msec()) % 1000 < 16:  # Print roughly once per second
			#print("Player moved ", player_moved_distance, "px (threshold: ", recalc_distance_threshold, ")")
	
	#if not path.is_empty() and target_pos_player != Vector2.ZERO:
		#var last_waypoint: Vector2 = path[path.size() - 1]
		#var player_moved_distance = last_waypoint.distance_to(target_pos_player)
		#
		#if player_moved_distance > recalc_distance_threshold:
			#print("player moved too far, recalc path")
			#return SUCCESS
	
	if path.is_empty():
		
		print("FAILED")
		return FAILURE
	
	if waypoint_index >= path.size():

		print("FAILED")
		return SUCCESS # failure forces tree to recalculate
		
	var target_pos: Vector2 = path[waypoint_index]
	var current_pos: Vector2 = agent.global_position
	
	if current_pos.distance_to(target_pos) <= 32.0:  
		waypoint_index += 1
		blackboard.set_var("waypoint_index", waypoint_index)
	
		#last waypoint reached
		if waypoint_index >= path.size():

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
		index += 1
	
	# All waypoints behind? Start from the last one
	return max(0, path.size() - 1)
