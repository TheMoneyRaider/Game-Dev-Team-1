extends RigidBody2D


@onready var parent = get_parent()

@export var force_strength := 8.0
@export var player: Node2D


func _ready():
	player = parent.c_owner
	apply_impulse(parent.direction *parent.speed)


func _physics_process(_delta: float) -> void:
	parent.global_position =  global_position
	var rot = global_rotation
	parent.rotation = global_rotation
	global_rotation = rot
	
	var dir = (player.global_position - global_position).normalized()
	var desired = dir * force_strength
	linear_velocity = linear_velocity.lerp(desired, 0.1)
