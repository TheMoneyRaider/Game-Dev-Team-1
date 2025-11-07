extends BTAction

@export var target_position_var: String = "target_pos"
@export var path_output_var: String = "path"
@export var current_waypoint_var: String = "waypoint_index"


func _tick(_detla: float) -> Status:
	#retrieves the target pos and defaults it to zero vector if not found
	var target_pos: Vector2 = blackboard.get_var(target_position_var, Vector2.ZERO) 
	
	# checks for existence of target pos
	if target_pos == Vector2.ZERO: 
		return FAILURE
	
	# learn what the hell this means 
	var layer_man = agent.get_tree().get_first_node_in_group("layer_manager")
	if not layer_man or not layer_man.pathfinding:
		push_error("No pathfinding system found")
		return FAILURE
	
	var path = layer_man.find_path(agent.global_position, target_pos)
	
	if path.is_empty():
		print("No path found")
		return FAILURE
	
	blackboard.set_var(path_output_var, path)
	blackboard.set_var(current_waypoint_var, 0)
	
	print("Path calculated with ", path.size(), " waypoints")
	
	return SUCCESS
	
	
