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


 
