extends Node2D

var shop_open = false
var moving_tentacles : Array[Node] = []
var moving_positions : Array[Vector2] = []
var opening_stage : int = 0
var curr_pos = Vector2.ZERO

func _ready() -> void:
	for node in get_node("Tentacles").get_children():
		if node.is_in_group("tentacle"):
			node.set_hole($Cracks.global_position+Vector2(8,32))
			
func _process(delta: float) -> void:
	if curr_pos != position:
		curr_pos= position
		for node in get_node("Tentacles").get_children():
			if node.is_in_group("tentacle"):
				node.get_node("SubViewportContainer").material.set_shader_parameter("node_offset",position)



func open_shop(offered_items : int = 4) -> void:
	if shop_open:
		return
	shop_open = true

	var tentacle_list: Array[Node] = []

	for node in get_node("Tentacles").get_children():
		if node.is_in_group("tentacle") and node.name != "Tentacle_Vision":
			tentacle_list.append(node)

	tentacle_list.shuffle()
	moving_tentacles = tentacle_list.slice(0, min(offered_items, tentacle_list.size()))
	var hole_center : Vector2 = $Cracks.global_position + Vector2(8, 40)
	var hole_bottom : Vector2 = $ItemLocation.global_position

	for tentacle in moving_tentacles:
		_animate_tentacle_target(tentacle, hole_center, hole_bottom)

func _animate_tentacle_target(tentacle: Node, hole_center: Vector2, hole_bottom: Vector2) -> void:
	var target: Node2D = tentacle.target
	if target == null:
		return

	var start_pos := target.global_position

	var control := Vector2(hole_bottom.x,start_pos.y+48)

	var duration := 2

	var tween := create_tween()
	tween.set_trans(Tween.TRANS_SINE)
	tween.set_ease(Tween.EASE_IN_OUT)

	# Forward
	tween.tween_method(
		func(t):
			target.global_position = quadratic_bezier(start_pos, control, hole_bottom, t),
		0.0,
		1.0,
		duration
	)
	tween.tween_callback(
	func():
		_on_tentacle_reached_hole(tentacle)
	)
	# Reverse
	tween.tween_method(
		func(t):
			target.global_position = quadratic_bezier(start_pos, control, hole_bottom, t),
		1.0,
		0.0,
		duration
	)

func _on_tentacle_reached_hole(tentacle: Node) -> void:
	print("Tentacle reached hole:", tentacle.name)
	# grab item
	# play sound
	# spawn particles
	# lock tentacle state


func quadratic_bezier(p0: Vector2, p1: Vector2, p2: Vector2, t: float) -> Vector2:
	var q0 := p0.lerp(p1, t)
	var q1 := p1.lerp(p2, t)
	return q0.lerp(q1, t)
