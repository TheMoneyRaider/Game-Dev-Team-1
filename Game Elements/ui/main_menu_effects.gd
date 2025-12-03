extends Control

@onready var BreakFX = $BreakFX
@onready var UI_Group = $SubViewportContainer/SubViewport/UI_Group
@onready var exploaded = false
@onready var cooldown : float = 0.0
@onready var the_ui : Texture2D

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
	cooldown = randf_range(.5,4)
	exploaded =true

func _process(delta):
	cooldown -= delta
	if cooldown > 0:
		if cooldown <= 3*delta and !exploaded:
			UI_Group.visible = true
		return
	if !exploaded:
		UI_Group.visible = false
		print("explode")
		explode_ui()
		cooldown = randf_range(.5,4)
		exploaded =true
	else:
		print("rewind")
		cooldown = randf_range(2,5)
		rewind_ui(cooldown)
		exploaded =false

func explode_ui():
	var pulse_position = Vector2(randi_range(int(the_ui.get_size().x*1.0/6.0),int(the_ui.get_size().x*5.0/6.0)),
								randi_range(int(the_ui.get_size().y*1.0/6.0),int(the_ui.get_size().y*5.0/6.0)))
	var button_bounds = {}
	for button in $SubViewportContainer/SubViewport/UI_Group/VBoxContainer.get_children():
		if button is Button:
			button_bounds[button] = button.get_global_rect()
	# Generate fragments
	var fragments_data = generate_jittered_grid_fragments(the_ui.get_size(),100,20)
	for frag_data in fragments_data:
		var frag = load("res://Game Elements/ui/break_frag.tscn").instantiate()
		BreakFX.add_child(frag)
		
		# Determine if this fragment belongs to a button
		var assigned_button = find_button_for_fragment(frag_data, button_bounds)
		
		# Initialize fragment script
		frag.begin_break(frag_data, the_ui, UI_Group.global_position, pulse_position)
		
		# Add clickable area if belongs to a button
		if assigned_button:
			frag.add_interactive_area(frag_data, assigned_button)

func rewind_ui(time : float):
	for f in BreakFX.get_children():
		if "begin_rewind" in f:
			f.begin_rewind(time)

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
			fragments.append(poly)
	return fragments
	
func jitter_point(size : Vector2, p : float, jitter : float, is_x : bool) -> float:
	return max(0,min(size.x, p+randf_range(-jitter, jitter))) if is_x else max(0,min(size.y, p+randf_range(-jitter, jitter)))
	
func find_button_for_fragment(frag_poly: Array, button_bounds: Dictionary) -> Button:
	var centroid = Vector2.ZERO
	for p in frag_poly:
		centroid += p
	centroid /= frag_poly.size()
	for button in button_bounds.keys():
		if button_bounds[button].has_point(centroid):
			return button
	return null
