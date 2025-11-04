class_name Attack

var use_scene_defaults = true
#If the attack spawner should use scene defaults, or 
var direction := Vector2(0,0)
#The direction the attack goes
var speed : float = 0.0
#How fast the attack is moving
var damage : int = 0
#How much damage the attack will do
var position := Vector2(0,0)
#Where the attack will originate from
var lifespan : float = 0
#How long attack lasts in seconds before despawning
var scene_location : String = ""
#Where the scene is located
var hit_force : float = 100
#How much speed it adds to deflected objects

static func create_attack(t_scene_location : String, t_direction : Vector2, t_position : Vector2, t_use_scene_defaults = true, t_speed : float = 0, t_damage : int = 0,t_lifespan : float = 0, t_hit_force : float = 100) -> Attack:
	var new_attack = Attack.new()
	new_attack.use_scene_defaults = t_use_scene_defaults
	new_attack.direction = t_direction
	new_attack.speed = t_speed
	new_attack.damage = t_damage
	new_attack.position = t_position
	new_attack.lifespan = t_lifespan
	new_attack.scene_location = t_scene_location
	new_attack.hit_force = t_hit_force
	return new_attack
