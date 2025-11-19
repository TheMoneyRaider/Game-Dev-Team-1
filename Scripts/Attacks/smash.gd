extends Area2D

var direction = Vector2.RIGHT
@export var speed = 0
@export var damage = 3
@export var lifespan = .5
@export var hit_force = 100
@export var start_lag = 0
@export var cooldown = .5
var c_owner: Node = null

func _ready():
	await get_tree().create_timer(lifespan).timeout
	queue_free()

func _process(delta):
	position += direction * speed * delta

func _on_body_entered(body):
	if c_owner.has_method("swap_color"):
		if body.has_method("swap_color"):
			return
		elif body.has_method("take_damage"):
			body.take_damage(damage)
		else:
			print("plonk!")
	else:
		if !body.has_method("swap_color"):
			return
		elif body.has_method("take_damage"):
			body.take_damage(damage)
		else:
			print("plonk!")
	queue_free()

func _on_area_entered(area: Area2D) -> void:
	if area.has_method("deflect"):
		area.deflect(direction, hit_force)
		area.c_owner = c_owner
