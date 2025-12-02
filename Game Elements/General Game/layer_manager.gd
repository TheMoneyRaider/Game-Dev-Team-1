extends Node2D
const room = preload("res://Game Elements/Rooms/room.gd")
const room_data = preload("res://Game Elements/Rooms/room_data.gd")
@onready var timefabric = preload("res://Game Elements/Objects/time_fabric.tscn")
@onready var cave_stage : Array[Room] = room_data.new().rooms
enum Reward {TimeFabric, Remnant, RemnantUpgrade}
### Temp Multiplayer Fix
var player = null
var player_2 = null
###
@onready var room_cleared: bool = false
@onready var reward_claimed: bool = false
@onready var timefabric_masks: Array[Array]
@onready var timefabric_sizes: Array[Vector3i]
@onready var timefabric_collected: int = 0
@onready var timefabric_rewarded = 0

@onready var player_1_remnants: Array[Remnant] = []
@onready var player_2_remnants: Array[Remnant] = []
var room_instance_data : Room
var generated_rooms : = {}
var generated_room_metadata : = {}
var generated_room_entrance : = {}
var this_room_reward = Reward.Remnant

#Thread Stuff
var pending_room_creations: Array = []
var terrain_update_queue: Array = []
var room_gen_thread: Thread
var thread_result: Dictionary
var thread_running := false

#A list of all the tile locations that have an additional tile on them(i.e liquids, traps, etc)
@onready var pathfinding = Pathfinding.new()

@onready var camera = $game_container/game_viewport/game_root/Camera2D
@onready var game_root = $game_container/game_viewport/game_root
@onready var hud = $game_container/game_viewport/Hud

#Cached scenes to speed up room loading at runtime
@onready var cached_scenes := {}
var room_location : Resource 
var room_instance
var remnant_offer_popup
var remnant_upgrade_popup
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
	0,#Damage dealt
	0,#Attacks made
	0,#Enemies defeated
	0,#Shops visited
	0,#Liquid rooms visited
	0,#Trap rooms visited
	0,#Damage taken
	0,#Elite enemies defeated   	#TODO
	0,#Currency collected
	0,#Items picked up   			#TODO
	]

func _ready() -> void:
	var conflict_cells : Array[Vector2i] = []
	_setup_players()
	hud.set_players(player,player_2)
	hud.connect_signals(player)
	
	#####Remnant Testing
	
	var rem = load("res://Game Elements/Remnants/hunter.tres")
	var rem2 = load("res://Game Elements/Remnants/trickster.tres")
	rem.rank = 5
	rem2.rank = 5
	player_1_remnants.append(rem)
	player_2_remnants.append(rem)
	player_2_remnants.append(rem2)
	hud.set_remnant_icons(player_1_remnants,player_2_remnants)
	
	#####
	game_root.add_child(pathfinding)
	preload_rooms()
	randomize()
	choose_room()
	choose_pathways(room.Direction.Up,room_instance, room_instance_data, conflict_cells)
	player.global_position =  generated_room_entrance[room_instance.name]
	if(is_multiplayer):
		player_2.global_position =  generated_room_entrance[room_instance.name] + Vector2(16,0)
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
	pathfinding.setup_from_room(room_instance.get_node("Ground"), room_instance.blocked_cells)
	_prepare_timefabric()

func _process(delta: float) -> void:
	time_passed += delta
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
				
	hud.set_timefabric_amount(timefabric_collected)
	
	if timefabric_rewarded!= 0:
		for i in range (20):
			timefabric_rewarded -=1
			_place_timefabric((randi() %timefabric_sizes.size()),
			Vector2(-8,-8)+Vector2(randf_range(-6,6),randf_range(-6,6)), 
			Vector2(room_instance.get_node("TimeFabricOrb").position), 
			Vector2(0,-1))
			if timefabric_rewarded== 0:
				room_instance.get_node("TimeFabricOrb").queue_free()
				reward_claimed = true
	if !room_cleared:
		for child in room_instance.get_children():
			if child is DynamEnemy:
				return
		layer_ai[4] += time_passed - layer_ai[3] #Add to combat time
		room_reward()
		room_cleared= true

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

