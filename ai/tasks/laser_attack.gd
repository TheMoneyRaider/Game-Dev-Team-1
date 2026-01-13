extends BTAction

var started : bool = false
var laser_out : bool = false
var valid : bool = true
var time : float = 0.0
var opening_time : float =1.0
var closing_time : float =1.0
var total_time : float =3.0

func cast_axis_ray(origin: Vector2, direction: Vector2, distance: float) -> Dictionary:
	var space = agent.get_world_2d().direct_space_state
	var query = PhysicsRayQueryParameters2D.create(origin - direction, origin + direction * distance)
	query.collide_with_areas = false
	query.collide_with_bodies = true
	query.collision_mask = 1 << 0
	return space.intersect_ray(query)


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
		2:
			seg1.global_position = check_up.position
			seg2.global_position = check_down.position
			seg1.rotation = deg_to_rad(0)
			seg2.rotation = deg_to_rad(180)

func _tick(delta: float) -> Status:
	time+=delta
	if !started:
		start()
		if !valid:
			return proc_finish(FAILURE)
	var seg1 = agent.get_node("Segment1")
	var seg2 = agent.get_node("Segment2")
	if time < opening_time:
		seg1.modulate.a = lerp(0,1,time)
		seg2.modulate.a = lerp(0,1,time)
	elif !laser_out and time < total_time-closing_time-agent.get_node("LaserBeam").decay_time:
		agent.get_node("LaserBeam").fire_laser(seg1.position,seg2.position)
		laser_out =true
	#if laser_out and time >= total_time-closing_time-agent.get_node("LaserBeam").decay_time:
		#agent.get_node("LaserBeam").stop_laser()
		#laser_out =false
	#if time > total_time-closing_time:
		#seg1.modulate.a = lerp(1,0,(time-total_time+closing_time)/closing_time)
		#seg2.modulate.a = lerp(1,0,(time-total_time+closing_time)/closing_time)
	#if time >= total_time:
		#seg1.global_position = Vector2(1000,1000)
		#seg2.global_position = Vector2(1000,1000)
		#return proc_finish(SUCCESS)
		
	
	
	
	#var p_index = blackboard.get_var("player_idx")
	#var players = agent.get_tree().get_nodes_in_group("player")
	#var current_player_pos: Vector2 = players[p_index].global_position if players else Vector2.ZERO
	#var target_pos = blackboard.get_var("target_pos")
	#
	#agent.handle_attack(current_player_pos)
	
	return RUNNING

func proc_finish(status: Status) -> Status:
	started = false
	laser_out = false
	valid = true
	time = 0.0
	return status
