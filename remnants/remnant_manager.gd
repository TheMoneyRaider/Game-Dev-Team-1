extends Node

var remnant_pool: Array[Resource] = []

func _ready():
	randomize()
	_load_all_remnants()

#Loads all resources from res://remnants/
func _load_all_remnants() -> void:
	var dir = DirAccess.open("res://remnants")
	if dir == null:
		push_error("Remnants folder not found: res://remnants")
		return
	dir.list_dir_begin()
	var file_name = dir.get_next()
	while file_name != "":
		if not dir.current_is_dir() and file_name.ends_with(".tres"):
			var res = ResourceLoader.load("res://remnants/" + file_name)
			if res:
				remnant_pool.append(res)
		file_name = dir.get_next()
	dir.list_dir_end()

#Returns an array of up to `num` unique random remnants from the pool. #TODO update to remove current remnants the player has #TODO add level variance
func get_random_remnants(num: int = 3) -> Array[Resource]:
	var n = remnant_pool.size()
	if n == 0:
		return []
	if n <= num:
		#return a shuffled copy
		var out = remnant_pool.duplicate()
		out.shuffle()
		return out
	#chose num amount of remnants
	var indices = []
	while indices.size() < num:
		var i = (randi() % n)
		if i not in indices:
			indices.append(i)
	var result : Array[Resource] = []
	for idx in indices:
		result.append(remnant_pool[idx])
	return result
