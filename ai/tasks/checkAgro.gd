extends BTAction
@export var player_position_var: String = "target_pos"
@export var player_positions: String = "player_positions"

# determines the distance at which and enemy can detect a player
var agro_distance = 150

func _tick(_delta: float) -> Status:
	agent = get_agent()
	
	var positions = get_blackboard().get_var(player_positions)
	
	## outdated code
	#var player_pos = get_blackboard().get_var(player_position_var)
	#
	
	# gets all distances squared between enemies and players 
	var distances_squared = []
	for pos in positions: 
		distances_squared.append(agent.global_position.distance_squared_to(pos))
	
	# outdated 
	#var distance_squared = agent.global_position.distance_squared_to(player_pos)
	
	if not distances_squared:
		return FAILURE
	
	# looks for either enemy, and checks if they are in range, sends that position if they are
	for i in range(distances_squared.size()): 
		if distances_squared[i] <= agro_distance * agro_distance: 
			get_blackboard().set_var(player_position_var, positions[i])
			
	# outdated
	#if distance_squared >=  deagro_distance * deagro_distance:
		#return FAILURE

	return SUCCESS
