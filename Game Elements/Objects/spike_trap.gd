extends Area2D

@onready var anim: AnimationPlayer = $AnimationPlayer
@onready var hitbox: CollisionShape2D = $CollisionShape2D

var active: bool = false
var running: bool = false
var tracked_bodies: Array = []

func _ready():
	connect("body_entered", Callable(self, "_on_body_entered"))
	connect("body_exited", Callable(self, "_on_body_exited"))

func activate():
	anim.play("activate")
	await anim.animation_finished
	active = true
	for body in tracked_bodies:
		body.take_damage(3, null)
	while !tracked_bodies.is_empty():
		await get_tree().process_frame
	anim.play("deactivate")
	await anim.animation_finished
	active = false

func _on_body_entered(body):
	if body.has_method("take_damage"):
		tracked_bodies.append(body)
	if !active:
		if !running and body.has_method("take_damage"):
			activate()
			return
	elif body.has_method("take_damage"):
		body.take_damage(3, null)

func _on_body_exited(body):
	if body in tracked_bodies:
		tracked_bodies.erase(body)
