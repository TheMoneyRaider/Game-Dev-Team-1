extends Area2D

var direction = Vector2.RIGHT
var speed = 0
var damage = 0
var lifespan = 1
var c_owner: Node = null

func _ready():
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