func check_pathways(generated_room : Node2D, generated_room_data : Room, player_reference : Node, is_special_action : bool = false) -> int:
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

	var player_shape = player_reference.get_node("CollisionShape2D").shape
	var player_position = player_reference.global_position
	var player_rect = player_shape.extents
	for idx in range(0,len(targets_extents)):
		var area_rect = targets_extents[idx]
		if abs(player_position.x - targets_position[idx].x) <= player_rect.x + area_rect.x \
			and abs(player_position.y - targets_position[idx].y) <= player_rect.y + area_rect.y:
			var target_id = targets_id[idx]
			if !generated_room.get_node(target_id).used:
				if is_special_action:
					_randomize_room_reward(generated_room.get_node(target_id))
					return -1
				this_room_reward = generated_room.get_node(target_id).reward_type
				_move_to_pathway_room(targets_id[idx])
				return targets_direction[idx]
	return -1

func choose_room() -> void:
	#Shuffle rooms and load one
	room_instance_data = cave_stage[randi() % cave_stage.size()]
	
	room_location = load(room_instance_data.scene_location)
	room_instance = room_location.instantiate()
	game_root.add_child(room_instance)

func choose_pathways(direction : int, generated_room : Node2D, generated_room_data : Room, conflict_cells : Array[Vector2i]) -> void:
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
				_open_random_pathway_in_direction(Room.Direction.Up,direction_count, generated_room,conflict_cells)
			else:
				_open_random_pathway_in_direction(direction+1,direction_count, generated_room,conflict_cells)
	else:
		#Open at least one pathway in the given direction
		_open_random_pathway_in_direction(dir, direction_count, generated_room,conflict_cells)
	#Choose which pathways to keep      #add intelligent pathway choosing #TODO
	_open_random_pathways(generated_room, generated_room_data, conflict_cells)

func place_liquids(generated_room : Node2D, generated_room_data : Room, conflict_cells : Array[Vector2i]) -> void:
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
				conflict_cells.append_array(cells)

func place_traps(generated_room : Node2D, generated_room_data : Room, conflict_cells : Array[Vector2i]) -> void:
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
				conflict_cells.append_array(cells)
				_debug_message("Added Trap")
				if(generated_room_data.trap_types[trap_num-1]!=room.Trap.Tile):
					_add_trap(generated_room, generated_room_data, trap_num)

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
			var enemy = load("res://Game Elements/Characters/dynamEnemy.tscn").instantiate()
			enemy.position = generated_room.get_node("Enemy"+str(enemy_num)).position
			enemy.enemy_took_damage.connect(_on_enemy_take_damage)
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

func check_reward(generated_room : Node2D, _generated_room_data : Room, player_reference : Node) -> bool:
	#Remnant Orb
	if(if_node_exists("RemnantOrb",generated_room)):
		var remnant_orb = generated_room.get_node("RemnantOrb") as Area2D
		if remnant_orb.overlaps_body(player_reference):
			_open_remnant_popup()
			_enable_pathways()
			reward_claimed = true
			return true
	if(if_node_exists("TimeFabricOrb",generated_room)):
		var remnant_orb = generated_room.get_node("TimeFabricOrb") as Area2D
		if remnant_orb.overlaps_body(player_reference):
			timefabric_rewarded = 200 #TODO change this to by dynamic(ish)
			_enable_pathways()
			return true
	if(if_node_exists("UpgradeOrb",generated_room)):
		var upgrade_orb = generated_room.get_node("UpgradeOrb") as Area2D
		if upgrade_orb.overlaps_body(player_reference):
			_open_upgrade_popup()
			_enable_pathways()
			reward_claimed = true
			return true
	return false

