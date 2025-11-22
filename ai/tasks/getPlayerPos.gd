extends BTAction

@export var player_position_var: String = "target_pos"

func _tick(_delta: float) -> Status:
	# Find the player in the scene
	var players = agent.get_tree().get_nodes_in_group("player")
	
	if not players:
		push_error("No players found in 'player' group")
		return FAILURE
	
	# Store the player's position in the blackboard
	blackboard.set_var(player_position_var, players[0].global_position)
	
	if players.size() != 1:
		print("Multiplayer")
	
	return FAILURE
