extends Area2D

var direction = Vector2.RIGHT
@export var speed = 300
@export var damage = 4
@export var lifespan = 1
@export var start_lag = 0
@export var cooldown = .5
@export var pierce = 1
var c_owner: Node = null
@export var hit_force = 0
var hit_nodes = {}
@export var wall_collision = true


func _ready():
	rotation = direction.angle() + PI/2
	await get_tree().create_timer(lifespan).timeout
	queue_free()

func _process(delta):
	position += direction * speed * delta

func _on_body_entered(body):
	if(!hit_nodes.has(body)):
		match Attack.apply_damage(body,c_owner,damage,direction):
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
