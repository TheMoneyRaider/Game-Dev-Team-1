extends Node2D

@onready var player = $".."
var weapon_direction = Vector2(1,0)
var weapon_type = ""
var flip = 1

var last_weapon_type = ""

func _process(_delta: float):
	if last_weapon_type != weapon_type:
		update_weapon_location()
	match weapon_type:
		"Mace":
			rotation = (flip * weapon_direction).angle()
		"L_Sword":
			rotation = weapon_direction.angle()+ PI / 2 - TAU* _cubic_bezier(0,.42, .58, 1.0,(player.cooldowns[player.is_purple as int] / .3))
		_:
			rotation = weapon_direction.angle() + + PI / 2

func _cubic_bezier(p0: float, p1: float, p2: float, p3: float, t: float):
	var q0 = lerp(p0, p1, t)
	var q1 = lerp(p2,p1, t)
	var q2 = lerp(p2,p3, t)

	var r0 = lerp(q0, q1, t)
	var r1 = lerp(q1, q2, t)

	var s = lerp(r0, r1, t)
	print(s)
	return s


func flip_direction():
	flip *= -1
	
func update_weapon_location():
	last_weapon_type = weapon_type
	match weapon_type:
		"Mace":
			$Sprite2D.position = Vector2(-8,-27)
		"L_Sword":
			$Sprite2D.position = Vector2(-16,-28)
		_:
			$Sprite2D.position = Vector2(0,0)
	
