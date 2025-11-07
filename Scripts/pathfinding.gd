class_name Pathfinding 
extends Node

var astar = AStar2D.new()
var grid_bounds: Rect2i
var walkable_cells: Array[Vector2i] = []
var cell_size: int = 16

# reset function for changing rooms
func clear():
	astar.clear() # remove all points and connections from Astar
	walkable_cells.clear() # empty the walkable tiles list 
	
# Astar uses ID numbers rather than vectors to track points
func pos_to_id(pos: Vector2i) -> int: 
	return pos.x + pos.y * grid_bounds.size.x
	
# converts the id back into grid position 
func id_to_pos(id: int) -> Vector2i:
	var x = id % grid_bounds.size.x
	var y = id / grid_bounds.size.x
	return Vector2i(x,y)

# orgonises all the data from the layer_manager, 
func setup_from_room(ground_layer: TileMapLayer, blocked_cells: Array[Vector2i]):
	clear()
	
	# no used cells, return, nothing to do
	var used_cells = ground_layer.get_used_cells()
	if used_cells.is_empty():
		return
	
	# create a bounding box for all of the cells possible, used for id-ing them later 
	var min_x = used_cells[0].x
	var max_x = used_cells[0].x
	var min_y = used_cells[0].y
	var max_y = used_cells[0].y
	
	for cell in used_cells:
		min_x = min(min_x, cell.x)
		max_x = max(max_x, cell.x)
		min_y = min(min_y, cell.y)
		max_y = max(max_y, cell.y)
	
	grid_bounds = Rect2i(min_x, min_y, max_x - min_x + 1, max_y - min_y +  1)
	
	var blocked_dict = {}
	for cell in blocked_cells: 
		blocked_dict[cell] = true 
	
	for cell in used_cells:
		if not blocked_dict.has(cell):
			walkable_cells.append(cell)
			var id = pos_to_id(cell)
			astar.add_point(id, Vector2(cell.x * cell_size, cell.y * cell_size))
			
	# find neighboring walkable cells
	var directions = [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]
	
	# adds walkable neighbor cells to astar, mapping the bounding box
	for cell in walkable_cells:
		var id = pos_to_id(cell)
	
		for dir in directions: 
			var neighbor = cell + dir
			if neighbor in walkable_cells: 
				var neighbor_id = pos_to_id(neighbor)
				if not astar.are_points_connected(id, neighbor_id): 
					astar.connected_points(id,neighbor_id)
	

 
