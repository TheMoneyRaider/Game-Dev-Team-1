class_name Spawner

static var cell_world_size: float = 16.0 # size of each grid cell in world units
static var player_penalty_weight = 60
static var player_threshold =128
static var enemy_penalty_weight = 50
static var enemy_threshold = 96
static var edge_penalty_weight = 20
static var edge_threshold = 48

static func spawn_enemies(count: int, players: Array[Node],scene : Node, available_cells : Array[Vector2i],enemy_scenes: Array[PackedScene],layer_manager : Node):
	var edges = _get_edges(available_cells)
	var chosen_positions: Array[Vector2i] = []
	for i in count:
		var best_cell := _choose_best_cell(available_cells, chosen_positions, players,edges)

		if best_cell == null:
			push_warning("No valid cell left to place enemy")
			return

		available_cells.erase(best_cell)
		chosen_positions.append(best_cell)
	
		_spawn_enemy(best_cell,scene,enemy_scenes,layer_manager)
	_debug_tiles(chosen_positions,scene)

static func _choose_best_cell(available_cells : Array[Vector2i], chosen_positions : Array[Vector2i], players : Array[Node],edges : Array[Vector2i]) -> Vector2i:
	var best_score := -INF
	var best_cell = null

	for cell in available_cells:
		var score := _score_cell(cell, chosen_positions, players,edges)
		if score > best_score:
			best_score = score
			best_cell = cell

	return best_cell


static func _score_cell(cell: Vector2, chosen_positions : Array[Vector2i], players : Array[Node],edges : Array[Vector2i]) -> float:
	var world_pos := cell * cell_world_size

	var distance_score := 0.0

	#Distance from players
	for p in players:
		var d =world_pos.distance_to(p.global_position)
		var d_factor = max(d,1)
		distance_score += player_penalty_weight * (d_factor /  player_threshold)**2

	#Distance from already-chosen spawn points (keeps enemies apart)
	for c in chosen_positions:
		var d = world_pos.distance_to(c * cell_world_size)
		var d_factor = max(d,1)
		distance_score += enemy_penalty_weight * (d_factor / enemy_threshold)**2
	#Distance from edges (keeps enemies away from edges)
	for e in edges:
		var d = world_pos.distance_to(e * cell_world_size)
		if d < edge_threshold:
			distance_score -= edge_penalty_weight * (1.0 - d / edge_threshold)  # closer to edge = bigger penalty

	return distance_score


static func _spawn_enemy(cell: Vector2i, scene : Node,enemy_scenes: Array[PackedScene], layer_manager : Node):
	var enemy = enemy_scenes[randi() % enemy_scenes.size()].instantiate()

	# Convert cell coordinate to world space
	enemy.global_position = cell * cell_world_size
	#scene.add_child(enemy)
	#enemy.enemy_took_damage.connect(layer_manager._on_enemy_take_damage)
	
static func _get_edges(available_cells : Array[Vector2i]) -> Array[Vector2i]:
	var edges : Array[Vector2i]
	for cell in available_cells:
		var neighbors = [Vector2i(cell.x+1,cell.y),Vector2i(cell.x,cell.y+1),Vector2i(cell.x-1,cell.y),Vector2i(cell.x,cell.y-1)]
		for neigh in neighbors:
			if neigh not in available_cells and neigh not in edges:
				edges.append(neigh)
	return edges
	
static func _debug_tiles(array_of_tiles,scene) -> void:
	var debug
	for tile in array_of_tiles:
		debug = load("res://Game Elements/General Game/debug_scene.tscn").instantiate()
		debug.position = tile*16
		scene.add_child(debug)