func room_reward() -> void:
	var reward_location
	var reward = null
	if is_multiplayer:
		reward_location = _find_2x2_open_area([Vector2i(floor(player.global_position.x / 16), floor(player.global_position.y / 16)),Vector2i(floor(player_2.global_position.x / 16), floor(player_2.global_position.y / 16))])
	else:
		reward_location = _find_2x2_open_area([Vector2i(floor(player.global_position.x / 16), floor(player.global_position.y / 16))])
	while reward == null:
		match this_room_reward:
			Reward.Remnant:
				reward = load("res://Game Elements/Remnants/remnant_orb.tscn").instantiate()
			Reward.TimeFabric:
				reward = load("res://Game Elements/Objects/timefabric_orb.tscn").instantiate()
			Reward.RemnantUpgrade:
				reward = load("res://Game Elements/Objects/upgrade_orb.tscn").instantiate()
	reward.position = reward_location
	room_instance.call_deferred("add_child",reward)
	

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
	game_root.add_child(next_room_instance)
	
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

func open_death_menu() -> void:
	get_node("DeathMenu").activate()
	

func _randomize_room_reward(pathway_to_randomize : Node) -> void:
	var reward_type = null
	var prev_reward_type = pathway_to_randomize.reward_type
	var reward_texture : Node = null
	while reward_type == null:
		match randi() % 3:
			0:
				reward_type = Reward.Remnant
				if reward_type == prev_reward_type:
					reward_type = null
				else:
					var inst = load("res://Game Elements/Remnants/remnant_orb.tscn").instantiate()
					reward_texture = inst.get_node("Image")

			1:
				reward_type = Reward.TimeFabric
				if reward_type == prev_reward_type:
					reward_type = null
				else:
					var inst = load("res://Game Elements/Objects/timefabric_orb.tscn").instantiate()
					reward_texture = inst.get_node("Image")

			2:
				if _upgradable_remnants():
					reward_type = Reward.RemnantUpgrade
					if reward_type == prev_reward_type:
						reward_type = null
					else:
						var inst = load("res://Game Elements/Objects/upgrade_orb.tscn").instantiate()
						reward_texture = inst.get_node("Image")
	#Pass the icon & type to the pathway node
	pathway_to_randomize.set_reward(reward_texture, reward_type)

func _choose_reward(pathway_name : String) -> void:
	var reward_type = null
	var reward_texture : Node = null
	while reward_type == null:
		match randi() % 3:
			0:
				reward_type = Reward.Remnant
				var inst = load("res://Game Elements/Remnants/remnant_orb.tscn").instantiate()
				reward_texture = inst.get_node("Image")

			1:
				reward_type = Reward.TimeFabric
				var inst = load("res://Game Elements/Objects/timefabric_orb.tscn").instantiate()
				reward_texture = inst.get_node("Image")

			2:
				if _upgradable_remnants():
					reward_type = Reward.RemnantUpgrade
					var inst = load("res://Game Elements/Objects/upgrade_orb.tscn").instantiate()
					reward_texture = inst.get_node("Image")

	#Pass the icon & type to the pathway node
	room_instance.get_node(pathway_name).set_reward(reward_texture, reward_type)

func _enable_pathways() -> void:
	var pathway_name= ""
	var direction_count = [0,0,0,0]
	for p_direct in room_instance_data.pathway_direction:
		direction_count[p_direct]+=1
		pathway_name = _get_pathway_name(p_direct,direction_count[p_direct])
		if not if_node_exists(pathway_name,room_instance):
			var pathway_detect = room_instance.get_node_or_null(pathway_name+"_Detect/Area2D/CollisionShape2D")
			if pathway_detect and !room_instance.get_node(pathway_name+"_Detect").used:
				room_instance.get_node(pathway_name+"_Detect").enable_pathway()

func _upgradable_remnants() -> bool:
	var count = 0
	for remnant in player_1_remnants:
		if remnant.rank != 5:
			count+=1
			break
	for remnant in player_2_remnants:
		if remnant.rank != 5:
			count+=1
			break
	if count ==2:
		return true
	return false

