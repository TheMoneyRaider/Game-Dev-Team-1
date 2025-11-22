extends Area2D

var direction = Vector2.RIGHT
@export var speed = 300
@export var damage = 10
@export var lifespan = 1
@export var start_lag = 0
@export var cooldown = .5
var c_owner: Node = null
@export var hit_force = 0

func _ready():
	rotation = direction.angle() + PI/2
	await get_tree().create_timer(lifespan).timeout
	queue_free()

func _process(delta):
	position += direction * speed * delta

func _on_body_entered(body):
	if c_owner.has_method("swap_color"):
		if body.has_method("swap_color"):
			return
		elif body.has_method("take_damage"):
			print("hit enemy?")
			body.take_damage(damage)
		else:
			print("hit!")
	else:
		if !body.has_method("swap_color"):
			return
		elif body.has_method("take_damage"):
			print("hit enemy?")
			body.take_damage(damage)
		else:
			print("hit!")
	queue_free()

func deflect(hit_direction, hit_speed):
	direction = hit_direction
	rotation = direction.angle() + PI/2
	damage = round(damage * ((hit_speed + speed) / speed))
	speed = speed + hit_speed
