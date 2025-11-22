extends BTAction
@export var player_position_var: String = "target_pos"

var agro_distance = 150

func _tick(delta: float) -> Status:
	agent = get_agent()
	
	var player_pos = get_blackboard().get_var(player_position_var)
	
	var distance_squared = agent.global_position.distance_squared_to(player_pos)
	
	if not player_pos:
		return FAILURE
	
	if distance_squared <= agro_distance * agro_distance:
		return SUCCESS

	return FAILURE
