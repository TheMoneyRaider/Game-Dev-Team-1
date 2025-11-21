extends LimboState

@export var animation_player: AnimationPlayer
var animation : StringName = "idle_up"
var move_direction : Vector2 = Vector2.ZERO


func _enter() -> void:
	animation_update()
	animation_player.play(animation)

func _update(_delta) -> void:
	if agent.input_direction != Vector2.ZERO:
		get_root().dispatch("to_move")

func animation_update() -> void:
	if(move_direction != Vector2.ZERO):
		if(abs(move_direction.y) >= abs(move_direction.x)):
			if move_direction.y > 0:
				animation = "idle_down"
			else:
				animation = "idle_up"
		else:
			if move_direction.x > 0:
				animation = "idle_right"
			else:
				animation = "idle_left"
