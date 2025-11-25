extends Node2D
const room = preload("res://Scripts/room.gd")
const room_data = preload("res://Scripts/room_data.gd")
@onready var cave_stage : Array[Room] = room_data.new().rooms
### Temp Multiplayer Fix
var player
var player_2
###

var room_instance_data : Room
var generated_rooms : = {}
var generated_room_metadata : = {}
var generated_room_entrance : = {}
var pending_room_creations: Array = []
var terrain_update_queue: Array = []
#Thread Stuff
var room_gen_thread: Thread
var thread_result: Dictionary
var thread_running := false

#A list of all the tile locations that have an additional tile on them(i.e liquids, traps, etc)
@onready var pathfinding = Pathfinding.new()

@onready var camera = $Camera2D

#Cached scenes to speed up room loading at runtime
@onready var cached_scenes := {}
var room_location : Resource 
var room_instance
var remnant_offer_popup
#The total time of this run
var time_passed := 0.0
@export var water_cells := []
@export var lava_cells := []
@export var acid_cells := []
@export var trap_cells := []
@export var blocked_cells := []
@export var is_multiplayer = Globals.is_multiplayer
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
	var conflict_cells : Array[Vector2i]
	var player_scene = load("res://Scenes/Characters/player_cat.tscn")
	#Needs integration with main_menu
	if(is_multiplayer):
		var player1 = player_scene.instantiate()
		player1.is_multiplayer = true
		player1.input_device = "key"
		var player2 = player_scene.instantiate()
		player2.is_multiplayer = true
		player2.input_device = "0"
		player1.other_player = player2
		player2.other_player = player1
		add_child(player1)
		add_child(player2)
		player2.swap_color()
		#Temp Multiplayer Fix
		player = player1
		player_2 = player2
	else:
		var player1 = player_scene.instantiate()
		player1.is_multiplayer = false
		player1.input_device = "key"
		add_child(player1)
		player = player1
	
	add_child(pathfinding)
	preload_rooms()
	player.attack_requested.connect(_on_player_attack)
	randomize()
	choose_room()
	choose_pathways(room.Direction.Up,room_instance, room_instance_data, conflict_cells)
	player.global_position =  generated_room_entrance[room_instance.name]
	if(is_multiplayer):
		player_2.global_position =  generated_room_entrance[room_instance.name]
		player_2.global_position += Vector2(16,0)
		player.global_position -= Vector2(16,0)
	place_liquids(room_instance, room_instance_data,conflict_cells)
	place_traps(room_instance, room_instance_data,conflict_cells)
	place_enemy_spawners(room_instance, room_instance_data,conflict_cells)
	floor_noise_sync(room_instance, room_instance_data)
	calculate_cell_arrays(room_instance, room_instance_data)
	water_cells = room_instance.water_cells
	lava_cells = room_instance.lava_cells
	acid_cells = room_instance.acid_cells
	trap_cells = room_instance.trap_cells
	blocked_cells = room_instance.blocked_cells
	create_new_rooms()
	print("Room children: ")
	var root = get_tree().root
	for child in root.get_children():
		print("  - ", child.name, " (", child.get_class(), ")")
	pathfinding.setup_from_room(room_instance.get_node("Ground"), room_instance.blocked_cells)

func _process(delta: float) -> void:
	time_passed += delta
	#Pathway Travel Check
	#Temp Multiplayer Fix (It only gets activate from keyboard player)
	if Input.is_action_just_pressed("activate_key") and room_instance:
		var direction = check_pathways(room_instance, room_instance_data)
		if direction != -1:
			create_new_rooms()
	
	if is_multiplayer:
		camera.global_position = (player.global_position + player_2.global_position) / 2
	else:
		camera.position = player.global_position
	
	# Thread check
	if thread_running and not room_gen_thread.is_alive():
		thread_result = room_gen_thread.wait_to_finish()
		room_gen_thread = null
		thread_running = false
		_on_thread_finished(thread_result)

	# Process pending room creation gradually
	if !(pending_room_creations.size() == 0):
		_create_room_step()
		
	# Process queued terrain updates (spread across frames)
	if terrain_update_queue.size() > 0:
		_process_terrain_batch()
				
		
	if Input.is_action_just_pressed("get_remnant") and room_instance and !remnant_offer_popup:
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		var offer_scene = load("res://ui/remnant_offer.tscn")
		remnant_offer_popup = offer_scene.instantiate()
		$CanvasLayer.add_child(remnant_offer_popup)
		remnant_offer_popup.remnant_chosen.connect(_on_remnant_chosen)
		remnant_offer_popup.popup_offer()

