extends Node2D

var first: bool = true

func _process(_delta):
	if Input.is_action_just_pressed("ui_accept"):
		if(first):
			$GPUParticles2D.emitting = true
			first=false
		else:
			print('hey')
			$GPUParticles2D.restart()
