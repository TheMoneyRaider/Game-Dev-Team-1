extends Node2D

@onready var player = $".."
var weapon_direction = Vector2(1,0)
var weapon_type = ""
var flip = 1

func _process(_delta: float):
	match weapon_type:
		"Mace":
			rotation = (flip * weapon_direction).angle()
		_:
			rotation = weapon_direction.angle() + + PI / 2

func flip_direction():
	flip *= -1