func create_new_rooms() -> void:
	if thread_running:
		return
	# Free previous background rooms
	for gen_room in generated_rooms.values():
		if is_instance_valid(gen_room):
			gen_room.queue_free()
	generated_rooms.clear()
	generated_room_metadata.clear()

	# Start async generation thread
	thread_running = true
	room_gen_thread = Thread.new()
	room_gen_thread.start(_thread_generate_rooms.bind(cave_stage, room_instance_data))

func update_ai_array(generated_room : Node2D, generated_room_data : Room) -> void:
	#Rooms cleared
	layer_ai[0] += 1
	#Combat rooms cleared
	if !generated_room_data.has_shop:
		layer_ai[1] += 1
	#Last room time
	layer_ai[2] = time_passed - layer_ai[3]
	#Total time
	layer_ai[3] = time_passed
	if generated_room_data.has_shop:
		layer_ai[8] += 1
	else:
		layer_ai[4] += layer_ai[2]   #Change to actually only check time when enemies were active   TODO
	if generated_room_data.num_liquid > 0:
		var liquid_num = 0
		var liquid_type : String
		while liquid_num < generated_room_data.num_liquid:
			liquid_num+=1
			liquid_type= _get_liquid_string(generated_room_data.liquid_types[liquid_num-1])
			if if_node_exists(liquid_type+str(liquid_num),generated_room):
				layer_ai[9] += 1   #Liquid room
				break
	if generated_room_data.num_trap > 0:
		var trap_num = 0
		while trap_num < generated_room_data.num_trap:
			trap_num+=1
			if if_node_exists("Trap"+str(trap_num),generated_room):
				layer_ai[10] += 1   #Trap room
				break

	print(layer_ai)

func check_pathways(generated_room : Node2D, generated_room_data : Room) -> int:
	var targets_extents: Array = []
	var targets_position: Array = []
	var targets_id: Array = []
	var targets_direction: Array = []
	var pathway_name= ""
	var direction_count = [0,0,0,0]
	for p_direct in generated_room_data.pathway_direction:
		direction_count[p_direct]+=1
		pathway_name = _get_pathway_name(p_direct,direction_count[p_direct])
		if not if_node_exists(pathway_name,generated_room):
			var pathway_detect = generated_room.get_node_or_null(pathway_name+"_Detect/Area2D/CollisionShape2D")
			if pathway_detect:
				targets_extents.append(pathway_detect.shape.extents)
				targets_position.append(pathway_detect.global_position)
				targets_id.append(pathway_name+"_Detect")
				targets_direction.append(p_direct)

	var player_shape = player.get_node("CollisionShape2D").shape
	var player_position = player.global_position
	var player_rect = player_shape.extents
	for idx in range(0,len(targets_extents)):
		var area_rect = targets_extents[idx]
		if abs(player_position.x - targets_position[idx].x) <= player_rect.x + area_rect.x \
			and abs(player_position.y - targets_position[idx].y) <= player_rect.y + area_rect.y:
			var target_id = targets_id[idx]
			if !generated_room.get_node(target_id).used:
				_move_to_pathway_room(targets_id[idx])
				return targets_direction[idx]
	return -1

func choose_room() -> void:
	#Shuffle rooms and load one
	room_instance_data = cave_stage[randi() % cave_stage.size()]
	
	room_location = load(room_instance_data.scene_location)
	room_instance = room_location.instantiate()
	add_child(room_instance)

