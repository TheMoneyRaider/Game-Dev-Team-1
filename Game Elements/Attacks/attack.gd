class_name Attack

var speed : float = 0.0
#How fast the attack is moving
var damage : int = 0
#How much damage the attack will do
var lifespan : float = 0
#How long attack lasts in seconds before despawning
var scene_location : String = ""
#Where the scene is located
var hit_force : float = 100
#How much speed it adds to deflected objects
var start_lag : float = 0
#How much time after pressing attack does the attack start in seconds
var cooldown : float = 0
#How many enemies the attack will pierce through (-1 for inf)
var pierce : int = 0

static func create_attack(t_scene_location : String, t_speed : float = 0, t_damage : int = 0,t_lifespan : float = 0, t_hit_force : float = 100, t_start_lag : float = 0, t_cooldown : float = 0, t_hunter_boost : float = 0.0, t_pierce : int = 0) -> Attack:
	var new_attack = Attack.new()
	new_attack.speed = t_speed
	new_attack.damage = t_damage * t_hunter_boost
	new_attack.lifespan = t_lifespan
	new_attack.scene_location = t_scene_location
	new_attack.hit_force = t_hit_force
	new_attack.start_lag = t_start_lag
	new_attack.cooldown = t_cooldown
	new_attack.pierce = t_pierce
	return new_attack
	
static func create_from_resource(t_scene_location : String, t_script : Resource):
	var new_attack = Attack.new()
	var temp_instance = t_script.new()
	new_attack.scene_location = t_scene_location
	new_attack.speed = temp_instance.speed
	new_attack.lifespan = temp_instance.lifespan
	new_attack.hit_force = temp_instance.hit_force
	new_attack.damage = temp_instance.damage
	new_attack.start_lag = temp_instance.start_lag
	new_attack.cooldown = temp_instance.cooldown
	new_attack.pierce = temp_instance.pierce
	temp_instance.queue_free()
	return new_attack

#Multiplies the Speed, Damage, Lifespan adn Hit_Force of attack by given values
func mult(speed_mult, damage_mult = 1, lifespan_mult = 1, hit_force_mult = 1):
	self.speed = self.speed * speed_mult
	self.damage = self.damage * damage_mult
	self.lifespan = self.lifespan * lifespan_mult
	self.hit_force = self.hit_force * hit_force_mult 

func set_values(attack_speed, attack_damage = self.damage, attack_lifespan = self.lifespan, attack_hit_force = self.hit_force):
	self.speed = attack_speed
	self.damage = attack_damage
	self.lifespan = attack_lifespan
	self.hit_force = attack_hit_force
	
static func apply_damage(body : Node, c_owner : Node, damage_dealt : int, direction: Vector2) -> int:
	if c_owner.has_method("swap_color"):
		if body.has_method("swap_color"):
			return 0
		elif body.has_method("take_damage"):
			print("hit enemy?")
			body.take_damage(damage_dealt,c_owner,direction)
			return 1				
	else:
		if !body.has_method("swap_color"):
			return 0
		elif body.has_method("take_damage"):
			print("hit enemy?")
			body.take_damage(damage_dealt,c_owner,direction)
			return 1
	return -1
