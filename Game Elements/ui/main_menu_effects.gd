extends Control

@onready var BreakFX = $BreakFX
@onready var UI_Group = $SubViewportContainer/SubViewport/UI_Group
@onready var exploaded = false
@onready var cooldown : float = 0.0
@onready var disrupt_cooldown : float = 0.0
@onready var the_ui : Texture2D
@onready var is_disruptive : bool = true
@onready var is_purple: bool = true
var input_device = "key"

#var highlight_color : Color = Color(1,1,1,0.5)
#var normal_color : Color = Color(1,1,1,1)

func _ready():
	randomize()
	cooldown = 10.0
	await get_tree().process_frame
	await get_tree().process_frame
	# Capture the UI once
	var vp_tex = $SubViewportContainer/SubViewport.get_texture()
	the_ui = ImageTexture.create_from_image(vp_tex.get_image())
	UI_Group.visible = false
	print("explode")
	explode_ui()
	cooldown = randf_range(2,4)
	exploaded =true

func _process(delta):
	if Input.is_action_just_pressed("swap_" + input_device):
		is_purple=!is_purple
		disrupt_cooldown = 10.0
		is_disruptive = false
	
	#button_checks()
	cooldown -= delta
	disrupt_cooldown -= delta
	
	if disrupt_cooldown < 0 and !is_disruptive:
		is_disruptive = true
	
	if cooldown > 0:
		if cooldown <= 3*delta and !exploaded:
			UI_Group.visible = true
		return
	if !exploaded:
		UI_Group.visible = false
		print("explode")
		explode_ui()
		cooldown = randf_range(2,4)
		exploaded =true
	else:
		print("rewind")
		cooldown = 1
		rewind_ui(cooldown)
		exploaded =false



#var last_hovered_button : Node = null
#func button_checks():
	#var mouse_global = get_viewport().get_mouse_position()
	#var hovered_button : Node = null
#
	## Loop through fragments to check if mouse is over their polygon
	#for frag in get_tree().get_nodes_in_group("ui_fragments"):
		#var poly_node = frag.get_child(0)
		#var local_mouse = mouse_global - frag.position
		#if Geometry2D.is_point_in_polygon(local_mouse, poly_node.polygon):
			#for button in frag.assigned_buttons:
				#if Geometry2D.is_point_in_polygon(local_mouse, get_button_polygon(button, frag.start_pos)):
					#hovered_button = button
					#break
			#break
	## Only update if hovered button changed
	#if hovered_button != last_hovered_button:
		#last_hovered_button = hovered_button
		#for frag in get_tree().get_nodes_in_group("ui_fragments"):
			#frag.update_highlights(hovered_button)

func get_button_polygon(button: Button, frag_start_pos: Vector2) -> Array:
	var rect = button.get_global_rect()
	return [
		rect.position - frag_start_pos,
		rect.position + Vector2(rect.size.x, 0) - frag_start_pos,
		rect.position + rect.size - frag_start_pos,
		rect.position + Vector2(0, rect.size.y) - frag_start_pos
	]



# Recursive helper to collect leaf nodes
func collect_leaf_children(node: Node, bounds: Dictionary) -> void:
	for child in node.get_children():
		if child.get_child_count() == 0:
			# Leaf node, add to dictionary
			if child is Control and child.get_class() == "Control":
				continue
			bounds[child] = child.get_global_rect()
		else:
			# Recurse into children
			collect_leaf_children(child, bounds)

func explode_ui():
	var pulse_position = Vector2(randi_range(int(the_ui.get_size().x*1.0/6.0),int(the_ui.get_size().x*5.0/6.0)),
								randi_range(int(the_ui.get_size().y*1.0/6.0),int(the_ui.get_size().y*5.0/6.0)))
	# Get all leaf children of the SubViewport
	var ui_bounds = {}
	collect_leaf_children($SubViewportContainer/SubViewport, ui_bounds)
		
	var button_bounds = {}
	for button in $SubViewportContainer/SubViewport/UI_Group/VBoxContainer.get_children():
		if button is Button:
			button_bounds[button] = button.get_global_rect()
	# Generate fragments
	var fragments_data = generate_jittered_grid_fragments(the_ui.get_size(),10,20)
	for frag_data in fragments_data:
		# Only create a fragment if it overlaps any UI element
		if not overlaps_any_ui_element(frag_data, ui_bounds):
			continue
		var frag = load("res://Game Elements/ui/break_frag.tscn").instantiate()
		BreakFX.add_child(frag)
		
		# Determine if this fragment belongs to a button
		var assigned_buttons = find_button_for_fragment(frag_data, button_bounds)
		
		# Initialize fragment script
		frag.begin_break(frag_data, the_ui, UI_Group.global_position, pulse_position)
		
		# Add clickable area if belongs to a button
		frag.add_interactive_area(frag_data,assigned_buttons)
	print(BreakFX.get_child_count())

func rewind_ui(time : float):
	for f in BreakFX.get_children():
		if "begin_rewind" in f:
			f.begin_rewind(time)

func overlaps_any_ui_element(frag_poly: Array, button_bounds: Dictionary) -> bool:
	for p in frag_poly:
		var global_point = UI_Group.global_position + p
		for rect in button_bounds.values():
			if rect.has_point(global_point):
				return true
	return false

func generate_jittered_grid_fragments(size: Vector2, grid_x: int, grid_y: int, jitter: float = 20.0) -> Array:
	var fragments = []
	var cell_w = size.x / grid_x
	var cell_h = size.y / grid_y
	var points = []
	for x in range(grid_x + 1):
		points.append([])
		for y in range(grid_y + 1):
			points[x].append(Vector2.ZERO)
	var stop = false
	for y in range(grid_y+1):
		for x in range(grid_x+1):
			var px = x * cell_w
			var py = y * cell_h
			for vec in [Vector2(0,0),Vector2(0,size.y),Vector2(size.x,0),Vector2(size.x,size.y)]:
				if Vector2(px,py)==vec:
					points[x][y]= Vector2(px,py)
					stop = true
					break
			if stop:
				stop = false
			elif px == size.x or px == 0:
				points[x][y]= Vector2(px,jitter_point(size,py,jitter, false))
			elif py == size.y or py == 0:
				points[x][y]= Vector2(jitter_point(size,px,jitter, true),py)
			else:
				points[x][y]= Vector2(jitter_point(size,px,jitter, true),jitter_point(size,py,jitter, false))
	for y in range(grid_y):
		for x in range(grid_x):
			# Convex hull to ensure valid polygon
			var poly = Geometry2D.convex_hull([points[x][y],points[x+1][y],points[x+1][y+1],points[x][y+1]])
			# Remove last point if it equals the first
			if poly.size() > 1 and poly[0] == poly[poly.size() - 1]:
				poly.remove_at(poly.size() - 1)
			fragments.append(poly)
	return fragments
	
func jitter_point(size : Vector2, p : float, jitter : float, is_x : bool) -> float:
	return max(0,min(size.x, p+randf_range(-jitter, jitter))) if is_x else max(0,min(size.y, p+randf_range(-jitter, jitter)))
	
func find_button_for_fragment(frag_poly: Array, button_bounds: Dictionary) -> Array[Button]:
	var overlapping_buttons : Array[Button]= []
	for button in button_bounds.keys():
		var rect = button_bounds[button]
		for p in frag_poly:
			var global_point = p + UI_Group.global_position
			if rect.has_point(global_point):
				overlapping_buttons.append(button)
				break
	return overlapping_buttons
