extends Node2D

var start_pos: Vector2
var start_rot: float
var velocity: Vector2
var rot_vel: float
var breaking: bool = false
var rewinding: bool = false
var rewind_time: float = 0.0
var rewind_duration: float = 1.5

func begin_break():
	breaking = true
	rewinding = false
	start_pos = position
	start_rot = rotation
	velocity = Vector2(randf_range(-300,300), randf_range(-300,300))
	rot_vel = randf_range(-2.0, 2.0)
	set_process(true)

func begin_rewind(duration := 1.5):
	rewinding = true
	breaking = false
	rewind_duration = duration
	rewind_time = 0.0
	set_process(true)

func _process(delta):
	pass
	#if breaking:
		#velocity.y += 500 * delta  # gravity
		#position += velocity * delta
		#rotation += rot_vel * delta
	#elif rewinding:
		#rewind_time += delta
		#var t = clamp(rewind_time / rewind_duration, 0, 1)
		#t = t * t * (3 - 2*t)  # smoothstep
		#position = position.lerp(start_pos, t)
		#rotation = lerp(rotation, start_rot, t)
		#if t >= 1.0:
			#call_deferred("queue_free")