func choose_pathways(direction : int, generated_room : Node2D, generated_room_data : Room, conflict_cells : Array[Vector2i]) -> Array[Vector2i]:
	# Place required pathway(where the player(s) is entering		
	var direction_count = [0,0,0,0]
	for p_direct in generated_room_data.pathway_direction:
		direction_count[p_direct]+=1
	var pathway_name
	#Invert player direction so they come out the opposite side of a pathway
	direction = generated_room_data.invert_direction(direction)
	
	pathway_name = _get_pathway_name(direction,int(randf()*direction_count[direction])+1)
	_open_pathway(pathway_name, generated_room)
	#Save the new player spawn to an array
	generated_room_entrance[generated_room.name] = generated_room.get_node(pathway_name+"_Detect").global_position
	generated_room.get_node(pathway_name+"_Detect").used = true
	#Open a random pathway
	var dir = generated_room_data.pathway_direction[int(randf()*generated_room_data.num_pathways)]
	var offset = 0
	#END OF REMOVE
	if dir == direction:
		if direction_count[direction] > 1:
			while true:
				pathway_name = _get_pathway_name(direction,offset+1)
				if if_node_exists(pathway_name,generated_room):
					_open_pathway(pathway_name, generated_room)
					break
				offset+=1
		else:
			if direction == 3:
				conflict_cells = _open_random_pathway_in_direction(Room.Direction.Up,direction_count, generated_room,conflict_cells)
			else:
				conflict_cells = _open_random_pathway_in_direction(direction+1,direction_count, generated_room,conflict_cells)
	else:
		#Open at least one pathway in the given direction
		conflict_cells = _open_random_pathway_in_direction(dir, direction_count, generated_room,conflict_cells)
	#Choose which pathways to keep      #add intelligent pathway choosing #TODO
	conflict_cells = _open_random_pathways(generated_room, generated_room_data, conflict_cells)
	return conflict_cells

func place_liquids(generated_room : Node2D, generated_room_data : Room, conflict_cells : Array[Vector2i]) -> Array[Vector2i]:
	#For each liquid check if you should place it and then check if there's room
	var liquid_num = 0
	var cells : Array[Vector2i]
	var liquid_type : String
	var rand : float
	while liquid_num < generated_room_data.num_liquid:
		liquid_num+=1
		liquid_type= _get_liquid_string(generated_room_data.liquid_types[liquid_num-1])
		rand = randf()
		if rand > generated_room_data.liquid_chances[liquid_num-1]:
			generated_room.get_node(liquid_type+str(liquid_num)).queue_free()
		else:
			cells = generated_room.get_node(liquid_type+str(liquid_num)).get_used_cells()
			if(_arrays_intersect(cells, conflict_cells)):
				generated_room.get_node(liquid_type+str(liquid_num)).queue_free()
				#DEBUG
				_debug_message("Layer collision removed")
			else:
				conflict_cells+=cells
	return conflict_cells

func place_traps(generated_room : Node2D, generated_room_data : Room, conflict_cells : Array[Vector2i]) -> Array[Vector2i]:
	#For each trap check if you should place it and then check if there's room
	var trap_num = 0
	var cells : Array[Vector2i]
	while trap_num < generated_room_data.num_trap:
		trap_num+=1
		if randf() > generated_room_data.trap_chances[trap_num-1]:
			generated_room.get_node("Trap"+str(trap_num)).queue_free()
		else:
			cells = generated_room.get_node("Trap"+str(trap_num)).get_used_cells()
			if(_arrays_intersect(cells, conflict_cells)):
				generated_room.get_node("Trap"+str(trap_num)).queue_free()
				#DEBUG
				_debug_message("Deleted Trap")
			else:
				conflict_cells+=cells
				_debug_message("Added Trap")
				if(generated_room_data.trap_types[trap_num-1]!=room.Trap.Tile):
					_add_trap(generated_room, generated_room_data, trap_num)
	return conflict_cells

