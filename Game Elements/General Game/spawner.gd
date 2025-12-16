class_name Spawner

static var cell_world_size: float = 16.0 # size of each grid cell in world units
static var player_penalty_weight : float = 1.0
static var player_threshold : float =4*16.0
static var enemy_penalty_weight : float = .75
static var enemy_threshold : float = 4*16.0
static var edge_penalty_weight : float = 0.25
static var edge_threshold : float = 2*16.0

static func spawn_enemies(count: int, players: Array[Node],scene : Node, available_cells : Array[Vector2i],enemy_scenes: Array[PackedScene],layer_manager : Node):
	var edges = _get_edges(available_cells)
	var chosen_positions: Array[Vector2i] = []
	var weights: Array[float] = []
	for i in count:
		var best = _choose_best_cell(available_cells, chosen_positions, players,edges,scene)
		
		if best[0] == null:
			push_warning("No valid cell left to place enemy")
			return

		available_cells.erase(best[0])
		chosen_positions.append(best[0])
		weights.append(best[1])
	
		_spawn_enemy(best[0],scene,enemy_scenes,layer_manager)
		
	_choose_best_cell(available_cells, chosen_positions, players,edges,scene, true)

static func _choose_best_cell(available_cells : Array[Vector2i], chosen_positions : Array[Vector2i], players : Array[Node],edges : Array[Vector2i],scene : Node, is_debug : bool = false) -> Array:
	var best_weight := -INF
	var best_cell = null
	var weights = []
	var total_weight = 0.0

	for cell in available_cells:
		var score := _score_cell(cell, chosen_positions, players,edges)
		total_weight+=score
		weights.append(score)
	var placement = randf() * total_weight
	var running_weight = 0.0
	var i = 0
	while i < available_cells.size():
		if ( running_weight+weights[i]) > placement:
			best_cell = available_cells[i]
			best_weight = weights[i]
			break
		running_weight+=weights[i]
		i+=1
		
	
	_debug_tiles(available_cells,scene,weights)
	return [best_cell,best_weight]


static func _score_cell(cell: Vector2, chosen_positions : Array[Vector2i], players : Array[Node],edges : Array[Vector2i]) -> float:
	var world_pos := cell * cell_world_size

	var distance_score := 1.0
#
	#Distance from players
	for p in players:
		var d =float(world_pos.distance_to(p.global_position+Vector2(-8,-8)))
		if d < player_threshold:
			distance_score -= player_penalty_weight * (1-(d/player_threshold))
	##Distance from already-chosen spawn points (keeps enemies apart)
	for c in chosen_positions:
		var d =float(world_pos.distance_to(c * cell_world_size))
		if d < enemy_threshold:
			distance_score -= enemy_penalty_weight * (1-(d/enemy_threshold))
	##Distance from edges (keeps enemies away from edges)
	for e in edges:
		var d =float(world_pos.distance_to(e * cell_world_size))
		if d < edge_threshold:
			distance_score -= edge_penalty_weight * (1-(d/edge_threshold))

	return clamp(distance_score,0,1)


static func _spawn_enemy(cell: Vector2i, scene : Node,enemy_scenes: Array[PackedScene], layer_manager : Node):
	var enemy = enemy_scenes[randi() % enemy_scenes.size()].instantiate()

	# Convert cell coordinate to world space
	enemy.global_position = cell * cell_world_size
	scene.add_child(enemy)
	enemy.enemy_took_damage.connect(layer_manager._on_enemy_take_damage)
	
static func _get_edges(available_cells : Array[Vector2i]) -> Array[Vector2i]:
	var edges : Array[Vector2i]
	for cell in available_cells:
		var neighbors = [Vector2i(cell.x+1,cell.y),Vector2i(cell.x,cell.y+1),Vector2i(cell.x-1,cell.y),Vector2i(cell.x,cell.y-1)]
		for neigh in neighbors:
			if neigh not in available_cells and neigh not in edges:
				edges.append(neigh)
	return edges
	
static func _debug_tiles(array_of_tiles,scene, weights) -> void:
	var debug
	var idx =0
	for tile in array_of_tiles:
		debug = load("res://Game Elements/General Game/debug_scene.tscn").instantiate()
		debug.position = tile*16
		debug.get_node("TestScene2").modulate.a = weights[idx]
		scene.add_child(debug)
		idx+=1
