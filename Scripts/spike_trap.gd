extends Area2D

@onready var anim: AnimationPlayer = $AnimationPlayer
@onready var hitbox: CollisionShape2D = $CollisionShape2D

var active: bool = false
var running: bool = false

func _ready():
	connect("body_entered", Callable(self, "_on_body_entered"))

func activate():
	anim.play("activate")
	await anim.animation_finished
	active = true
	var num_damage_bodies = 0
	while num_damage_bodies != 0:
		num_damage_bodies = 0
		for body in get_overlapping_bodies():
			if body.has_method("take_damage"):
				num_damage_bodies+=1
				break
		await get_tree().process_frame
	anim.play("deactivate")
	await anim.animation_finished
	active = false

func _on_body_entered(body):
	if !active:
		if !running and body.has_method("take_damage"):
			activate()
			return
	elif body.has_method("take_damage"):
		body.take_damage(3)
