extends Line2D

@export var power_curve : Curve      # organic fade in/out
@export var power_time := 0.5        # seconds to fully charge
@export var decay_time := 0.5        # seconds to fully turn off

@export var laser_width := 8.0
@export var color := Color(1, 0, 0)


var powering := 0.0        # 0–1 (power up)
var powering_down := 0.0   # 0–1 (power down)
var active := false



func _ready():
	default_color = color
	hide_laser()


func fire_laser(from_point : Vector2, to_point : Vector2):
	add_point(from_point)
	add_point(to_point)
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

	width=(p*laser_width)


func show_laser():
	visible = true
func hide_laser():
	visible = false
