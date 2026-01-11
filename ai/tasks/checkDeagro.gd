extends BTAction
@export var player_position_var: String = "target_pos"
@export var deagro_distance: String = "deagro_dist"


func _tick(_delta: float) -> Status:
	agent = get_agent()
	
	var player_pos = get_blackboard().get_var(player_position_var)
	
	var distance_squared = agent.global_position.distance_squared_to(player_pos)
	
	
	if not player_pos:
		return FAILURE
	
	var deagro_dist = get_blackboard().get_var(deagro_distance)
	if distance_squared <= deagro_dist * deagro_dist:
		blackboard.set_var("state", "idle")
		return SUCCESS
		
	return FAILURE
