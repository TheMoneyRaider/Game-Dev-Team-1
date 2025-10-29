extends Node2D
const room = preload("res://Scripts/room.gd")
#the root node of each room MUST BE NAMED Root
#                                           scene_location                                            num_liquids    Liquid Types											                            Liquid Chances                     Num Fillings   Terrain Set                                       Terrain ID					 Threshold			  Noise Scale									Num_traps      Trap Chances                                   Num Exits            Exit Directions                             Num Entrances            Entrance Directions                                                                                                  Exit Types                                                                Enemy Spawnpoints     Enemy Num Goal         NPC Spawnpoints    Can Shop
@onready var cave_stage : Array[Room] = [room.Create_Room("res://Scenes/test_room1.tscn",                        4,            [room.Liquid.Water,room.Liquid.Water,room.Liquid.Water,room.Liquid.Water], [.75,.25,.75,.25],                     2,              [0,0],                                      [3,4],                       [.6,1.0],            Vector2i(10,10),                              3,              [.65,.65,.65],                                2,                   [room.Direction.Up,room.Direction.Up],     4,                   [room.Direction.Left,room.Direction.Down,room.Direction.Down,room.Direction.Right],                                     [room.Exit.Cave,room.Exit.Cave,room.Exit.Cave],                                          7,    5,                               0,   false),
										 room.Create_Room("res://Scenes/test_room2.tscn",                        2,            [room.Liquid.Water,room.Liquid.Water],                                    [.5,.5],                               2,              [0,0],                                      [4,3],                       [.6,1.0],            Vector2i(20,20),                              2,              [.75,.25],                                    2,                   [room.Direction.Up,room.Direction.Up],      3,                   [room.Direction.Left,room.Direction.Down,room.Direction.Right],                                                         [room.Exit.Cave,room.Exit.Cave],                                                         11,    8,                               0,   false)
										]
@onready var player = $PlayerCat
var current_room : Room
#A list of all the tile locations that have an additional tile on them(i.e liquids, traps, etc)
@onready var second_layer : Array[Vector2i] = []
var room_location : Resource 
var room_instance


func _ready() -> void:
	randomize()
	_choose_room()
	_place_exits()
	_place_liquids()
	_place_traps()
	_place_enemy_spawners()
	#cull NPC spawners
	#cull shop spawners
	_floor_noise()
	player.position = room_instance.get_node("PlayerSpawn").position
	
func _process(_delta: float) -> void:
	if(Input.is_action_just_pressed("Activate")):
		var direction = check_exits()
		if direction != -1:
			room_instance.queue_free()
			second_layer = []
			while find_child("Root") != null:
				pass
			_choose_room()
			# Randomize the entrance
			var L = 0
			var R = 0
			var D = 0
			for direct in current_room.entrance_direction:
				if direct == room.Direction.Down:
					D+=1
				if direct == room.Direction.Right:
					R+=1
				if direct == room.Direction.Left:
					L+=1
			var entrance
			match direction:
				room.Direction.Left:
					entrance = int(randf()*R)+1
					room_instance.get_node("EntranceR"+str(entrance)).queue_free()
					player.position = room_instance.get_node("EntranceR"+str(entrance)+"_Detect").position
				room.Direction.Right:
					entrance = int(randf()*L)+1
					room_instance.get_node("EntranceL"+str(entrance)).queue_free()
					player.position = room_instance.get_node("EntranceL"+str(entrance)+"_Detect").position
				room.Direction.Up:
					entrance = int(randf()*D)+1
					room_instance.get_node("EntranceD"+str(entrance)).queue_free()
					player.position = room_instance.get_node("EntranceD"+str(entrance)+"_Detect").position
			L = 0
			R = 0
			D = 0
			for j in current_room.entrance_direction:
				match j:
					room.Direction.Left:
						L+=1
						if room_instance.get_node("EntranceL"+str(L)):
							second_layer+=room_instance.get_node("EntranceL"+str(L)).get_used_cells()
					room.Direction.Right:
						R+=1
						if room_instance.get_node("EntranceR"+str(R)):
							second_layer+=room_instance.get_node("EntranceR"+str(R)).get_used_cells()
					room.Direction.Down:
						D+=1
						if room_instance.get_node("EntranceD"+str(D)):
							second_layer+=room_instance.get_node("EntranceD"+str(D)).get_used_cells()
			_place_exits()
			_place_liquids()
			_place_traps()
			_place_enemy_spawners()
			#cull NPC spawners
			#cull shop spawners
			_floor_noise()
				
					
				
	
func check_exits() -> int:
	var targets_extents: Array = []
	var targets_position: Array = []
	for idx in range(1,current_room.num_exits+1):
		targets_extents.append(room_instance.get_node("Exit"+str(idx)+"_Detect/CollisionShape2D").shape.extents)
		targets_position.append(room_instance.get_node("Exit"+str(idx)+"_Detect/CollisionShape2D").global_position)
		
	var player_shape = player.get_node("CollisionShape2D").shape
	var player_position = player.global_position
	var player_rect = player_shape.extents
	
	for idx in range(0,current_room.num_exits):
		var area_rect = targets_extents[idx]

		if abs(player_position.x -  targets_position[idx].x) <= player_rect.x + area_rect.x \
			and abs(player_position.y - targets_position[idx].y) <= player_rect.y + area_rect.y:
			return current_room.exit_direction[idx]
	return -1
	
func _choose_room() -> void:
	#Shuffle rooms and load one
	#cave_stage.shuffle()       Undo comment #TODO
	current_room=cave_stage[0]
	
	room_location = load(current_room.scene_location)
	room_instance = room_location.instantiate()
	add_child(room_instance)

func _place_exits() -> void:
	#Choose which exits to keep
	var exit_num = 0
	#Open at least one exit
	var curr_exit = int(randf()*current_room.num_exits)+1
	room_instance.get_node("Exit"+str(curr_exit)).queue_free()
	print("Opened ",curr_exit)
	while exit_num < current_room.num_exits:
		exit_num+=1
		#Add intelligent exit choosing later. Also remember removing the node is OPENING the exit. #TODO
		if room_instance.get_node("Exit"+str(exit_num)):
			if randf() > .5:
				room_instance.get_node("Exit"+str(exit_num)).queue_free()
			else:
				second_layer+=room_instance.get_node("Exit"+str(exit_num)).get_used_cells()

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
		if room_instance.get_node("Enemy"+str(curr_en)):
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
	
