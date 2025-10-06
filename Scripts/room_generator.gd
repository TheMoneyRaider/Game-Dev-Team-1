extends Node2D

@export var _dimensions : Vector2i = Vector2i(100,100)
@export var _start : Vector2i = Vector2i(50,50)
@export var _walkers : int = 4
#@export var _walker_turn_chance : float = .125
#@export var _path_randomness : Curve
@export var _path_min : int = 3
@export var _path_max : int = 10

@onready var room_base : Resource = load("res://Scenes/room.tscn")
@onready var room_instance : TileMapLayer = room_base.instantiate()

var layer : Array
var _walker_candidates : Array[Vector2i]
var _flooring : Array[Vector2i]
var _walls : Array[Vector2i]
var _filling : Array[Vector2i]

#func _process(_delta: float) -> void:
	

func _ready() -> void:
	room_instance.set_name("Room")
	add_child(room_instance)
	_create_layer()
	_place_entrance()
	_generate_critical_path(_start, randi_range(_path_min, _path_max))
	_generate_walkers()
	_print_layer()

func _create_layer() -> void:
	for x in _dimensions.x:
		layer.append([])
		for y in _dimensions.y:
			layer[x].append(0)

func _print_layer() -> void:
	for y in _dimensions.y:
		for x in _dimensions.x:
			if (x>0 and y<_dimensions.y-2 and x<_dimensions.x-1 
					and layer[x][y+2] 
					and layer[x+1][y+1] 
					and layer[x][y]
					and layer[x-1][y+1]
					and !layer[x][y+1]):
				layer[x][y+1]="1"
				_flooring.append(Vector2i(x-_start.x,y+1-_start.y))
			#if y>0 and y<_dimensions.y-1 and layer[x][y+1] and !layer[x][y-1]:
				#_walls.append(Vector2i(x-_start.x,y-_start.y))
			#elif !layer[x][y]:
				#_filling.append(Vector2i(x-_start.x,y-_start.y))
	room_instance.set_cells_terrain_connect(_flooring, 0, 0, true)
	#room_instance.set_cells_terrain_connect(_walls, 0, 1, true)
	#room_instance.set_cells_terrain_connect(_filling, 0, 2, true)
		
	

	var layer_as_string : String = ""
	for y in _dimensions.y:
		for x in _dimensions.x:
			if layer[x][y]:
				layer_as_string += "["+ str(layer[x][y])+"]"
			else:
				layer_as_string += "   "
		layer_as_string += '\n'
	print(layer_as_string)
	
func _place_entrance() -> void:
	if _start.x <0 or _start.x >= _dimensions.x:
		_start.x = randi_range(0, _dimensions.x-1)
	if _start.y <0 or _start.y >= _dimensions.y:
		_start.y = randi_range(0, _dimensions.y-1)
	layer[_start.x][_start.y]= "S"
	_flooring.append(Vector2i(0,0))

func _print_branches(array: Array[Vector2i]):
	var branches_as_string : String = str(_walkers)
	for x in _walker_candidates.size():
		branches_as_string += "("+str(array[x].x)+","+str(array[x].y)+") "
	branches_as_string += '\n'
	print(branches_as_string)
	_print_layer()

func _generate_critical_path(from : Vector2i, length: int)-> bool:
	if length==0:
		return true
	var current : Vector2i = from
	var direction : Vector2i
	match randi_range(0,3):
		0:
			direction = Vector2i.UP
		1:
			direction = Vector2i.RIGHT
		2:
			direction = Vector2i.DOWN
		3:
			direction = Vector2i.LEFT
	for i in 4:
		if (current.x + direction.x >= 0 and current.x + direction.x < _dimensions.x and 
			current.y + direction.y >= 0 and current.y + direction.y < _dimensions.y and 
			not layer[current.x +direction.x][current.y +direction.y]):
				current+=direction
				layer[current.x][current.y]="1"
				if length > 1:
					_walker_candidates.append(current)
				if _generate_critical_path(current, length - 1):
					_flooring.append(Vector2i(current.x-_start.x,current.y-_start.y))
					return true
				else:
					_walker_candidates.erase(current)
					layer[current.x][current.y]=0
					current -= direction
		direction = Vector2(direction.y, -direction.x)
	return false

func _generate_walkers() -> void:
	var walkers_created : int = 0
	var candidate : Vector2i
	while walkers_created < _walkers and _walker_candidates.size():
		candidate = _walker_candidates[randi_range(0, _walker_candidates.size() -1)]
		if _generate_critical_path(candidate, randi_range(_path_min, _path_max)):
			walkers_created += 1
		else:
			_walker_candidates.erase(candidate)
	print(str(_walker_candidates.size())+" "+str(walkers_created))
