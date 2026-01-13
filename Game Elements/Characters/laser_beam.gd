extends Node2D

@export var power_curve : Curve      # organic fade in/out
@export var power_time := 0.5        # seconds to fully charge
@export var decay_time := 0.5        # seconds to fully turn off

@export var laser_width := 8.0
@export var color := Color(1, 0, 0)

var A : Vector2
var B : Vector2

var powering := 0.0        # 0–1 (power up)
var powering_down := 0.0   # 0–1 (power down)
var active := false

# Cache references
@onready var above : Line2D = $LaserAbove
@onready var below : Line2D = $LaserBelow


func _ready():
	above.width = laser_width
	below.width = laser_width
	above.default_color = color
	below.default_color = color
	hide_laser()


func fire_laser(from_point : Vector2, to_point : Vector2):
	A = from_point
	B = to_point
	print(A)
	print(B)
	active = true
	powering = 0.0
	powering_down = -1.0
	show_laser()


func stop_laser():
	powering_down = 0.0

func _process(delta):
	if !active:
		return

	# Powering up
	if powering < 1.0:
		powering += delta / power_time
		powering = min(powering, 1.0)
	# idle until stop_laser() is called
	if powering >= 1.0 and powering_down < 0.0:
		pass
	# Powering down
	if powering_down >= 0.0:
		powering_down += delta / decay_time
		if powering_down > 1.0:
			hide_laser()
			active = false
			return

	# Final power factor (organic)
	var p := powering
	if powering_down > 0.0:
		p = 1.0 - powering_down

	p = power_curve.sample(p)  # organic shaping

	update_laser(p)

func update_laser(power_factor : float):
	above.clear_points()
	below.clear_points()

	above.add_point(A)
	above.add_point(B)
	above.width=(power_factor*laser_width)

	## Shrink laser toward center for powering up/down effect
	#var center := (A + B) * 0.5
	#var Ap := center.lerp(A, power_factor)
	#var Bp := center.lerp(B, power_factor)
#
	## Collect all Y boundaries (players, enemies)
	#var splits : Array = []
	#for body in get_tree().get_nodes_in_group("depth_entities"):
		#splits.append(body.global_position.y)
#
	## Always include endpoints (so sorting works)
	#splits.append(Ap.y)
	#splits.append(Bp.y)
#
	## Sort split Y levels
	#splits.sort()
#
	## Build subsegments
	#for i in range(splits.size() - 1):
		#var y1 = splits[i]
		#var y2 = splits[i+1]
#
		#var seg_start = point_at_y(Ap, Bp, y1)
		#var seg_end   = point_at_y(Ap, Bp, y2)
#
		#if seg_start == Vector2(-123456789,-123456789) or seg_end == Vector2(-123456789,-123456789):
			#continue
#
		## The midpoint defines whether this segment is above or below the player
		#var mid_y = (y1 + y2) * 0.5
		#var segment := [seg_start, seg_end]
#
		## Assign to correct line
		#if is_above_entities(mid_y):
			#above.points += PackedVector2Array(segment)
		#else:
			#below.points += PackedVector2Array(segment)

func point_at_y(Ap : Vector2, Bp : Vector2, target_y : float) -> Vector2:
	if (target_y < min(Ap.y, Bp.y)) or (target_y > max(Ap.y, Bp.y)):
		return Vector2(-123456789,-123456789)

	var t = (target_y - Ap.y) / (Bp.y - Ap.y)
	return Ap.lerp(Bp, t)


func is_above_entities(y : float) -> bool:
	for body in get_tree().get_nodes_in_group("depth_entities"):
		if y < body.global_position.y:
			return true
	return false

func show_laser():
	above.visible = true
	below.visible = true


func hide_laser():
	above.visible = false
	below.visible = false
