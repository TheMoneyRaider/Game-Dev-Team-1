extends Node2D

@export var _dimensions : Vector2i = Vector2i(7,5)
@export var _start : Vector2i = Vector2i(3,0)
@export var _critical_path_length : int = 13
@export var _branches : int = 3
@export var _branch_length : Vector2i = Vector2i(1,4)

var layer : Array
var _branch_candidates : Array[Vector2i]


func _ready() -> void:
	_create_layer()
	_place_entrance()
	_generate_critical_path(_start, _critical_path_length, "C")
	_generate_branches()
	_print_layer()

func _create_layer() -> void:
	for x in _dimensions.x:
		layer.append([])
		for y in _dimensions.y:
			layer[x].append(0)

func _print_layer() -> void:
	var layer_as_string : String = ""
	for y in range(_dimensions.y -1,-1,-1):
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
	

func _generate_critical_path(from : Vector2i, length: int, marker : String)-> bool:
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
				layer[current.x][current.y]=marker
				if length > 1:
					_branch_candidates.append(current)
				if _generate_critical_path(current, length - 1, marker):
					return true
				else:
					_branch_candidates.erase(current)
					layer[current.x][current.y]=0
					current -= direction
		direction = Vector2(direction.y, -direction.x)
	return false

func _generate_branches() -> void:
	var branches_created : int = 0
	var candidate : Vector2i
	while branches_created < _branches and _branch_candidates.size():
		candidate = _branch_candidates[randi_range(0, _branch_candidates.size() -1)]
		if _generate_critical_path(candidate, randi_range(_branch_length.x, _branch_length.y), str(branches_created+1)):
			branches_created += 1
		else:
			_branch_candidates.erase(candidate)
