extends Resource
class_name Weapon

# Exposed fields for editor
@export var type: String = "Error"
@export var cooldown_icon: Resource = preload("res://art/mace_bright.png")
@export var weapon_sprite: Resource = null
@export var num_attacks: int = 1

@export var random_spread : bool = true
@export var attack_spread: float = 0

@export var attack_type: String = "smash"
@export var attack_scene: String = "res://Game Elements/Attacks/smash.tscn"

var speed = 60.0
#How fast the attack is moving
var damage = 1.0
#How much damage the attack will do
var lifespan = 1.0
#How long attack lasts in seconds before despawning
var hit_force = 0.0
#How much speed it adds to deflected objects
var start_lag = 0.0
#How much time after pressing attack does the attack start in seconds
var cooldown = .5
var pierce = 0.0
#How many enemies the attack will pierce through (-1 for inf)
var c_owner: Node = null
#If the attack can hit walls

static func create_weapon(resource_location : String, current_owner : Node2D):
	var new_weapon = load(resource_location)
	var attack_instance = load(new_weapon.attack_scene).instantiate()
	new_weapon.speed = attack_instance.speed
	new_weapon.damage = attack_instance.damage
	new_weapon.lifespan = attack_instance.lifespan
	new_weapon.hit_force = attack_instance.hit_force
	new_weapon.start_lag = attack_instance.start_lag
	new_weapon.cooldown = attack_instance.cooldown
	new_weapon.pierce = attack_instance.pierce
	new_weapon.c_owner = current_owner
	attack_instance.queue_free()
	#Modify sprites in c_owner
	
	return new_weapon

func request_attacks(direction : Vector2, char_position : Vector2):
	var attack_direction
	if(random_spread):
		attack_direction = direction.rotated(deg_to_rad((-attack_spread / 2) + randf_range(0,attack_spread)))
	else:
		attack_direction = direction.rotated(deg_to_rad(-attack_spread / 2))
	if(num_attacks > 1):
		for i in range(num_attacks):
			#If there is weapon specific interactions write that here
			match type:
				"Shotgun":
					speed = randi_range(150,250)
				_:
					pass
			var attack_position = attack_direction * 20 + char_position
			spawn_attack(attack_direction,attack_position)
			if(random_spread):
				attack_direction = direction.rotated(deg_to_rad((-attack_spread / 2) + randf_range(0,attack_spread)))
			else:
				attack_direction = attack_direction.rotated(deg_to_rad(attack_spread / (num_attacks-1)))
			
	else:
		var attack_position = attack_direction * 20 + char_position
		spawn_attack(attack_direction,attack_position)

func spawn_attack(attack_direction : Vector2, attack_position : Vector2):
	var instance = load(attack_scene).instantiate()
	instance.direction = attack_direction
	instance.global_position = attack_position
	instance.c_owner = c_owner
	instance.speed = speed
	instance.damage = damage * (1+ c_owner.hunter_percent_boost()/100)
	instance.lifespan = lifespan
	instance.hit_force = hit_force
	instance.start_lag = start_lag
	instance.cooldown = cooldown
	instance.pierce = pierce
	c_owner.get_tree().get_root().get_node("LayerManager").room_instance.add_child(instance)