func place_enemy_spawners(generated_room : Node2D, generated_room_data : Room, conflict_cells : Array[Vector2i]) -> void:
	#For each enemy check if there's room
	var enemy_num = 0
	while enemy_num < generated_room_data.num_enemy_spawnpoints:
		enemy_num+=1
		var cell =  Vector2i(floor(generated_room.get_node("Enemy"+str(enemy_num)).position.x / 16), floor(generated_room.get_node("Enemy"+str(enemy_num)).position.y / 16))

		if cell in conflict_cells:
			generated_room.get_node("Enemy"+str(enemy_num)).queue_free()
			#DEBUG
			_debug_message("Layer collision removed")
	while enemy_num > generated_room_data.num_enemy_goal:
		var curr_en = int(randf()*generated_room_data.num_enemy_spawnpoints)+1
		if if_node_exists("Enemy"+str(curr_en),generated_room):
			generated_room.get_node("Enemy"+str(curr_en)).queue_free()
			_debug_message("Deleted enemy")
			enemy_num-=1
	# Temporary Enemey creation   UPDATE TODO
	enemy_num = 0
	while enemy_num < generated_room_data.num_enemy_spawnpoints:
		enemy_num+=1
		if if_node_exists("Enemy"+str(enemy_num),generated_room):
			var enemy = load("res://Scenes/Characters/dynamEnemy.tscn").instantiate()
			enemy.position = generated_room.get_node("Enemy"+str(enemy_num)).position
			generated_room.get_node("Enemy"+str(enemy_num)).queue_free()
			generated_room.add_child(enemy)
			
func floor_noise_sync(generated_room : Node2D, generated_room_data : Room) -> void:
	#If there's no noise fillings, don't do the work
	if(generated_room_data.num_fillings==0):
		return
	var ground = generated_room.get_node("Ground")
	var noise = generated_room_data.noise
	#Initialize variables
	var thresholds = generated_room_data.fillings_terrain_threshold
	var num_fillings = generated_room_data.num_fillings
	#Create the output terrain array
	var terrains := []
	terrains.resize(num_fillings)
	for i in range(num_fillings):
		terrains[i] = []

	var cells = ground.get_used_cells()
	#Create Noise
	for cell in cells:
		var noise_val = (noise.get_noise_2d(cell.x,cell.y) + 1.0) * 0.5
		for i in range(num_fillings):
			if noise_val < thresholds[i]:
				terrains[i].append(cell)
				break
	#Connect tiles			
	for i in range(num_fillings):
		ground.set_cells_terrain_connect(terrains[i],generated_room_data.fillings_terrain_set[i],generated_room_data.fillings_terrain_id[i],true)

func floor_noise_threaded(generated_room: Node2D, generated_room_data: Room) -> void:
	if generated_room_data.num_fillings == 0:
		return

	var ground = generated_room.get_node("Ground")
	var cells = ground.get_used_cells()

	# Start thread
	var result_thread = Thread.new()
	var noise_result: Dictionary
	var thread_finished := false

	result_thread.start(
		func() -> Dictionary:
			return _compute_floor_noise_threaded(generated_room_data, cells)
	)

	# Wait for the thread to finish
	while not thread_finished:
		OS.delay_msec(1)

	noise_result = result_thread.wait_to_finish()
	result_thread = null

	# Assign terrains in batch (single TileMap API call per terrain)
	for i in range(generated_room_data.num_fillings):
		ground.set_cells_terrain_connect(
			noise_result["terrains"][i],
			generated_room_data.fillings_terrain_set[i],
			generated_room_data.fillings_terrain_id[i],
			true
	)

