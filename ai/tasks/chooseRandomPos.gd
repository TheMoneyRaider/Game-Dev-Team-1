extends BTAction

@export var target_position_var: String = "target_pos"
@export var min_distance: float = 48
@export var random_extra_distance: float = 32

func _tick(_delta: float) -> Status: 
	var pos: Vector2 = agent.global_position
	var place_locations : Array[Vector2i] = agent.get_tree().get_root().get_node("LayerManager")._placable_locations()
	var attempts = 0
	var x: float
	var y: float
	while attempts < 20:
		x = randf_range(-random_extra_distance, random_extra_distance)
		y = randf_range(-random_extra_distance, random_extra_distance)
		
		if x < 0:
			x += - min_distance
		else: 
			x += min_distance
		
		if y < 0:
			y += -min_distance
		else:
			y += min_distance
		attempts+=1
		if place_locations.has(Vector2i(((pos+Vector2(x,y))/16))):
			pos += Vector2(x,y)
			break
			
	
	
	
	print("Player Pos: " + str(agent.global_transform.origin) + " Random Pos: " + str(pos))
	
	blackboard.set_var("target_pos", pos)
	
	return SUCCESS

"""
make it so it stays in/returns to it's "spawn bubble" at some point 
"""
