extends Node2D

var start_pos: Vector2
var rewind_pos: Vector2
var velocity: Vector2
var rot_vel: float
var breaking: bool = false
var rewinding: bool = false
var rewind_time: float = 0.0
var rewind_duration: float = 1.5

func begin_break(size: Vector2, frag_data: Array, tex: Texture2D, ui_pos : Vector2):
	# 1. Compute fragment's top-left corner (min bounds)
	var min_p = frag_data[0]
	for p in frag_data:
		min_p.x = min(min_p.x, p.x)
		min_p.y = min(min_p.y, p.y)

	# 2. Convert polygon vertices into local space
	var local_points = []
	for p in frag_data:
		local_points.append(p - min_p)

	# 3. Position this Node2D in world space (must add UI_Group offset)
	position = ui_pos + min_p

	# 4. Create the Polygon2D
	var poly = Polygon2D.new()
	poly.position = Vector2.ZERO
	poly.offset = Vector2.ZERO
	poly.texture = tex

	# UVs stay in texture-space
	poly.uv = frag_data

	# Geometry is local
	poly.polygon = local_points

	add_child(poly)

	# --- EXPLOSION MOTION ---
	breaking = true
	rewinding = false

	start_pos = position

	var center = min_p  # use fragment's reference point
	var dist = center.distance_to(size / 2)
	var direction = (center - size / 2).normalized()
	#Random directional deviation
	var max_angle = deg_to_rad(20.0)  #20° cone of variation
	var angle_offset = randf_range(-max_angle, max_angle)
	direction = direction.rotated(angle_offset)
	
	
	velocity = direction * (dist * dist * 0.00006)
	

	set_process(true)

func begin_rewind(duration := 1.5):
	rewinding = true
	breaking = false
	rewind_duration = duration
	rewind_time = 0.0
	set_process(true)
	rewind_pos = position

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