func calculate_cell_arrays(generated_room : Node2D, generated_room_data : Room) -> void:
	generated_room.blocked_cells += generated_room.get_node("Walls").get_used_cells()
	generated_room.blocked_cells += generated_room.get_node("Filling").get_used_cells()
	var types = [0,0,0,0,0]
	for liquid in generated_room_data.liquid_types:
		types[liquid] +=1
		match liquid:
			room.Liquid.Water:
				if if_node_exists("Water"+str(types[liquid]),generated_room):
					generated_room.water_cells += generated_room.get_node("Water"+str(types[liquid])).get_used_cells()
			room.Liquid.Lava:
				if if_node_exists("Lava"+str(types[liquid]),generated_room):
					generated_room.lava_cells += generated_room.get_node("Lava"+str(types[liquid])).get_used_cells()
			room.Liquid.Acid:
				if if_node_exists("Acid"+str(types[liquid]),generated_room):
					generated_room.acid_cells += generated_room.get_node("Acid"+str(types[liquid])).get_used_cells()
	var curr_trap = 0
	while curr_trap < generated_room_data.num_trap:
		curr_trap+=1
		if if_node_exists("Trap"+str(curr_trap),generated_room):
			generated_room.trap_cells += generated_room.get_node("Trap"+str(curr_trap)).get_used_cells()
	#Add blocked cells for an covers still existing
	var direction_count = [0,0,0,0]
	var pathway_name = ""
	for p_direct in generated_room_data.pathway_direction:
		direction_count[p_direct]+=1
		pathway_name = _get_pathway_name(p_direct,direction_count[p_direct])
		if if_node_exists(pathway_name,generated_room):
			generated_room.blocked_cells += generated_room.get_node(pathway_name).get_used_cells()
	generated_room.blocked_cells = _remove_duplicates(generated_room.blocked_cells) #remove duplicates

func preload_rooms() -> void:
	for room_data_item in cave_stage:
		if not cached_scenes.has(room_data_item.scene_location):
			var packed = ResourceLoader.load(room_data_item.scene_location, "PackedScene")
			cached_scenes[room_data_item.scene_location] = packed

#Thread functions

func _thread_generate_rooms(room_data_array: Array, room_instance_data_sent: Room) -> Dictionary:
	var result := {}
	var direction_count = [0,0,0,0]
	
	for direction in room_instance_data_sent.pathway_direction:
		direction_count[direction] += 1
		var pathway_name = _get_pathway_name(direction, direction_count[direction])
		# Only precompute data. No scene calls
		var chosen_index = randi() % room_data_array.size()
		var next_room_data = room_data_array[chosen_index]
		result[pathway_name] = {
			"pathway": pathway_name,
			"direction": direction,
			"chosen_index": chosen_index,
			"scene_path": next_room_data.scene_location,
			"room_data": next_room_data
		}
	return result

func _on_thread_finished(data: Dictionary) -> void:
	for pathway_name in data.keys():
		pending_room_creations.append(data[pathway_name])

func _create_room_step() -> void:
	if pending_room_creations.is_empty():
		return
	
	var info = pending_room_creations.pop_front()
	
	var pathway_name = info["pathway"]
	var direction = info["direction"]
	var next_room_data = info["room_data"]
	var scene_path = info["scene_path"]
	
	if if_node_exists(pathway_name, room_instance):
		return
	if not room_instance.has_node(pathway_name + "_Detect"):
		return

	var pathway_detect = room_instance.get_node(pathway_name + "_Detect")
	if pathway_detect.used:
		return
	
	# use a preloaded scene
	var packed_scene: PackedScene = cached_scenes[scene_path]
	var next_room_instance = packed_scene.instantiate()
	next_room_instance.name = pathway_name
	next_room_instance.visible = false
	next_room_instance.process_mode = Node.PROCESS_MODE_DISABLED
	add_child(next_room_instance)
	
	# defer the more computationally heavy code
	call_deferred("_finalize_room_creation", next_room_instance, next_room_data, direction, pathway_detect)
	await get_tree().process_frame

func _exit_tree() -> void:
	if thread_running and room_gen_thread.is_alive():
		room_gen_thread.wait_to_finish()

func _compute_floor_noise_threaded(generated_room_data: Room, cells: Array) -> Dictionary:
	#Initialize variables
	var noise = generated_room_data.noise
	var thresholds = generated_room_data.fillings_terrain_threshold
	var num_fillings = generated_room_data.num_fillings
	
	#Create the output terrain array
	var terrains := []
	terrains.resize(num_fillings)
	for i in range(num_fillings):
		terrains[i] = []

	#Create Noise
	for cell in cells:
		var noise_val = (noise.get_noise_2d(int(cell.x),int(cell.y)) + 1.0) * 0.5
		for i in range(num_fillings):
			if noise_val < thresholds[i]:
				terrains[i].append(cell)
				break
	return {"terrains": terrains}

