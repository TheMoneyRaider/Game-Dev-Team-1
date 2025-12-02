extends Area2D

var direction = Vector2.RIGHT
@export var speed = 300
@export var damage = 2
@export var lifespan = 1
@export var start_lag = 0
@export var cooldown = .5
@export var pierce = 0
var c_owner: Node = null
@export var hit_force = 0
var hit_nodes = {}

func _ready():
	rotation = direction.angle() + PI/2
	await get_tree().create_timer(lifespan).timeout
	queue_free()

func _process(delta):
	position += direction * speed * delta

func _on_body_entered(body):
	
	if not is_instance_valid(c_owner):
		queue_free()
		return
	
	if c_owner.has_method("swap_color"):
		if body.has_method("swap_color"):
			return
		elif body.has_method("take_damage"):
			if(!hit_nodes.has(body)):
				print("hit enemy?")
				pierce -= 1
				body.take_damage(damage,c_owner,direction)
			else:
				hit_nodes[body] = null
	else:
		if !body.has_method("swap_color"):
			return
		elif body.has_method("take_damage"):
			if(!hit_nodes.has(body)):
				pierce -= 1
				print("hit enemy?")
				body.take_damage(damage,c_owner,direction)
			else:
				hit_nodes[body] = null
	if pierce == -1:
		queue_free()

func deflect(hit_direction, hit_speed):
	direction = hit_direction
	rotation = direction.angle() + PI/2
	damage = round(damage * ((hit_speed + speed) / speed))
	speed = speed + hit_speed
