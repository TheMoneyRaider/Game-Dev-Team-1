class_name Attack

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

static func create_attack(t_direction : Vector2, t_speed : float, t_damage : int, t_position : Vector2, t_lifespan) -> Attack:
	var new_attack = Attack.new()
	new_attack.direction = t_direction
	new_attack.speed = t_speed
	new_attack.damage = t_damage
	new_attack.position = t_position
	new_attack.lifespan = t_lifespan
	return new_attack