func _apply_floor_noise_async(next_room_instance: Node2D, next_room_data: Room, thread: Thread) -> void:
	var terrains_dict = thread.wait_to_finish()
	thread = null
	_start_apply_floor_noise_batched(next_room_instance, next_room_data, terrains_dict)

func _start_apply_floor_noise_batched(generated_room: Node2D, generated_room_data: Room, terrains_dict: Dictionary, batch_size: int = 100) -> void:
	var ground = generated_room.get_node("Ground")
	for i in range(generated_room_data.num_fillings):
		var terrain_cells = terrains_dict["terrains"][i]
		if terrain_cells.is_empty():
			continue
		# Split into segments
		for j in range(0, terrain_cells.size(), batch_size):
			var sub_array = terrain_cells.slice(j, j + batch_size)
			terrain_update_queue.append({
				"ground": ground,
				"cells": sub_array,
				"terrain_set": generated_room_data.fillings_terrain_set[i],
				"terrain_id": generated_room_data.fillings_terrain_id[i],
			})

func _process_terrain_batch() -> void:
	if terrain_update_queue.is_empty():
		return
	
	# Apply one segment per frame
	var entry = terrain_update_queue.pop_front()
	if is_instance_valid(entry["ground"]):
		entry["ground"].set_cells_terrain_connect(
			entry["cells"],
			entry["terrain_set"],
			entry["terrain_id"],
			true
		)

#Helper Functions

func _add_trap(generated_room: Node2D, generated_room_data: Room, trap_num: int) -> void:
	var cells = generated_room.get_node("Trap"+str(trap_num)).get_used_cells()
	var type = generated_room_data.trap_types[trap_num-1]
	for cell in cells:
		match type:
			room.Trap.Spike:
				var spike = load("res://Scenes/Objects/spike_trap.tscn").instantiate()
				spike.position = generated_room.get_node("Trap"+str(trap_num)).map_to_local(cell)
				generated_room.add_child(spike)
				
				
func return_trap_layer(tile_pos : Vector2i) -> TileMapLayer:
	for trap_num in range(1,room_instance_data.num_trap+1):
		if if_node_exists(("Trap"+str(trap_num)), room_instance):
			if tile_pos in room_instance.get_node("Trap"+str(trap_num)).get_used_cells():
				return room_instance.get_node("Trap"+str(trap_num))
	return null

func _finalize_room_creation(next_room_instance: Node2D, next_room_data: Room, direction: int, pathway_detect: Node) -> void:
	
	var conflict_cells : Array[Vector2i]
	conflict_cells = choose_pathways(direction, next_room_instance, next_room_data, conflict_cells)
	conflict_cells = place_liquids(next_room_instance, next_room_data, conflict_cells)
	conflict_cells = place_traps(next_room_instance, next_room_data, conflict_cells)
	place_enemy_spawners(next_room_instance, next_room_data, conflict_cells)
	
	# Async floor noise
	var ground = next_room_instance.get_node("Ground")
	var cells = ground.get_used_cells()

	var thread := Thread.new()
	thread.start(
		func() -> Dictionary:
			return _compute_floor_noise_threaded(next_room_data, cells)
	)

	# Defer the TileMap assignment to avoid blocking
	call_deferred("_apply_floor_noise_async", next_room_instance, next_room_data, thread)
	
	calculate_cell_arrays(next_room_instance, next_room_data)
	_set_tilemaplayer_collisions(next_room_instance, false)

	generated_room_metadata[pathway_detect.name] = next_room_data
	generated_rooms[pathway_detect.name] = next_room_instance
	
