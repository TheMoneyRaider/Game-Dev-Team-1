extends LimboState

@export var animation_player: AnimationPlayer
@export var animation : StringName
var move_direction : Vector2 = Vector2.ZERO


func _enter() -> void:
	animation_update()
	animation_player.play(animation)

func _update(delta) -> void:
	print(move_direction)
	animation_update()
	agent.apply_movement(delta)
	if agent.input_direction == Vector2.ZERO:
		get_root().dispatch("to_idle")

func animation_update() -> void:
	if(move_direction != Vector2.ZERO):
		if(abs(move_direction.y) > abs(move_direction.x)):
			if move_direction.y > 0:
				if(animation != "walk_down"):
					animation = "walk_down"
					animation_player.play(animation)
			else:
				if(animation != "walk_up"):
					animation = "walk_up"
					animation_player.play(animation)
		elif abs(move_direction.y) < abs(move_direction.x):
			if move_direction.x > 0:
				if(animation != "walk_right"):
					animation = "walk_right"
					animation_player.play(animation)
			else:
				if(animation != "walk_left"):
					animation = "walk_left"
					animation_player.play(animation)
		else:
			pass
			
