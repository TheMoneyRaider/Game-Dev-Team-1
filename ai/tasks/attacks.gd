extends BTAction

func _tick(_delta: float) -> Status: 
	var player_pos = get_blackboard().get_var("target_pos")
	
	if not player_pos:
		return FAILURE
	
	agent.handle_attack(player_pos)
	
	return SUCCESS