func _move_to_pathway_room(pathway_id: String) -> void:
	if not generated_rooms.has(pathway_id):
		push_warning("No linked room for pathway " + pathway_id)
		return
	var next_room_data = generated_room_metadata[pathway_id]
	var next_room = generated_rooms[pathway_id]
	if not is_instance_valid(next_room):
		push_warning("Linked room instance invalid for " + pathway_id)
		return
	
	# Teleport player to the entrance of the next room
	player.global_position =  generated_room_entrance[next_room.name]
	#Temp Multiplayer Fix
	if(is_multiplayer):
		player_2.global_position = generated_room_entrance[next_room.name]
	
	# Delete all other generated rooms
	for key in generated_rooms.keys():
		if key != pathway_id and is_instance_valid(generated_rooms[key]):
			generated_rooms[key].queue_free()
	generated_rooms.clear()
	generated_room_metadata.clear()
	
	# Delete the current room
	if is_instance_valid(room_instance):
		room_instance.queue_free()

	#Update algorithm statistics before data is overwriten
	update_ai_array(room_instance, room_instance_data)
	
	# Activate the chosen room
	next_room.visible = true
	next_room.process_mode = Node.PROCESS_MODE_INHERIT
	room_instance = next_room
	
	room_instance.name = "Root"
	# Enable Collisions
	_set_tilemaplayer_collisions(room_instance, true)
	

	# Assign a new generated_room_data definition for metadata
	room_instance_data = next_room_data

	# Update layers and other arrays
	water_cells = room_instance.water_cells
	lava_cells = room_instance.lava_cells
	acid_cells = room_instance.acid_cells
	trap_cells = room_instance.trap_cells
	blocked_cells = room_instance.blocked_cells
	pathfinding.setup_from_room(room_instance.get_node("Ground"), room_instance.blocked_cells)

func _set_tilemaplayer_collisions(generated_room: Node2D, enable: bool) -> void:
	for child in generated_room.get_children():
		if child is TileMapLayer:
			child.enabled = enable

func _get_pathway_name(direction: int, index: int) -> String:
	match direction:
		room.Direction.Up: 
			return "PathwayU" + str(index)
		room.Direction.Down: 
			return "PathwayD" + str(index)
		room.Direction.Left: 
			return "PathwayL" + str(index)
		room.Direction.Right: 
			return "PathwayR" + str(index)
	push_warning("Invalid pathway direction: " + str(direction))
	return ""

func _remove_duplicates(arr: Array) -> Array:
	var s := {}
	for element in arr:
		s[element] = true
	return s.keys()

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
	
func _open_pathway(input : String,generated_room : Node2D) -> void:
	_debug_message("Opened "+input+" In this room: "+generated_room.name)
	generated_room.get_node(input).queue_free()
	
func if_node_exists(input : String,generated_room : Node2D) -> bool:
	if generated_room.get_node_or_null(input):
		return !generated_room.get_node(input).is_queued_for_deletion()
	else:
		return false

func _open_random_pathway_in_direction(dir : room.Direction, direction_count : Array,generated_room : Node2D, conflict_cells : Array[Vector2i]) -> Array[Vector2i]:
	var pathway_name = _get_pathway_name(dir,int(randf()*direction_count[dir])+1)
	conflict_cells+=generated_room.get_node(pathway_name).get_used_cells()
	_open_pathway(pathway_name, generated_room)
	return conflict_cells

func _open_random_pathways(generated_room : Node2D, generated_room_data : Room, conflict_cells : Array[Vector2i]) -> Array[Vector2i]:
	var direction_count = [0,0,0,0]
	var pathway_name = ""
	for p_direct in generated_room_data.pathway_direction:
		direction_count[p_direct]+=1
		pathway_name = _get_pathway_name(p_direct,direction_count[p_direct])
		if if_node_exists(pathway_name,generated_room):
			if randf() > .5:
				_open_pathway(pathway_name, generated_room)
			else:
				_open_pathway(pathway_name+"_Detect", generated_room)
				conflict_cells+=generated_room.get_node(pathway_name).get_used_cells()
	return conflict_cells
			
func _on_player_attack(_new_attack : Attack, _attack_position : Vector2, _attack_direction : Vector2) -> void:
	layer_ai[6]+=1

func _on_remnant_chosen(remnant : Resource):
	player.add_remnant(remnant)
	remnant_offer_popup.queue_free()
	Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)
	

func _debug_message(msg : String) -> void:
	print("DEBUG: "+msg)
	return
