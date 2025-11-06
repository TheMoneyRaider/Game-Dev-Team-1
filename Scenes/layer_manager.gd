extends Node2D
const room = preload("res://Scripts/room.gd")
const Pathfinding = preload("res://Scripts/pathfinding.gd")
#the root node MUST BE NAMED Root
#                                           scene_location                                            num_liquids    Liquid Types											                            Liquid Chances                     Num Fillings   Terrain Set                                       Terrain ID					 Threshold			  Noise Scale									Num_traps      Trap Chances                                   Num Exits            Exit Directions                                                                                      Exit Types                                                                Enemy Spawnpoints  NPC Spawnpoints    Can Shop
@onready var cave_stage : Array[Room] = [room.Create_Room("res://Scenes/medival_cave_room_test.tscn",           4,            [room.Liquid.Water,room.Liquid.Water,room.Liquid.Water,room.Liquid.Water], [.75,.25,.75,.25],                     2,              [0,0],                                      [3,4],                       [.6,1.0],            Vector2i(10,10),                              3,              [.65,.65,.65],                                3,                   [room.Direction.Left,room.Direction.Up,room.Direction.Up],                                           [room.Exit.Cave,room.Exit.Cave,room.Exit.Cave],                                          0,              0,   false),
										 room.Create_Room("res://Scenes/medival_cave_room_test2.tscn",           2,            [room.Liquid.Water,room.Liquid.Water],                                    [.5,.5],                               2,              [0,0],                                      [4,3],                       [.6,1.0],            Vector2i(20,20),                              2,              [.75,.25],                                    2,                   [room.Direction.Up,room.Direction.Up],                                                               [room.Exit.Cave,room.Exit.Cave],                                                         0,              0,   false)
										]
@onready var player = $PlayerCat
var current_room : Room
#A list of all the tile locations that have an additional tile on them(i.e liquids, traps, etc)
@onready var second_layer : Array[Vector2i] = []
var room_location : Resource 
var room_instance
var pathfinding: Pathfinding

func _ready() -> void:
	add_to_group("layer_manager")
	pathfinding = Pathfinding.new()
	add_child(pathfinding)
	
	randomize()
	_choose_room()
	_place_exits()
	_place_liquids()
	_place_traps()
	#cull enemy spawners
	#cull NPC spawners
	#cull shop spawners
	_floor_noise()
	
func _process(_delta: float) -> void:
	if(Input.is_action_just_pressed("Activate")):
		room_instance.queue_free()
		second_layer = []
		while find_child("Root") != null:
			pass
		_choose_room()
		_place_exits()
		_place_liquids()
		_place_traps()
		#cull enemy spawners
		#cull NPC spawners
		#cull shop spawners
		_floor_noise()
	
	
	
func _choose_room() -> void:
	#Shuffle rooms and load one
	cave_stage.shuffle()
	current_room=cave_stage[0]
	
	room_location = load(current_room.scene_location)
	room_instance = room_location.instantiate()
	add_child(room_instance)
	#temporary remove this when you dynamically choose the player's entrance #TODO
	player.position = room_instance.get_node("PlayerSpawn").position

func _place_exits() -> void:
	#Choose which exits to keep
	var exit_num = 0
	while exit_num < current_room.num_exits:
		exit_num+=1
		#Add intellgient exit choosing later. Also remember removing the node is OPENING the exit. #TODO
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
				
				
func _floor_noise() -> void:
	#If there's no noise fillings, don't do the work
	if(current_room.num_fillings==0):
		pass
	room_instance.noise.seed = randi()
	var noise_val : float
	var cells : Array[Vector2i] = room_instance.get_node("Ground").get_used_cells()
	var cell_count = cells.size()+1
	#Create the output terrain arrays
	var terrains = []
	terrains.resize(cell_count*current_room.num_fillings);
	for i in range(current_room.num_fillings):
		terrains[i]=Array()
		terrains[i].resize(cell_count)
		for j in range(cell_count):
			terrains[i][j]=Vector2i(-1,-1)
	var itr : int = 1
	#For each cell of the floor, check which terrain it should display and update the appropriate element in the appropriate terrain array
	for cell in cells:
		noise_val = (room_instance.noise.get_noise_2d((cell.x)*current_room.noise_scale.x,(cell.y)*current_room.noise_scale.y)+1)/2
		for i in range(current_room.num_fillings):
			if i == 0:
				if noise_val < current_room.fillings_terrain_threshold[i]:
					terrains[i][itr]=Vector2i(cell.x,cell.y)
			elif noise_val < current_room.fillings_terrain_threshold[i] and noise_val >= current_room.fillings_terrain_threshold[i-1]:
					terrains[i][itr]=Vector2i(cell.x,cell.y)
		itr+=1
	#update the tilemaplayer with all the terrain layers
	for i in range(current_room.num_fillings):
		terrains[i].filter(func(vector) : return vector != Vector2i(-1,-1))
		room_instance.get_node("Ground").set_cells_terrain_connect(terrains[i], current_room.fillings_terrain_set[i], current_room.fillings_terrain_id[i], true)



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
	
