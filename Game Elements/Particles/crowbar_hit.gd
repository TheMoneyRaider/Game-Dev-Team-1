extends Node2D

var lifetime = .25

func _ready() -> void:
	$AnimationPlayer.play("explode")

func _process(delta: float) -> void:
	lifetime-=delta
	if lifetime <=0.0:
		queue_free()
