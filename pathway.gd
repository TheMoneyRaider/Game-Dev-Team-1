extends Node2D

@export var used := false


func _process(_delta):
	$ShaderSprite.material.set_shader_parameter("mask_texture", $MaskViewport.get_texture())
