extends Node

func _ready():
	if get_parent().has_signal("attack_requested"):
		get_parent().connect("attack_requested", Callable(self,"_on_attack_requested"))

func _on_attack_requested(requested_attack : Attack, t_position : Vector2, t_direction : Vector2, damage_boost : float = 0.0):
	var character = get_parent()
	var scene = load(requested_attack.scene_location)
	if scene:
		var new_attack = scene.instantiate()
		new_attack.global_position = t_position
		new_attack.direction = t_direction
		new_attack.speed = requested_attack.speed
		new_attack.damage = requested_attack.damage* (1+damage_boost/100.0)
		new_attack.lifespan = requested_attack.lifespan
		new_attack.hit_force = requested_attack.hit_force
		new_attack.c_owner = character
		get_tree().current_scene.room_instance.call_deferred("add_child",new_attack)
