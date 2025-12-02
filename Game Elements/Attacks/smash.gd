extends Area2D

var direction = Vector2.RIGHT
@export var speed = 0
@export var damage = 3
@export var lifespan = .5
@export var hit_force = 100
@export var start_lag = 0.05
@export var cooldown = .5
@export var pierce = -1
var c_owner: Node = null
var hit_nodes = {}


func _ready():
	await get_tree().create_timer(lifespan).timeout
	queue_free()

func _process(delta):
	position += direction * speed * delta

func _on_body_entered(body):
	print("hit type is ", body)
	
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
	if pierce == 0:
		queue_free()

func _on_area_entered(area: Area2D) -> void:
	if area.has_method("deflect"):
		area.deflect(direction, hit_force)
		area.c_owner = c_owner
