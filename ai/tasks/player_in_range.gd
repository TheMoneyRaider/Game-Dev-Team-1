extends BTAction

@export var player_position_var: String = "target_pos"

func _tick(_delta: float) -> Status:
#	
	var player_pos = get_blackboard().get_var(player_position_var)
	if !player_pos:
		return FAILURE
	if player_pos.distance_to(agent.global_position) <= agent.hit_range:
		return SUCCESS
	return FAILURE
