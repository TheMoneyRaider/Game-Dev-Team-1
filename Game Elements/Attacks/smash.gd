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
	if(!hit_nodes.has(body)):
		if(apply_damage(body)):
			pierce -= 1
			hit_nodes[body] = null
	if pierce == -1:
		queue_free()
		
func apply_damage(body : Node) -> bool:
	if c_owner.has_method("swap_color"):
		if body.has_method("swap_color"):
			return false
		elif body.has_method("take_damage"):
			print("hit enemy?")
			body.take_damage(damage,c_owner,direction)
			return true				
	else:
		if !body.has_method("swap_color"):
			return false
		elif body.has_method("take_damage"):
			print("hit enemy?")
			body.take_damage(damage,c_owner,direction)
			return true
	return false

func _on_area_entered(area: Area2D) -> void:
	if area.has_method("deflect"):
		area.deflect(direction, hit_force)
		area.c_owner = c_owner
		area.hit_nodes = {}
