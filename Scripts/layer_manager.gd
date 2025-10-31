extends Node2D
const room = preload("res://Scripts/room.gd")
const room_data = preload("res://Scripts/room_data.gd")
@onready var cave_stage : Array[Room] = room_data.new().rooms
@onready var player = $PlayerCat
var current_room : Room
#A list of all the tile locations that have an additional tile on them(i.e liquids, traps, etc)
@onready var second_layer : Array[Vector2i] = []
var room_location : Resource 
var room_instance
#The total time of this run
var time_passed := 0.0
@export var water_cells := []
@export var lava_cells := []
@export var acid_cells := []
@export var blocked_cells := []

#
@export var layer_ai := [
	0,#Rooms cleared
	0,#Combat rooms cleared
	0,#Time spent in last room
	0,#Time spent in game
	0,#Time spent in combat
	0,#Damage dealt   				#TODO
	0,#Attacks made
	0,#Enemies defeated   			#TODO
	0,#Shops visited
	0,#Liquid rooms visited
	0,#Trap rooms visited
	0,#Damage taken   				#TODO
	0,#Elite enemies defeated   	#TODO
	0,#Currency collected   		#TODO
	0,#Items picked up   			#TODO
	]


func _ready() -> void:
	randomize()
	_choose_room()
	_choose_pathways(room.Direction.Up)
	_place_liquids()
	_place_traps()
	_place_enemy_spawners()
	#cull NPC spawners
	#cull shop spawners
	_floor_noise()
	_calculate_cell_arrays()
	player.attack_requested.connect(_on_player_attack)
func _process(delta: float) -> void:
	time_passed += delta
	if(Input.is_action_just_pressed("Activate")):
		var direction = check_pathways()
		if direction != -1:
			_update_ai_array()
			room_instance.queue_free()
			second_layer = []
			while find_child("Root") != null:
				pass
			_choose_room()
			# Randomize the pathway
			_choose_pathways(direction)
			_place_liquids()
			_place_traps()
			_place_enemy_spawners()
			#cull NPC spawners
			#cull shop spawners
			_floor_noise()
			_calculate_cell_arrays()
				
					
				
func _update_ai_array() -> void:
	#Rooms cleared
	layer_ai[0] += 1
	#Combat rooms cleared
	if !current_room.has_shop:
		layer_ai[1] += 1
	#Last room time
	layer_ai[2] = time_passed - layer_ai[3]
	#Total time
	layer_ai[3] = time_passed
	if current_room.has_shop:
		layer_ai[7] += 1
	else:
		layer_ai[4] += layer_ai[2]   #Change to actually only check time when enemies were active   TODO
	if current_room.num_liquid > 0:
		var liquid_num = 0
		var liquid_type : String
		while liquid_num < current_room.num_liquid:
			liquid_num+=1
			liquid_type= _get_liquid_string(current_room.liquid_types[liquid_num-1])
			if room_instance.get_node_or_null(liquid_type+str(liquid_num)):
				layer_ai[9] += 1   #Liquid room
				break
	if current_room.num_trap > 0:
		var trap_num = 0
		while trap_num < current_room.num_trap:
			trap_num+=1
			if room_instance.get_node_or_null("Trap"+str(trap_num)):
				layer_ai[10] += 1   #Trap room
				break

	print(layer_ai)


