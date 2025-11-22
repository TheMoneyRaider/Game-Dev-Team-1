extends BTAction
@export var player_position_var: String = "target_pos"
@export var player_positions: String = "player_positions"
@export var player_idx: String = "player_idx"
# determines the distance at which and enemy can detect a player
var agro_distance = 150

func _tick(_delta: float) -> Status:
	agent = get_agent()
	
	# get all player positions
	var positions = get_blackboard().get_var(player_positions)
	
	# gets all distances squared between enemies and players 
	var distances_squared = []
	for pos in positions: 
		distances_squared.append(agent.global_position.distance_squared_to(pos))
	
	# double check thos distances exist
	if not distances_squared:
		return FAILURE
	
	# looks for either enemy, and checks if they are in range, sends that position if they are
	for i in range(distances_squared.size()): 
		#print("checking index: ", i, 
		#"\nat position: ", positions[i], 
		#"\nwith distance: ", distances_squared[i],
		#"\nrequired distance: ", agro_distance * agro_distance);
		if distances_squared[i] <= agro_distance * agro_distance:
			blackboard.set_var(player_position_var, positions[i])
			blackboard.set_var(player_idx, i)
			return SUCCESS
			# pdate which index value the enemies should be acce`ssing
	
	return FAILURE
