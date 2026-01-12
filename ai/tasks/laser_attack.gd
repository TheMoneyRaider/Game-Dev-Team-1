extends BTAction

var started : bool = false
var valid : bool = true


func cast_axis_ray(origin: Vector2, direction: Vector2, distance: float) -> Dictionary:
	var space = agent.get_world_2d().direct_space_state
	var query = PhysicsRayQueryParameters2D.create(origin - direction, origin + direction * distance)
	query.collide_with_areas = false
	query.collide_with_bodies = true
	query.collision_mask = 1 << 0
	return space.intersect_ray(query)

#func place_marker(direction : Vector2):
	#var hit =cast_axis_ray(agent.global_position, direction, 1600)
	##print(hit)
	#if hit:
		#var instance = load("res://Game Elements/Objects/moving_target.tscn").instantiate()
		#instance.global_position = hit.position
		#instance.speed = 0
		#instance.range = 0
		#agent.get_parent().add_child(instance)
	#else:
		#print("Error at "+str(direction))


func start()->void:
	started = true
	var valid_X = false
	var valid_Y = false
	var check_right = cast_axis_ray(agent.global_position, Vector2.RIGHT, 1600)
	var check_left = cast_axis_ray(agent.global_position, Vector2.LEFT, 1600)
	var check_up = cast_axis_ray(agent.global_position, Vector2.UP, 1600)
	var check_down = cast_axis_ray(agent.global_position, Vector2.DOWN, 1600)
	
	##REMOVE UNVALID LOCATIONS THAT HAVE OTHER LASER SPOTS
	##
	if check_right and check_left:
		valid_X = true
	if check_up and check_down:
		valid_Y = true
	if !valid_X and !valid_Y:
		valid=false
		
	var choice = 0
		
	if valid_X and !valid_Y:
		choice = 1
	if !valid_X and valid_Y:
		choice = 2
	if choice ==0:
		randomize()
		choice = randi()%2+1
	var seg1 = agent.get_node("Segment1")
	var seg2 = agent.get_node("Segment2")
	match choice:
		0:
			pass
		1:
			seg1.global_position = check_right.position
			seg2.global_position = check_left.position
			seg1.rotation = deg_to_rad(90)
			seg2.rotation = deg_to_rad(-90)
			seg1.visible = true
			seg2.visible = true
		2:
			seg1.global_position = check_up.position
			seg2.global_position = check_down.position
			seg1.rotation = deg_to_rad(0)
			seg2.rotation = deg_to_rad(180)
			seg1.visible = true
			seg2.visible = true

func _tick(_delta: float) -> Status:
	if !started:
		start()
		valid=false
		if !valid:
			return FAILURE
	
	
	
	#var p_index = blackboard.get_var("player_idx")
	#var players = agent.get_tree().get_nodes_in_group("player")
	#var current_player_pos: Vector2 = players[p_index].global_position if players else Vector2.ZERO
	#var target_pos = blackboard.get_var("target_pos")
	#
	#agent.handle_attack(current_player_pos)
	
	return RUNNING

func finish(status: Status) -> void:
	started = false
	valid = true
