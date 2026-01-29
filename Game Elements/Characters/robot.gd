extends Node2D

@export var anim_frame : int

func set_frame(frame_in : int):
	get_node("../Sprite2D").frame = frame_in
