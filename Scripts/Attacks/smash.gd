extends Area2D

var direction = Vector2.RIGHT
@export var speed = 0
@export var damage = 3
@export var lifespan = .5
@export var hit_force = 100
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

func _on_area_entered(area: Area2D) -> void:
	if area.has_method("deflect"):
		area.deflect(direction, hit_force)
