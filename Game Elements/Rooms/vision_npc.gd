extends Node2D

func _ready() -> void:
	for node in get_node("SubViewportContainer").get_node("SubViewport").get_children():
		if node.is_in_group("tentacle"):
			node.set_hole($Cracks.global_position)
			
func _process(delta: float) -> void:
	#position+=Vector2(1,0)*delta*10
	get_node("SubViewportContainer").material.set_shader_parameter("node_offset",position)
	pass
