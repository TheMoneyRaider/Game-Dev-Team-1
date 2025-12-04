extends Area2D

@onready var dead_player = $Sprite2D

var direction = Vector2.RIGHT
@export var speed = 0
@export var damage = 0
@export var lifespan = 10
@export var hit_force = 0
@export var start_lag = 0
@export var cooldown = 0
@export var pierce = -1
var c_owner: Node = null
@onready var orange_texture = preload("res://art/Sprout Lands - Sprites - Basic pack/Characters/dead_orange.png")
@onready var purple_texture = preload("res://art/Sprout Lands - Sprites - Basic pack/Characters/dead_purple.png")


func _ready():
	if c_owner.is_purple:
		dead_player.texture = purple_texture
	else:
		dead_player.texture = orange_texture
	await get_tree().create_timer(lifespan).timeout
	c_owner.die(true,true)
	queue_free()

func _process(delta):
	position += direction * speed * delta

func _on_body_entered(body):
	if body == c_owner:
		pass
	elif body.has_method("swap_color"):
		c_owner.die(false)
	else:
		return
	queue_free()
