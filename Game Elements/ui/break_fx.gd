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

func begin_break(frag_data: Array, tex: Texture2D, ui_pos : Vector2, pulse_position : Vector2):
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
	start_pos = position
	var center = min_p  # use fragment's reference point
	var dist = center.distance_to(pulse_position)
	var direction = (center - pulse_position).normalized()
	##Random directional deviation
	#var max_angle = deg_to_rad(20.0)  #20° cone of variation
	#var angle_offset = randf_range(-max_angle, max_angle)
	#direction = direction.rotated(angle_offset)
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
				var move =Vector2(200/clamp((position-mouse_global).x,10,200),200/clamp((position-mouse_global).y,10,200))
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
			call_deferred("queue_free")
			
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
			if img.get_pixel(x, y).a > 0.0 and is_border(img,x,y,int(min_x),int(min_y),int(max_x),int(max_y)):
				points.append(Vector2i(x, y))
	if points.size()<=2:
		get_node("Area2D").queue_free()
		return

	#print(points)
	 # Generate convex hull if we have enough points
	var raw_outline = get_polygon_outline(points)
	raw_outline = simplify_polygon(raw_outline)
	print(raw_outline)
	collision.polygon = raw_outline
	if assigned_b!=[]:
		get_node("Area2D/CollisionPolygon2D").polygon = raw_outline
		add_to_group("ui_fragments")  # allow easy access to all button fragments
		get_node("Area2D").connect("input_event", Callable(self, "_on_fragment_input"))
	else:
		get_node("Area2D").queue_free()

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


func simplify_polygon(poly: PackedVector2Array) -> PackedVector2Array:
	if poly.size() < 3:
		return poly

	var simplified: Array[Vector2] = []
	var n := poly.size()

	for i in range(n):
		var prev = poly[(i - 1 + n) % n]
		var curr = poly[i]
		var next = poly[(i + 1) % n]

		# Compute cross product: if zero → collinear
		var cross = (curr.x - prev.x) * (next.y - curr.y) - (curr.y - prev.y) * (next.x - curr.x)

		if abs(cross) > 0.0001:			# not collinear → keep point
			simplified.append(curr)

	return PackedVector2Array(simplified)


func is_border(img : Image,x : int,y : int,min_x,min_y,max_x,max_y) -> bool:
	var w = img.get_width()
	var h = img.get_height()
	# Cardinal directions (right, left, down, up)
	var dirs := [ Vector2i(1,0), Vector2i(-1,0), Vector2i(0,1), Vector2i(0,-1) ]
	for d in dirs:
		var nx = x + int(d.x)
		var ny = y + int(d.y)

		# If neighbor is outside the *image* treat as transparent (border)
		if nx < 0 or nx >= w or ny < 0 or ny >= h:
			return true

		# If neighbor is outside the fragment bbox treat as transparent (border)
		if nx < min_x or nx > max_x or ny < min_y or ny > max_y:
			return true

		# If neighbor pixel alpha == 0 -> border
		if img.get_pixel(nx, ny).a <= 0.0:
			return true

	# none of the four cardinal neighbors are transparent
	return false

func get_polygon_outline(points: Array[Vector2i]) -> PackedVector2Array:
	if points.size() < 3:
		return PackedVector2Array(points)

	# 1. Compute centroid
	var center = Vector2i.ZERO
	for p in points:
		center += p
	center /= points.size()

	# 2. Sort points by angle around centroid (clockwise)
	points.sort_custom(func(a, b):
		var angle_a = atan2(a.y - center.y, a.x - center.x)
		var angle_b = atan2(b.y - center.y, b.x - center.x)
		return angle_a > angle_b   # reverse order = clockwise
	)

	# 3. Return as PackedVector2Array
	return PackedVector2Array(points)
