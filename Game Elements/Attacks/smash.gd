extends Area2D

var direction = Vector2.RIGHT
@export var speed = 0
@export var damage = 3
@export var lifespan = .5
@export var hit_force = 100
@export var start_lag = 0.05
@export var cooldown = .5
@export var pierce = -1
@export var life = 0.0
@export var start_size = 8
@export var end_size = 16
var c_owner: Node = null
var hit_nodes = {}
@export var wall_collision = false


func _ready():
	#rotation = direction.angle() + PI/2
	await get_tree().create_timer(lifespan).timeout
	queue_free()

func _process(delta):
	life+=delta
	get_node("CollisionShape2D").shape.radius = lerp(start_size,end_size,life/lifespan)
	position += direction * speed * delta

func _on_body_entered(body):
	print("hit type is ", body)
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

func _on_area_entered(area: Area2D) -> void:
	if area.has_method("deflect"):
		area.deflect(direction, hit_force)
		area.c_owner = c_owner
		area.hit_nodes = {}
