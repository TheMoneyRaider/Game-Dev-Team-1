extends Control

@onready var BreakFX = $BreakFX
@onready var UI_Group = $SubViewportContainer/SubViewport/UI_Group
@onready var frames = 0
@onready var exploaded = false
@onready var cooldown : float = 0.0
@onready var the_ui : Texture2D

func _ready():
	randomize()

func _process(delta):
	frames+=1
	if frames < 2:
		return
	if frames <3:
		# Capture UI texture
		var vp_tex = $SubViewportContainer/SubViewport.get_texture()
		the_ui = ImageTexture.create_from_image(vp_tex.get_image())
	cooldown -= delta
	if cooldown > 0:
		if cooldown <= 3*delta and !exploaded:
			UI_Group.visible = true
		return
	if !exploaded:
		UI_Group.visible = false
		print("explode")
		explode_ui()
		cooldown = randf_range(.5,8)
		exploaded =true
	else:
		print("rewind")
		cooldown = randf_range(2,6)
		rewind_ui(cooldown)
		exploaded =false

func explode_ui():


	# Generate fragments
	var fragments_data = generate_jittered_grid_fragments(the_ui.get_size(),20,20)
	for frag_data in fragments_data:
		var frag = Node2D.new()
		frag.set_script(preload("res://Game Elements/ui/break_fx.gd"))
		BreakFX.add_child(frag)
		frag.begin_break(the_ui.get_size(), frag_data, the_ui, UI_Group.global_position)

func rewind_ui(time : float):
	for f in BreakFX.get_children():
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
