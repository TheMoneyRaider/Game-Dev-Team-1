extends BTAction
const layer_manager_script = preload("res://Scripts/layer_manager.gd")

@export var target_position_var: String = "target_pos"
@export var path_output_var: String = "path"
@export var current_waypoint_var: String = "waypoint_index"
@export var recalculated_bool: String = "path_recalculated"

func _tick(_detla: float) -> Status:
	var start_time = Time.get_ticks_usec() 
	#retrieves the target pos and defaults it to zero vector if not found
	var target_pos: Vector2 = blackboard.get_var(target_position_var, Vector2.ZERO) 
	
	# checks for existence of target pos
	if target_pos == Vector2.ZERO: 
		return FAILURE
	
	# find layer manager based on script
	var layer_manager = null
	for node in agent.get_tree().root.get_children():
		if node.get_script() == layer_manager_script:
			layer_manager = node
			break
	
	if not layer_manager:
		push_error("Could not find LayerManager")
		return FAILURE
	
	var path = layer_manager.pathfinding.find_path(agent.global_position, target_pos) 
	
	if path.is_empty():
		return FAILURE
	
	path = path_smoothing(path)
	
	blackboard.set_var(path_output_var, path)
	blackboard.set_var(current_waypoint_var, 0)
	blackboard.set_var(recalculated_bool, true)
	
	var end_time = Time.get_ticks_usec()
	var duration_ms = (end_time - start_time) / 1000.0

	return SUCCESS
	

func path_smoothing(path: Array) -> Array:
	if path.size() <= 2:
		return path
	
	var smoothed = [path[0]]
	var i = 1
	
	while i < path.size() - 1:
		var start = smoothed[smoothed.size() - 1]
		var end_index = i + 1
		
		# Try to skip as many waypoints as possible while maintaining line of sight
		while end_index < path.size():
			# Check if we can go directly from start to end_index
			if can_skip_to(start, path[end_index], path, i, end_index):
				end_index += 1
			else:
				break
		
		# Add the furthest point we can reach
		smoothed.append(path[end_index - 1])
		i = end_index
	
	smoothed.append(path[path.size() - 1])
	return smoothed

func can_skip_to(start: Vector2, end: Vector2, path: Array, start_idx: int, end_idx: int) -> bool:
	# Simple check: if all intermediate points are close to the line, we can skip them
	for i in range(start_idx, end_idx):
		var point = path[i]
		var dist_to_line = distance_to_line(point, start, end)
		if dist_to_line > 8.0:  # More than half a tile off the line
			return false
	return true

func distance_to_line(point: Vector2, line_start: Vector2, line_end: Vector2) -> float:
	var line_vec = line_end - line_start
	var point_vec = point - line_start
	var line_len = line_vec.length()
	if line_len == 0:
		return point_vec.length()
	var proj = point_vec.dot(line_vec) / line_len
	proj = clamp(proj, 0, line_len)
	var closest = line_start + line_vec.normalized() * proj
	return point.distance_to(closest)
 
