extends BTAction

@export var player_position_var: String = "target_pos"
@export var player_positions: String = "player_positions"
@export var player_idx: String = "player_idx"

func _tick(_delta: float) -> Status:
	# Find the player in the scene
	
#	can i write a conditional that checks if they player is agrod
#	if so, check which player that specific enemy is agrod on
#	this should not change. I just need to export this from my Check_agro function
#	
#	
	var players = agent.get_tree().get_nodes_in_group("player")
	
	if not players:
		push_error("No players found in 'player' group")
		return FAILURE
	
	# Store the player's position in the blackboard
	# blackboard.set_var(player_position_var, players[0].global_position)
	
	var positions_array = []
	
	for player in players: 
		positions_array.append(player.global_position)
		
	blackboard.set_var(player_positions, positions_array)
	
	
	if blackboard.get_var("state") == "agro":
		#print("does this ever actually happen")
		var player_agressing = blackboard.get_var(player_idx)
		blackboard.set_var(player_position_var, positions_array[player_agressing])
	
	return FAILURE