func check_pathways() -> int:
	var targets_extents: Array = []
	var targets_position: Array = []
	var targets_id: Array = []
	var L = 0
	var R = 0
	var D = 0
	var U = 0
	for p_direct in current_room.pathway_direction:
		match p_direct:
			room.Direction.Left:
				L+=1
				if room_instance.get_node_or_null("PathwayL"+str(L)+"_Detect"):
					targets_extents.append(room_instance.get_node("PathwayL"+str(L)+"_Detect/Area2D/CollisionShape2D").shape.extents)
					targets_position.append(room_instance.get_node("PathwayL"+str(L)+"_Detect/Area2D/CollisionShape2D").global_position)
					targets_id.append("PathwayL"+str(L)+"_Detect")
			room.Direction.Right:
				R+=1
				if room_instance.get_node_or_null("PathwayR"+str(R)+"_Detect"):
					targets_extents.append(room_instance.get_node("PathwayR"+str(R)+"_Detect/Area2D/CollisionShape2D").shape.extents)
					targets_position.append(room_instance.get_node("PathwayR"+str(R)+"_Detect/Area2D/CollisionShape2D").global_position)
					targets_id.append("PathwayR"+str(R)+"_Detect")
			room.Direction.Down:
				D+=1
				if room_instance.get_node_or_null("PathwayD"+str(D)+"_Detect"):
					targets_extents.append(room_instance.get_node("PathwayD"+str(D)+"_Detect/Area2D/CollisionShape2D").shape.extents)
					targets_position.append(room_instance.get_node("PathwayD"+str(D)+"_Detect/Area2D/CollisionShape2D").global_position)
					targets_id.append("PathwayD"+str(D)+"_Detect")
			room.Direction.Up:
				U+=1
				if room_instance.get_node_or_null("PathwayU"+str(U)+"_Detect"):
					targets_extents.append(room_instance.get_node("PathwayU"+str(U)+"_Detect/Area2D/CollisionShape2D").shape.extents)
					targets_position.append(room_instance.get_node("PathwayU"+str(U)+"_Detect/Area2D/CollisionShape2D").global_position)
					targets_id.append("PathwayU"+str(U)+"_Detect")

	var player_shape = player.get_node("CollisionShape2D").shape
	var player_position = player.global_position
	var player_rect = player_shape.extents
	
	for idx in range(0,len(targets_extents)):
		var area_rect = targets_extents[idx]
		if abs(player_position.x -  targets_position[idx].x) <= player_rect.x + area_rect.x \
			and abs(player_position.y - targets_position[idx].y) <= player_rect.y + area_rect.y:
			if !room_instance.get_node(targets_id[idx]).used:
				return current_room.pathway_direction[idx]
	return -1
	
func _choose_room() -> void:
	#Shuffle rooms and load one
	cave_stage.shuffle()
	current_room=cave_stage[0]
	
	room_location = load(current_room.scene_location)
	room_instance = room_location.instantiate()
	add_child(room_instance)

func _choose_pathways(direction) -> void:
	# Place required pathway(where the player(s) is entering		
	var L = 0
	var R = 0
	var D = 0
	var U = 0
	for direct in current_room.pathway_direction:
		if direct == room.Direction.Down:
			D+=1
		if direct == room.Direction.Right:
			R+=1
		if direct == room.Direction.Left:
			L+=1
		if direct == room.Direction.Up:
			U+=1
	var pathway
	match direction:
		room.Direction.Left:
			pathway = int(randf()*R)+1
			_open_pathway("PathwayR"+str(pathway))
			player.position = room_instance.get_node("PathwayR"+str(pathway)+"_Detect").position
			room_instance.get_node("PathwayR"+str(pathway)+"_Detect").used = true
		room.Direction.Right:
			pathway = int(randf()*L)+1
			_open_pathway("PathwayL"+str(pathway))
			player.position = room_instance.get_node("PathwayL"+str(pathway)+"_Detect").position
			room_instance.get_node("PathwayL"+str(pathway)+"_Detect").used = true
		room.Direction.Up:
			pathway = int(randf()*D)+1
			_open_pathway("PathwayD"+str(pathway))
			player.position = room_instance.get_node("PathwayD"+str(pathway)+"_Detect").position
			room_instance.get_node("PathwayD"+str(pathway)+"_Detect").used = true
		room.Direction.Down:
			pathway = int(randf()*U)+1
			_open_pathway("PathwayU"+str(pathway))
			player.position = room_instance.get_node("PathwayU"+str(pathway)+"_Detect").position
			room_instance.get_node("PathwayU"+str(pathway)+"_Detect").used = true
	#Open a random pathway
	var dir = current_room.pathway_direction[int(randf()*current_room.num_pathways)]
	var offset = 0
	if dir == current_room.invert_direction(direction):
		match direction:
			room.Direction.Left:
				if L > 1:
					while true:
						if room_instance.get_node_or_null("PathwayL"+str(offset+1)):
							_open_pathway("PathwayL"+str(offset+1))
							break
						offset+=1
				else:
					_open_random_pathway_in_direction(room.Direction.Right, L, R, D, U)
			room.Direction.Right:
				if R > 1:
					while true:
						if room_instance.get_node_or_null("PathwayR"+str(offset+1)):
							_open_pathway("PathwayR"+str(offset+1))
							break
						offset+=1
				else:
					_open_random_pathway_in_direction(room.Direction.Down, L, R, D, U)
			room.Direction.Down:
				if D > 1:
					while true:
						if room_instance.get_node_or_null("PathwayD"+str(offset+1)):
							_open_pathway("PathwayD"+str(offset+1))
							break
						offset+=1
				else:
					_open_random_pathway_in_direction(room.Direction.Up, L, R, D, U)
			room.Direction.Up:
				if U > 1:
					while true:
						if room_instance.get_node_or_null("PathwayU"+str(offset+1)):
							_open_pathway("PathwayU"+str(offset+1))
							break
						offset+=1
				else:
					_open_random_pathway_in_direction(room.Direction.Left, L, R, D, U)
	else:
		#Open at least one pathway in the given direction
		_open_random_pathway_in_direction(dir, L, R, D, U)
	#Choose which pathways to keep      #add intelligent pathway choosing #TODO
	_open_random_pathways()
	

