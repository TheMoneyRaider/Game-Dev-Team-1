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
	var fragments_data = generate_fast_voronoi_fragments(tex.get_size(),1000)
	for frag_data in fragments_data:
		var frag = Node2D.new()
		frag.position = UI_Group.get_global_position() + frag_data["rect"].position
		frag.set_script(preload("res://Game Elements/ui/break_fx.gd"))

		var poly = Polygon2D.new()
		poly.polygon = frag_data["polygon"]
		# map UVs to the sub-rectangle of the texture
		var uv = []
		for point in frag_data["polygon"]:
			uv.append(frag_data["rect"].position + point)
		poly.uv = uv

		poly.texture = tex
		frag.add_child(poly)

		BreakFX.add_child(frag)
		frag.begin_break()

func rewind_ui():
	for f in BreakFX.get_children():
		f.begin_rewind()
	# Wait a bit before showing UI_Group again
	await get_tree().create_timer(1.6).timeout
	UI_Group.visible = true

func generate_fast_voronoi_fragments(tex_size: Vector2, site_count: int, points_per_site: int = 10) -> Array:
	var fragments = []

	for i in site_count:
		# Random site within texture
		var site = Vector2(randf_range(0, tex_size.x), randf_range(0, tex_size.y))

		# Generate small random cloud around the site
		var points = []
		for j in points_per_site:
			points.append(site + Vector2(randf_range(-50,50), randf_range(-50,50)))

		# Compute convex hull → polygon
		var polygon = Geometry2D.convex_hull(points)
		if polygon.size() < 3:
			continue

		# Compute polygon center
		var center = Vector2.ZERO
		for pt in polygon:
			center += pt
		center /= polygon.size()

		# Convert polygon to local coordinates relative to center
		var local_poly = []
		for pt in polygon:
			local_poly.append(pt - center)

		# Compute bounding rect for UV mapping
		var min_x = INF
		var min_y = INF
		var max_x = -INF
		var max_y = -INF
		for pt in polygon:
			min_x = min(min_x, pt.x)
			min_y = min(min_y, pt.y)
			max_x = max(max_x, pt.x)
			max_y = max(max_y, pt.y)
		var rect = Rect2(Vector2(min_x, min_y), Vector2(max_x - min_x, max_y - min_y))

		# Add fragment data
		fragments.append({
			"polygon": local_poly,
			"center": center,
			"rect": rect
		})

	return fragments
