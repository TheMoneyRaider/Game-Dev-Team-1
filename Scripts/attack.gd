extends Sprite2D

@onready var player = $"../PlayerCat"
@onready var hitbox = $Area2D
@onready var cooldown = $Timer

func _process(_delta: float) -> void:
	if Input.is_action_just_pressed("attack") and not is_visible():
		print("pressed attack")
		var camera = get_viewport().get_camera_2d()
		var mouse_coords = camera.get_global_mouse_position()
		var direction = (mouse_coords - player.position).normalized()
		position = direction * 10
		rotation = direction.angle()
		visible = true
		cooldown.start()
		hitbox.set_collision_mask_value(1, true)


func _on_timer_timeout() -> void:
	visible = false
	print("attacked")
	hitbox.set_collision_mask_value(1, false)
	#Hitbox.disabled = true
	pass # Replace with function body.


func _on_area_2d_area_entered(area: Area2D) -> void:
	print(area)
	pass # Replace with function body.