func _setup_players() -> void:
	var player_scene = load("res://Game Elements/Characters/player_cat.tscn")
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
		game_root.add_child(player1)
		game_root.add_child(player2)
		player2.swap_color()
		#Temp Multiplayer Fix
		player = player1
		player_2 = player2
		player_2.attack_requested.connect(_on_player_attack)
		player_2.player_took_damage.connect(_on_player_take_damage)
		player_2.activate.connect(_on_activate)
		player_2.special.connect(_on_special)
		hud.connect_signals(player_2)
	else:
		var player1 = player_scene.instantiate()
		player1.is_multiplayer = false
		player1.input_device = "key"
		game_root.add_child(player1)
		player = player1
	player.attack_requested.connect(_on_player_attack)
	player.player_took_damage.connect(_on_player_take_damage)
	player.activate.connect(_on_activate)
	player.special.connect(_on_special)

func _enemy_to_timefabric(enemy : Node,direction : Vector2, amount_range : Vector2) -> void:
	var sprite = enemy.get_node("Sprite2D")
	var current_position = sprite.get_global_position() - sprite.get_rect().size /2
	var return_values : Array = _load_enemy_image(enemy)
	var pixels_to_cover : Dictionary = return_values[0]
	var enemy_width : int = return_values[1]
	var enemy_height : int = return_values[2]
	var timefabrics_to_place : Array[Array] = []
	var time_idx =0
	var offset = Vector2i(0,0)
	var num_time_fabrics = timefabric_masks.size()
	var best_score = 0.0
	var score = 0.0
	for i in range(0,100):
		best_score = 0.0
		#Place random timefabric variants and random locations.
		timefabrics_to_place.append([0,Vector2i(0,0)])
		for j in range(0,100):
			time_idx = randi() % num_time_fabrics
			offset = Vector2i(
				randi_range(1 - timefabric_sizes[time_idx][0], enemy_width - 1),
				randi_range(1 - timefabric_sizes[time_idx][1], enemy_height - 1)
			)
			score = _score_timefabric_placement(pixels_to_cover,timefabric_masks[time_idx],time_idx,offset)
			if score > best_score:
				best_score=score
				timefabrics_to_place[i]= [time_idx,offset]
			if best_score >= .95:
				break
		if best_score <= .5:
			timefabrics_to_place.pop_back()
			break
		for pixel in timefabric_masks[timefabrics_to_place[i][0]]:
			if pixels_to_cover.has(Vector2i(pixel+timefabrics_to_place[i][1])):
				pixels_to_cover[Vector2i(pixel+timefabrics_to_place[i][1])] = false
	while timefabrics_to_place.size() > amount_range.y:
		timefabrics_to_place.remove_at(randi() % timefabrics_to_place.size())
	while timefabrics_to_place.size() < amount_range.x:
		timefabrics_to_place.append(timefabrics_to_place[randi() % timefabrics_to_place.size()])
	
	for fabric in timefabrics_to_place:
		_place_timefabric(fabric[0],fabric[1],current_position,direction)

func _place_timefabric(time_idx : int, offset : Vector2i, current_position : Vector2, direction : Vector2) -> void:
	var timefabric_instance = timefabric.instantiate()
	room_instance.add_child(timefabric_instance)
	timefabric_instance.get_node("Sprite2D").frame = time_idx
	timefabric_instance.global_position = current_position + Vector2(offset) +Vector2(8,8)
	timefabric_instance.set_arrays(self, room_instance.get_node("Walls").get_used_cells())
	timefabric_instance.set_direction(direction)
	timefabric_instance.set_process(true)
	timefabric_instance.absorbed_by_player.connect(_on_timefabric_absorbed)
	return

func _score_timefabric_placement(pixels_to_cover : Dictionary, timefabric_pixels : Array, timefabric_idx : int,offset : Vector2i) -> float:
	var count = 0.0
	for pixel in timefabric_pixels:
		if pixels_to_cover.has(Vector2i(pixel+offset)) and pixels_to_cover[Vector2i(pixel+offset)]:
			count+=1.0
	return count / timefabric_sizes[timefabric_idx][2]

