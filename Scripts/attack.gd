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
#How much time after pressing attack does the attack start
var cooldown : float = 0
#How much time after pressing attack can you attack again

static func create_attack(t_scene_location : String, t_speed : float = 0, t_damage : int = 0,t_lifespan : float = 0, t_hit_force : float = 100, t_start_lag : float = 0, t_cooldown : float = 0) -> Attack:
	var new_attack = Attack.new()
	new_attack.speed = t_speed
	new_attack.damage = t_damage
	new_attack.lifespan = t_lifespan
	new_attack.scene_location = t_scene_location
	new_attack.hit_force = t_hit_force
	new_attack.start_lag = t_start_lag
	new_attack.cooldown = t_cooldown
	return new_attack
	
static func create_from_scene(t_scene_location):
	var scene = load(t_scene_location)
	var defaults = scene.instantiate()
	var new_attack = Attack.new()
	new_attack.scene_location = t_scene_location
	new_attack.speed = defaults.speed
	new_attack.lifespan = defaults.lifespan
	new_attack.hit_force = defaults.hit_force
	new_attack.damage = defaults.damage
	new_attack.start_lag = defaults.start_lag
	new_attack.cooldown = defaults.cooldown
	defaults.free()
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
