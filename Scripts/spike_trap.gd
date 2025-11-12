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
	while get_overlapping_bodies().size() > 0:
		await get_tree().process_frame
	anim.play("deactivate")
	await anim.animation_finished
	active = false

func _on_body_entered(body):
	if !active:
		if !running:
			activate()
			return
	if active and body.has_method("take_damage"):
		body.take_damage(3)