func _load_enemy_image(enemy : Node) -> Array: 
	var sprite = enemy.get_node("Sprite2D") as Sprite2D
	if not sprite.texture:
		print("Sprite has no texture!")
	var img : Image = sprite.texture.get_image()
	if not sprite.texture:
		print("Texture has no image!")
	var visible_pixels := {}  # Dictionary as hashmap
	var w = int(img.get_width() / sprite.hframes)
	var h = int(img.get_height() / sprite.vframes)
	#Get the coords of the current frame
	var cur_x = sprite.frame % sprite.hframes * w
	var cur_y = int (sprite.frame / sprite.hframes) * h
	for y in range(cur_y,cur_y+h):
		for x in range(cur_x,cur_x+w):
			var color = img.get_pixel(x, y)
			if color.a > 0.5:
				visible_pixels[Vector2i(x-cur_x,y-cur_y)] = true
	return [visible_pixels, w, h]

func _prepare_timefabric() -> void: 
	var sheet = preload("res://art/time_fabric.png") as Texture2D 
	var w = 16
	var h = 16
	var max_x
	var max_y
	for i in range(6): 
		var atlas = AtlasTexture.new() 
		atlas.atlas = sheet 
		atlas.region = Rect2(i * w, 0, w, h) 
		var img = atlas.get_image() 
		var mask = [] 
		max_x = 0
		max_y = 0
		timefabric_masks.append([])
		for y in range(h): 
			mask.append([]) 
			for x in range(w):
				if img.get_pixel(x,y).a > 0.5:
					max_x = max(max_x,x)
					max_y = max(max_y,y)
					timefabric_masks[i].append(Vector2i(x,y))
		timefabric_sizes.append(Vector3i(max_x,max_y,timefabric_masks[i].size()))

func _open_remnant_popup() -> void:
	if room_instance and !remnant_offer_popup:
		room_instance.get_node("RemnantOrb").queue_free()
		var offer_scene = load("res://Game Elements/ui/remnant_offer.tscn")
		remnant_offer_popup = offer_scene.instantiate()
		hud.add_child(remnant_offer_popup)
		remnant_offer_popup.remnant_chosen.connect(_on_remnant_chosen)
		remnant_offer_popup.popup_offer(is_multiplayer, player_1_remnants,player_2_remnants, [50,35,10,5,0])
		
		player.get_node("Crosshair").visible = false
		if is_multiplayer:
			player_2.get_node("Crosshair").visible = false

func _open_upgrade_popup() -> void:
	if room_instance and !remnant_upgrade_popup:
		room_instance.get_node("UpgradeOrb").queue_free()
		var upgrade_scene = load("res://Game Elements/ui/remnant_upgrade.tscn")
		remnant_upgrade_popup = upgrade_scene.instantiate()
		hud.add_child(remnant_upgrade_popup)
		remnant_upgrade_popup.remnant_upgraded.connect(_on_remnant_upgraded)
		remnant_upgrade_popup.popup_upgrade(is_multiplayer, player_1_remnants.duplicate(),player_2_remnants.duplicate())
		
		player.get_node("Crosshair").visible = false
		if is_multiplayer:
			player_2.get_node("Crosshair").visible = false