func _place_liquids() -> void:
	#For each liquid check if you should place it and then check if there's room
	var liquid_num = 0
	var cells : Array[Vector2i]
	var liquid_type : String
	var rand : float
	while liquid_num < current_room.num_liquid:
		liquid_num+=1
		liquid_type= _get_liquid_string(current_room.liquid_types[liquid_num-1])
		rand = randf()
		if rand > current_room.liquid_chances[liquid_num-1]:
			room_instance.get_node(liquid_type+str(liquid_num)).queue_free()
		else:
			cells = room_instance.get_node(liquid_type+str(liquid_num)).get_used_cells()
			if(_arrays_intersect(cells, second_layer)):
				room_instance.get_node(liquid_type+str(liquid_num)).queue_free()
				#DEBUG
				print("DEBUG: Layer collision removed")
			else:
				second_layer+=cells


func _place_traps() -> void:
	#For each trap check if you should place it and then check if there's room
	var trap_num = 0
	var cells : Array[Vector2i]
	while trap_num < current_room.num_trap:
		trap_num+=1
		if randf() > current_room.trap_chances[trap_num-1]:
			room_instance.get_node("Trap"+str(trap_num)).queue_free()
		else:
			cells = room_instance.get_node("Trap"+str(trap_num)).get_used_cells()
			if(_arrays_intersect(cells, second_layer)):
				room_instance.get_node("Trap"+str(trap_num)).queue_free()
				#DEBUG
				print("DEBUG: Layer collision removed")
			else:
				second_layer+=cells

func _place_enemy_spawners() -> void:
	#For each enemy check if there's room
	var enemy_num = 0
	while enemy_num < current_room.num_enemy_spawnpoints:
		enemy_num+=1
		var cell =  Vector2i(floor(room_instance.get_node("Enemy"+str(enemy_num)).position.x / 16), floor(room_instance.get_node("Enemy"+str(enemy_num)).position.y / 16))

		if cell in second_layer:
			room_instance.get_node("Enemy"+str(enemy_num)).queue_free()
			#DEBUG
			print("DEBUG: Layer collision removed")
	while enemy_num > current_room.num_enemy_goal:
		var curr_en = int(randf()*current_room.num_enemy_spawnpoints)+1
		if room_instance.get_node_or_null("Enemy"+str(curr_en)):
			room_instance.get_node("Enemy"+str(curr_en)).queue_free()
			print("DEBUG: Deleted enemy")
			enemy_num-=1
			
		
				
