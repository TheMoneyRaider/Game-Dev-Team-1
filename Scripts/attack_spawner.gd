extends Node

func _ready():
	if get_parent().has_signal("attack_requested"):
		get_parent().connect("attack_requested", Callable(self,"_on_attack_requested"))

func _on_attack_requested(requested_attack : Attack):
	var character = get_parent()
	var scene: PackedScene = character.attack_scene
	if scene:
		var new_attack = scene.instantiate()
		new_attack.global_position = requested_attack.position
		new_attack.direction = requested_attack.direction
		new_attack.speed = requested_attack.speed
		new_attack.damage = requested_attack.damage
		new_attack.lifespan = requested_attack.lifespan
		new_attack.c_owner = character
		get_tree().current_scene.add_child(new_attack)
		