func _find_2x2_open_area(player_positions: Array, max_distance: int = 20) -> Vector2i:
	var candidates := []
	#Combine all blocked and unsafe cells
	var unsafe_cells :Array = blocked_cells.duplicate()
	var safe_cells : Array = room_instance.get_node("Ground").get_used_cells()
	unsafe_cells.append_array(water_cells)
	unsafe_cells.append_array(lava_cells)
	unsafe_cells.append_array(acid_cells)
	unsafe_cells.append_array(trap_cells)
	var direction_count = [0,0,0,0]
	var pathway_positions = []
	var pathway_name = ""
	var temp_pos
	for p_direct in room_instance_data.pathway_direction:
		direction_count[p_direct]+=1
		pathway_name = _get_pathway_name(p_direct,direction_count[p_direct])
		if if_node_exists(pathway_name,room_instance):
			unsafe_cells += room_instance.get_node(pathway_name).get_used_cells()
		if if_node_exists(pathway_name+"_Detect",room_instance):
			temp_pos = room_instance.get_node(pathway_name+"_Detect").position
			pathway_positions.append(Vector2i(floor(temp_pos.x / 16), floor(temp_pos.y / 16)))
	#Generate candidate 2x2 positions around each player
	for player_pos in player_positions:
		for dx in range(-max_distance, max_distance):
			for dy in range(-max_distance, max_distance):
				var candidate = player_pos + Vector2i(dx, dy)
				#Check the 2x2 area is free
				var all_free = true
				for x in range(-1,1):
					for y in range(-1,1):
						if unsafe_cells.has(candidate + Vector2i(x, y)) or !safe_cells.has(candidate + Vector2i(x, y)):
							all_free = false
							break
					if not all_free:
						break
				if all_free:
					for player_position in player_positions:
						if player_position.distance_to(candidate) < 3:
							all_free = false
							break
				if all_free:
					for path_position in pathway_positions:
						if path_position.distance_to(candidate) < 3:
							all_free = false
							break
				if all_free:
					candidates.append(candidate)

	if candidates.size()==0:
		return Vector2i.ZERO
	#Weighted random selection
	var weights := []
	for c in candidates:
		var min_dist = INF
		for player_pos in player_positions:
			var dist = player_pos.distance_to(c)
			if dist < min_dist:
				min_dist = dist
		#Closer = higher weight
		weights.append(1.0 / (min_dist*2 + 1))
	#_debug_tiles(candidates)


	# Pick a candidate based on weight
	var total_weight = 0.0
	for w in weights:
		total_weight += w

	var rnd = randf() * total_weight
	for i in range(candidates.size()):
		rnd -= weights[i]
		if rnd <= 0:
			return candidates[i] * 16

	return candidates[0] * 16

func _add_trap(generated_room: Node2D, generated_room_data: Room, trap_num: int) -> void:
	var cells = generated_room.get_node("Trap"+str(trap_num)).get_used_cells()
	var type = generated_room_data.trap_types[trap_num-1]
	for cell in cells:
		match type:
			room.Trap.Spike:
				var spike = load("res://Game Elements/Objects/spike_trap.tscn").instantiate()
				spike.position = generated_room.get_node("Trap"+str(trap_num)).map_to_local(cell)
				generated_room.add_child(spike)

func return_trap_layer(tile_pos : Vector2i) -> TileMapLayer:
	for trap_num in range(1,room_instance_data.num_trap+1):
		if if_node_exists(("Trap"+str(trap_num)), room_instance):
			if tile_pos in room_instance.get_node("Trap"+str(trap_num)).get_used_cells():
				return room_instance.get_node("Trap"+str(trap_num))
	return null

func _finalize_room_creation(next_room_instance: Node2D, next_room_data: Room, direction: int, pathway_detect: Node) -> void:
	
	var conflict_cells : Array[Vector2i] = []
	choose_pathways(direction, next_room_instance, next_room_data, conflict_cells)
	place_liquids(next_room_instance, next_room_data, conflict_cells)
	place_traps(next_room_instance, next_room_data, conflict_cells)
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
	
	_choose_reward(pathway_detect.name)
	
func _move_to_pathway_room(pathway_id: String) -> void:
	if not generated_rooms.has(pathway_id):
		push_warning("No linked room for pathway " + pathway_id)
		return
	var next_room_data = generated_room_metadata[pathway_id]
	var next_room = generated_rooms[pathway_id]
	if not is_instance_valid(next_room):
		push_warning("Linked room instance invalid for " + pathway_id)
		return

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
	
	# Teleport player to the entrance of the next room
	player.global_position =  generated_room_entrance[next_room.name]
	player.disabled_countdown=3
	if(is_multiplayer):
		player_2.global_position = generated_room_entrance[next_room.name] + Vector2(16,0)
		player_2.disabled_countdown=3
		player.global_position -= Vector2(16,0)
		
	
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
	
	
	room_cleared= false
	reward_claimed = false

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
	if !input.ends_with("_Detect"):
		generated_room.get_node(input+"_Detect").disable_pathway()
	
