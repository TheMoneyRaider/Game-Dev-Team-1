extends Control

@onready var BreakFX = $BreakFX
@onready var UI_Group = $SubViewportContainer/SubViewport/UI_Group


func _ready():
	randomize()
	await get_tree().process_frame
	await get_tree().process_frame
	explode_ui()

func explode_ui():
	UI_Group.visible = false

	# Capture UI texture
	var vp_tex = $SubViewportContainer/SubViewport.get_texture()
	var tex = ImageTexture.create_from_image(vp_tex.get_image())

	# Generate fragments
	var fragments_data = generate_jittered_grid_fragments(tex.get_size(),20,20)
	for frag_data in fragments_data:
		var frag = Node2D.new()
		frag.position = UI_Group.get_global_position()
		frag.set_script(preload("res://Game Elements/ui/break_fx.gd"))


		BreakFX.add_child(frag)
		frag.begin_break(size,frag_data,tex)

func rewind_ui():
	for f in BreakFX.get_children():
		f.begin_rewind()
	# Wait a bit before showing UI_Group again
	await get_tree().create_timer(1.6).timeout
	UI_Group.visible = true

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
