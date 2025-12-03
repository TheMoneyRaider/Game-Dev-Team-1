extends Node2D

var start_pos: Vector2
var rewind_pos: Vector2
var velocity: Vector2
var rot_vel: float
var breaking: bool = false
var rewinding: bool = false
var rewind_time: float = 0.0
var rewind_duration: float = 1.5
var highlight_color : Color = Color(1,1,1,0.5)
var normal_color : Color = Color(1,1,1,1)

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

	#Position this Node2D in world space (must add UI_Group offset)
	position = ui_pos + min_p

	# Polygon2D
	var poly = Polygon2D.new()
	poly.position = Vector2.ZERO
	poly.offset = Vector2.ZERO
	poly.texture = tex
	poly.polygon = local_points
	poly.uv = frag_data
	add_child(poly)

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
	set_process(true)

func begin_rewind(duration := 1.5):
	rewinding = true
	breaking = false
	rewind_duration = duration
	rewind_time = 0.0
	set_process(true)
	rewind_pos = position

func _ready():
	set_process_input(true)

func _process(delta):
	if breaking:
		position += velocity * delta
	elif rewinding:
		rewind_time += delta
		var t = clamp(rewind_time / rewind_duration, 0, 1)
		t = t * t * (3 - 2*t)  # smoothstep
		position = rewind_pos.lerp(start_pos, t)
		if t >= 1.0:
			call_deferred("queue_free")
			
func add_interactive_area(frag_poly: Array):
	var area = Area2D.new()
	area.input_pickable = true
	area.collision_layer = 1
	area.collision_mask = 1
	
	var collision = CollisionPolygon2D.new()
	var local_poly = []
	for p in frag_poly:
		local_poly.append(p - position)
	collision.polygon = local_poly
	area.add_child(collision)
	add_child(area)
	add_to_group("ui_fragments")  # allow easy access to all button fragments
	area.connect("input_event", Callable(self, "_on_fragment_input"))


func _on_fragment_input(viewport, event, shape_idx):
	# Get global mouse position
	var mouse_global = event.global_position
	var fragment_displacement = position - start_pos
	var mouse_original_space = mouse_global - fragment_displacement
	
	if event is InputEventMouseButton and event.pressed:
		# Iterate over buttons
		for button in get_tree().get_nodes_in_group("ui_buttons"):
			# Button's global rect
			var rect = button.get_global_rect()
			# Check if mouse is inside the button rect
			if rect.has_point(mouse_original_space):
				button.emit_signal("pressed")
				break
			
	elif event is InputEventMouseMotion:
		# Iterate over buttons
		for button in get_tree().get_nodes_in_group("ui_buttons"):
			# Button's global rect
			var rect = button.get_global_rect()
			# Check if mouse is inside the button rect
			if rect.has_point(mouse_original_space):
				for frag in get_tree().get_nodes_in_group("ui_fragments"):
					if frag.has_button(button):
						frag.get_child(0).modulate = highlight_color
					else:
						frag.get_child(0).modulate = normal_color

func has_button(button : Node) -> bool:
	var poly_node = get_child(0)
	for p in poly_node.polygon:
		var global_point = position + p
		if button.get_global_rect().has_point(global_point):
			return true
	return false
