extends LimboState

@export var animation_player: AnimationPlayer
@export var animation : StringName

func _enter() -> void:
	animation_player.play(animation)
