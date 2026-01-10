extends Area2D

var direction = Vector2.RIGHT
@export var speed = 60.0
#How fast the attack is moving
@export var damage = 1.0
#How much damage the attack will do
@export var lifespan = 1.0
#How long attack lasts in seconds before despawning
@export var hit_force = 0.0
#How much speed it adds to deflected objects
@export var start_lag = 0.0
#How much time after pressing attack does the attack start in seconds
@export var cooldown = .5
@export var pierce = 0.0
#How many enemies the attack will pierce through (-1 for inf)
var c_owner: Node = null
#If the attack can hit walls
@export var wall_collision = true
var hit_nodes = {}
#The attack type
@export var attack_type : String = ""
@export var deflectable : bool = false
@export var deflects : bool = false

var frozen := true


#Special Variables
var life = 0.0

#Multiplies the Speed, Damage, Lifespan adn Hit_Force of attack by given values
func mult(speed_mult, damage_mult = 1, lifespan_mult = 1, hit_force_mult = 1):
	self.speed = self.speed * speed_mult
	self.damage = self.damage * damage_mult
	self.lifespan = self.lifespan * lifespan_mult
	self.hit_force = self.hit_force * hit_force_mult 

func set_values(attack_speed = self.attack_speed, attack_damage = self.damage, attack_lifespan = self.lifespan, attack_hit_force = self.hit_force):
	self.speed = attack_speed
	self.damage = attack_damage
	self.lifespan = attack_lifespan
	self.hit_force = attack_hit_force

func _ready():
	frozen = true
	await get_tree().create_timer(start_lag).timeout
	frozen = false
	
	if attack_type == "death mark":
		if c_owner.is_purple:
			$Sprite2D.texture = preload("res://art/Sprout Lands - Sprites - Basic pack/Characters/dead_purple.png")
		else:
			$Sprite2D.texture = preload("res://art/Sprout Lands - Sprites - Basic pack/Characters/dead_orange.png")
	rotation = direction.angle() + PI/2

func _process(delta):
	if frozen:
		return
	position += direction * speed * delta
	life+=delta
	if attack_type == "smash":
		get_node("CollisionShape2D").shape.radius = lerp(8,16,life/lifespan)
	if life < lifespan:
		return
	if attack_type == "death mark":
		c_owner.die(true,true)
	queue_free()
	
func apply_damage(body : Node, n_owner : Node, damage_dealt : int, a_direction: Vector2) -> int:
	if n_owner.is_in_group("player") and body.is_in_group("player"):
		return 0
	if !n_owner.is_in_group("player") and !body.is_in_group("player"):
		return 0
	if body.has_method("take_damage"):
		body.take_damage(damage_dealt,n_owner,a_direction,self)
		return 1
	return -1
	

func _on_body_entered(body):
	if attack_type == "death mark":
		if body != c_owner and body.is_in_group("player"):
			c_owner.die(false)
		return
	
	if(!hit_nodes.has(body)):
		match apply_damage(body,c_owner,damage,direction):
			1:
				pierce -= 1
				hit_nodes[body] = null
			0:
				pass
			-1:
				pierce -= 1
				if(wall_collision):
					queue_free()
	if pierce == -1:
		queue_free()

func deflect(hit_direction, hit_speed):
	direction = hit_direction
	rotation = direction.angle() + PI/2
	damage = round(damage * ((hit_speed + speed) / speed))
	speed = speed + hit_speed

func _on_area_entered(area: Area2D) -> void:
	if area.is_in_group("attack") and area.deflectable == true:
		area.deflect(direction, hit_force)
		area.c_owner = c_owner
		area.hit_nodes = {}
		for area_intr in area.get_overlapping_areas():
			area._on_body_entered(area_intr)
