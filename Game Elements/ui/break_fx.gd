extends Node2D

var start_pos: Vector2
var start_rot: float
var velocity: Vector2
var rot_vel: float
var breaking: bool = false
var rewinding: bool = false
var rewind_time: float = 0.0
var rewind_duration: float = 1.5

func begin_break(size : Vector2, frag_data : Array, tex : Texture2D):
	var poly = Polygon2D.new()
	# map UVs to the sub-rectangle of the texture
	var uv = []
	var local_points = []
	for point in frag_data:
		uv.append(point)
	var average_position = Vector2.ZERO
	for point in frag_data:
		average_position+=point
		local_points.append(point - average_position)
	average_position/=frag_data.size()
	poly.uv = uv

	poly.polygon = local_points
	poly.position = average_position
	poly.offset = Vector2.ZERO
	poly.texture = tex
	add_child(poly)
	
	breaking = true
	rewinding = false
	start_pos = position
	start_rot = rotation
	var dist = average_position.distance_to(size/2)
	var direction = (average_position - size/2).normalized()
	velocity = direction * (dist*dist*.00006)
	print(velocity)
	set_process(true)

func begin_rewind(duration := 1.5):
	rewinding = true
	breaking = false
	rewind_duration = duration
	rewind_time = 0.0
	set_process(true)

func _process(delta):
	if breaking:
		position += velocity * delta
	elif rewinding:
		rewind_time += delta
		var t = clamp(rewind_time / rewind_duration, 0, 1)
		t = t * t * (3 - 2*t)  # smoothstep
		position = position.lerp(start_pos, t)
		rotation = lerp(rotation, start_rot, t)
		if t >= 1.0:
			call_deferred("queue_free")
