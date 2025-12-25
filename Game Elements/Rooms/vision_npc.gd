extends Area2D

func _ready() -> void:
	for node in get_children():
		if node.is_in_group("tentacle"):
			node.set_hole($Cracks.global_position)
			
