extends Node2D

@export var used := false
@export var reward_type = Reward.Remnant
@export var reward_texture = null
@export var reward_material = null
enum Reward {TimeFabric, Remnant, RemnantUpgrade}

func _process(_delta):
	$ShaderSprite.material.set_shader_parameter("mask_texture", $MaskViewport.get_texture())


func disable_pathway():
	$ShaderSprite.visible = false
func enable_pathway():
	$ShaderSprite.visible = true
	$PathwayIcon.texture = reward_texture
	$PathwayIcon.material = reward_material

func set_reward(new_icon : Node, reward : Reward):
	reward_type = reward
	reward_texture = new_icon.texture
	reward_material = new_icon.material