func _floor_noise() -> void:
	#If there's no noise fillings, don't do the work
	if(current_room.num_fillings==0):
		return
	var ground = room_instance.get_node("Ground")
	var noise = room_instance.noise
	noise.seed = randi()
	#Initialize variables
	var scale_x = current_room.noise_scale.x
	var scale_y = current_room.noise_scale.y
	var thresholds = current_room.fillings_terrain_threshold
	var num_fillings = current_room.num_fillings
	#Create the output terrain array
	var terrains := []
	terrains.resize(num_fillings)
	for i in range(num_fillings):
		terrains[i] = []

	var cells = ground.get_used_cells()
	#Create Noise
	for cell in cells:
		var noise_val = (noise.get_noise_2d(cell.x * scale_x, cell.y * scale_y) + 1.0) * 0.5
		for i in range(num_fillings):
			if noise_val < thresholds[i]:
				terrains[i].append(cell)
				break
	#Connect tiles			
	for i in range(num_fillings):
		ground.set_cells_terrain_connect(terrains[i],current_room.fillings_terrain_set[i],current_room.fillings_terrain_id[i],true)
func _calculate_cell_arrays() -> void:
	blocked_cells = []
	water_cells = []
	lava_cells = []
	acid_cells = []
	blocked_cells.append(room_instance.get_node("Walls").get_used_cells())
	blocked_cells.append(room_instance.get_node("Filling").get_used_cells())
	var types = [0,0,0,0,0]
	for liquid in current_room.liquid_types:
		types[liquid] +=1
		match liquid:
			room.Liquid.Water:
				water_cells +=room_instance.get_node("Water"+str(types[liquid])).get_used_cells()
			room.Liquid.Lava:
				water_cells +=room_instance.get_node("Lava"+str(types[liquid])).get_used_cells()
			room.Liquid.Acid:
				water_cells +=room_instance.get_node("Acid"+str(types[liquid])).get_used_cells()

#Helper Functions

func _arrays_intersect(array1 : Array[Vector2i], array2 : Array[Vector2i]) -> bool:
	var array2_dictionary = {}
	for vector in array2:
		array2_dictionary[vector] = true
	for vector in array1:
		if array2_dictionary.get(vector, false):
			return true
	return false
	
func _get_liquid_string(liquid : room.Liquid) -> String:
	match liquid:
		room.Liquid.Water:
			return "Water"
		room.Liquid.Lava:
			return "Lava"
		room.Liquid.Acid:
			return "Acid"
	return ""
	
func _open_pathway(input : String) -> void:
	print("DEBUG: Opened "+input)
	room_instance.get_node(input).queue_free()

func _open_random_pathway_in_direction(dir : room.Direction, L : int, R : int, D : int, U : int) -> void:
	match dir:
		room.Direction.Left:
			_open_pathway("PathwayL"+str(int(randf()*L)+1))
		room.Direction.Right:
			_open_pathway("PathwayR"+str(int(randf()*R)+1))
		room.Direction.Down:
			_open_pathway("PathwayD"+str(int(randf()*D)+1))
		room.Direction.Up:
			_open_pathway("PathwayU"+str(int(randf()*U)+1))

func _open_random_pathways() -> void:
	var L = 0
	var R = 0
	var D = 0
	var U = 0
	for p_direct in current_room.pathway_direction:
		match p_direct:
			room.Direction.Left:
				L+=1
				if room_instance.get_node_or_null("PathwayL"+str(L)):
					if randf() > .5:
						_open_pathway("PathwayL"+str(L))
					else:
						second_layer+=room_instance.get_node("PathwayL"+str(L)).get_used_cells()
			room.Direction.Right:
				R+=1
				if room_instance.get_node_or_null("PathwayR"+str(R)):
					if randf() > .5:
						_open_pathway("PathwayR"+str(R))
					else:
						second_layer+=room_instance.get_node("PathwayR"+str(R)).get_used_cells()
			room.Direction.Down:
				D+=1
				if room_instance.get_node_or_null("PathwayD"+str(D)):
					if randf() > .5:
						_open_pathway("PathwayD"+str(D))
					else:
						second_layer+=room_instance.get_node("PathwayD"+str(D)).get_used_cells()
			room.Direction.Up:
				U+=1
				if room_instance.get_node_or_null("PathwayU"+str(U)):
					if randf() > .5:
						_open_pathway("PathwayU"+str(U))
					else:
						second_layer+=room_instance.get_node("PathwayU"+str(U)).get_used_cells()
func _on_player_attack(_new_attack : Attack) -> void:
	layer_ai[6]+=1
