extends RigidBody2D

var start_pos: Vector2
var rewind_pos: Vector2
var rewind_rot: float
var velocity: Vector2
var rot_vel: float
var breaking: bool = false
var rewinding: bool = false
var rewind_time: float = 0.0
var rewind_duration: float = 1.5
var assigned_buttons : Array[Button] = []
#var highlight_nodes: Array = []
#
#var normal_color: Color = Color(1,1,1,1)
#var highlight_color: Color = Color(1,1,1,0.5)

func begin_break(frag_data: Array, tex: Texture2D, ui_pos : Vector2):
	#Compute fragment's top-left corner (min bounds)
	var min_p = frag_data[0]
	for p in frag_data:
		min_p.x = min(min_p.x, p.x)
		min_p.y = min(min_p.y, p.y)

	#Convert polygon vertices into local space
	var local_points = []
	for p in frag_data:
		local_points.append(p - min_p)

	freeze = true
	#Position this Node2D in world space (must add UI_Group offset)
	position = ui_pos + min_p
	start_pos = position
	freeze = false

	# Polygon2D
	var poly = Polygon2D.new()
	poly.position = Vector2.ZERO
	poly.offset = Vector2.ZERO
	poly.texture = tex
	poly.polygon = local_points
	poly.uv = frag_data
	poly.name = "Polygon2D"
	add_child(poly)

	#highlight_nodes.clear()
	#Motion
	breaking = true
	rewinding = false
	var center = min_p  # use fragment's reference point
	var dist = center.distance_to(get_viewport().get_mouse_position())
	dist = clamp(dist, 0, 1000)
	var direction = (center - get_viewport().get_mouse_position()).normalized()
	velocity = direction * (dist * dist * 0.00006)
	

func redo_break():
	rewind_time= 0.0
	rewind_duration= 1.5
	freeze = true
	velocity=Vector2.ZERO
	#Position this Node2D in world space
	freeze = false
	

	#Motion
	breaking = true
	rewinding = false
	var center = start_pos  # use fragment's reference point
	var dist = center.distance_to(get_viewport().get_mouse_position())
	var direction = (center - get_viewport().get_mouse_position()).normalized()
	dist = clamp(dist, 0, 1000)
	velocity = direction * (dist * dist * 0.00006)

func begin_rewind(duration := 1.5):
	rewinding = true
	breaking = false
	rewind_duration = duration
	rewind_time = 0.0
	rewind_pos = position
	rewind_rot = rotation
	freeze = true


func _physics_process(delta):
	if breaking:
		pass
		if get_parent().get_parent().is_disruptive:
			var mouse_global = get_viewport().get_mouse_position()
			if position.distance_to(mouse_global) < 100:
				var move =Vector2(10/clamp((position-mouse_global).x,10,200),10/clamp((position-mouse_global).y,10,200))
				if (position-mouse_global).x <= 0.0:
					move.x *= -1
				if (position-mouse_global).y <= 0.0:
					move.y *= -1
				velocity+= move
		linear_velocity = velocity
	elif rewinding:
		rewind_time += delta
		var t = clamp(rewind_time / rewind_duration, 0, 1)
		t = t * t * (3 - 2*t)  # smoothstep
		position = rewind_pos.lerp(start_pos, t)
		rotation = lerp(rewind_rot, 0.0, t)
		if t >= 1.0:
			redo_break()
			
func add_interactive_area(frag_poly: Array, assigned_b : Array):
	var poly_node = get_node("Polygon2D")
	var collision = get_node("CollisionPolygon2D")
	var img = poly_node.texture.get_image()
	
	# Compute bounding box of fragment in texture space
	var min_x = frag_poly[0].x
	var max_x = frag_poly[0].x
	var min_y = frag_poly[0].y
	var max_y = frag_poly[0].y
	for p in frag_poly:
		min_x = min(min_x, p.x)
		max_x = max(max_x, p.x)
		min_y = min(min_y, p.y)
		max_y = max(max_y, p.y)
	
	#print("Sizex: "+str(max_x-min_x)+" Sizey: "+str(max_y-min_y))
	
	var points: Array[Vector2i] = []
	var step = 1  # every 1 pixels
	for y in range(int(min_y), int(max_y)+1, step):
		for x in range(int(min_x), int(max_x)+1, step):
			if img.get_pixel(x, y).a > 0.0:
				points.append(Vector2i(x, y))
	if points.size()<=40:
		queue_free()
		return
	
	collision.polygon = poly_node.polygon
	if assigned_b!=[]:
		get_node("Area2D/CollisionPolygon2D").polygon = poly_node.polygon
		add_to_group("ui_fragments")  # allow easy access to all button fragments
		get_node("Area2D").connect("input_event", Callable(self, "_on_fragment_input"))

	assigned_buttons = assigned_b
	#poly_node.visible = false

var last_hovered_button : Node = null

func _on_fragment_input(_viewport, event, _shape_idx):
	# Get global mouse position
	var mouse_global = event.global_position
	var fragment_displacement = position - start_pos
	var mouse_original_space = mouse_global - fragment_displacement

	if event is InputEventMouseButton and event.pressed:
		# Iterate over buttons
		for button in assigned_buttons:
			if button.get_global_rect().has_point(mouse_original_space):
				button.emit_signal("pressed")
				break


func has_button(button : Node) -> bool:
	for b in assigned_buttons:
		if b == button:
			return true
	return false
