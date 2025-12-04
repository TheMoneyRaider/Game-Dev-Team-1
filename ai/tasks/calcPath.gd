extends BTAction
const layer_manager_script = preload("res://Game Elements/General Game/layer_manager.gd")

@export var target_position_var: String = "target_pos"
@export var path_output_var: String = "path"
@export var current_waypoint_var: String = "waypoint_index"
@export var recalculated_bool: String = "path_recalculated"

func _tick(_detla: float) -> Status:
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
	
	if path:
		path = layer_manager.pathfinding.smooth_path(path)
	
	blackboard.set_var(path_output_var, path)
	
	if path.is_empty():
		return FAILURE
	
	blackboard.set_var(path_output_var, path)
	blackboard.set_var(current_waypoint_var, 0)
	blackboard.set_var(recalculated_bool, true)

	return SUCCESS
	
