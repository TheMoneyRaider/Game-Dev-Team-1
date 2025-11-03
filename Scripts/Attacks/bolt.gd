extends Area2D

var direction = Vector2.RIGHT
var speed = 0
var damage = 0
var lifespan = 1
var c_owner: Node = null
var initial_speed = 0
var initial_damage = 0

func _ready():
	rotation = direction.angle() + PI/2
	await get_tree().create_timer(lifespan).timeout
	queue_free()

func _process(delta):
	position += direction * speed * delta

func _on_body_entered(body):
	if body == c_owner:
		return
	else:
		print("hit!")
	queue_free()

func deflect(hit_direction, hit_speed):
	direction = hit_direction
	rotation = direction.angle() + PI/2
	damage = round(damage * ((hit_speed + speed) / speed))
	speed = speed + hit_speed
