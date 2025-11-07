extends BTAction

@export var player_position_var: String = "target_pos"

func _tick(_delta: float) -> Status:
	# Find the player in the scene
	var player = agent.get_tree().get_first_node_in_group("player")
	
	if not player:
		push_error("No player found in 'player' group")
		return FAILURE
	
	# Store the player's position in the blackboard
	blackboard.set_var(player_position_var, player.global_position)
	
	return SUCCESS
