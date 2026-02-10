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
			print(player.cooldowns[player.is_purple as int])
			rotation = weapon_direction.angle()+ PI / 2 - TAU*(player.cooldowns[player.is_purple as int] / .3)
		_:
			rotation = weapon_direction.angle() + + PI / 2

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
	