func if_node_exists(input : String,generated_room : Node2D) -> bool:
	if generated_room.get_node_or_null(input):
		return !generated_room.get_node(input).is_queued_for_deletion()
	else:
		return false

func _open_random_pathway_in_direction(dir : room.Direction, direction_count : Array,generated_room : Node2D, conflict_cells : Array[Vector2i]) -> void:
	var pathway_name = _get_pathway_name(dir,int(randf()*direction_count[dir])+1)
	conflict_cells.append_array(generated_room.get_node(pathway_name).get_used_cells())
	_open_pathway(pathway_name, generated_room)

func _open_random_pathways(generated_room : Node2D, generated_room_data : Room, conflict_cells : Array[Vector2i]) -> void:
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
				conflict_cells.append_array(generated_room.get_node(pathway_name).get_used_cells())
			
func _on_player_attack(_new_attack : Attack, _attack_position : Vector2, _attack_direction : Vector2, _damage_boost : float) -> void:
	layer_ai[6]+=1
	
func _on_player_take_damage(damage_amount : int,_current_health : int,_player_node : Node) -> void:
	layer_ai[11]+=damage_amount
	
func _on_enemy_take_damage(damage : int,current_health : int,enemy : Node, direction = Vector2(0,-1)) -> void:
	layer_ai[5]+=damage
	if current_health <= 0:
		_enemy_to_timefabric(enemy,direction,Vector2(20,40))
		enemy.visible=false
		enemy.queue_free()
		layer_ai[7]+=1

func _on_remnant_chosen(remnant1 : Resource, remnant2 : Resource):
	player_1_remnants.append(remnant1.duplicate(true))
	player_2_remnants.append(remnant2.duplicate(true))
	remnant_offer_popup.queue_free()
	player.get_node("Crosshair").visible = true
	if is_multiplayer:
		player_2.get_node("Crosshair").visible = true
	hud.set_remnant_icons(player_1_remnants,player_2_remnants)

func _on_remnant_upgraded(remnant1 : Resource, remnant2 : Resource):
	for i in range(player_1_remnants.size()):
		if player_1_remnants[i] == remnant1:
			player_1_remnants[i].rank +=1
	for i in range(player_2_remnants.size()):
		if player_2_remnants[i] == remnant2:
			player_2_remnants[i].rank +=1
	remnant_upgrade_popup.queue_free()
	player.get_node("Crosshair").visible = true
	if is_multiplayer:
		player_2.get_node("Crosshair").visible = true
	hud.set_remnant_icons(player_1_remnants,player_2_remnants)

func _on_timefabric_absorbed(timefabric_node : Node):
	timefabric_collected+=1
	layer_ai[13]+=1
	timefabric_node.queue_free()
	
func _on_activate(player_node : Node):
	if room_instance and room_cleared:
		if check_reward(room_instance, room_instance_data,player_node):
			return
		if reward_claimed:
			var direction = check_pathways(room_instance, room_instance_data,player_node,false)
			if direction != -1:
				create_new_rooms()
	
func _on_special(player_node : Node):
	var remnants : Array[Remnant] = []
	if player_node.is_purple:
		remnants = get_tree().get_root().get_node("LayerManager").player_1_remnants
	else:
		remnants = get_tree().get_root().get_node("LayerManager").player_2_remnants
	var trickster = load("res://Game Elements/Remnants/trickster.tres")
	for rem in remnants:
		if rem.remnant_name == trickster.remnant_name:
			if timefabric_collected >= int(rem.variable_1_values[rem.rank-1]):
				timefabric_collected-=int(rem.variable_1_values[rem.rank-1])
				check_pathways(room_instance, room_instance_data,player_node,true)
	return -1

func _debug_message(msg : String) -> void:
	print("DEBUG: "+msg)

func _debug_tiles(array_of_tiles) -> void:
	var debug
	for tile in array_of_tiles:
		debug = load("res://Game Elements/General Game/debug_scene.tscn").instantiate()
		debug.position = tile*16
		room_instance.add_child(debug)
