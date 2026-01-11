extends Resource
class_name Weapon

# Exposed fields for editor
@export var type: String = "Error"
@export var cooldown_icon: Resource = preload("res://art/mace_bright.png")
@export var weapon_sprite: Resource = null
@export var num_attacks: int = 1
@export var attack_spread: float = 0
@export var attack_type: String = "smash"
@export var attack_scene: String = "res://Game Elements/Attacks/smash.tscn"


#
#func request_attacks(direction : Vector2, char_position : Vector2, hunter_boost : float ):
	#var attack_direction = direction.rotated(deg_to_rad(-attack_spread / 2))
	#if(num_attacks > 1):
		#for i in range(num_attacks):
			#var attack_position = attack_direction * 20 + char_position
			#emit_signal("attack_requested",attack, attack_position, attack_direction, hunter_boost)
			#attack_direction = attack_direction.rotated(deg_to_rad(attack_spread / (num_attacks-1)))
	#else:
		#var attack_position = attack_direction * 20 + char_position
		#emit_signal("attack_requested",attack, attack_position, attack_direction, hunter_boost)
#
#func modify_attribute(attribute_name : String, new_value):
	#match attribute_name.to_lower():
		#"speed":
			#attack.speed = new_value
		#"damage":
			#attack.damage = new_value
		#"lifespan":
			#attack.damage = new_value
		#"scene_location":
			#attack.scene_location = new_value
		#"hit_force":
			#attack.hit_force = new_value
		#"start_lag":
			#attack.start_lag = new_value
		#"cooldown":
			#attack.cooldown = new_value
		#"pierce":
			#attack.cooldown = new_value
		#_:
			#push_error("Attribute trying to modify does not exist.")
