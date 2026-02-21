extends Node2D

var active = false
var y_floor = 0
var pos_velocity = Vector2.ZERO
var rot_velocity = 0.0
var gravity = Vector2(0, 900)
var phy_scale = 1/10.0


func _process(delta: float) -> void:
	if !active:
		return
	if position.y < y_floor:
		pos_velocity +=gravity*delta * phy_scale
		position +=pos_velocity*delta * phy_scale
		rotation +=rot_velocity*delta * phy_scale



func activate(move : Vector2, rotation_range : Vector2):
	rot_velocity = randf_range(rotation_range[0],rotation_range[1])
	pos_velocity = move * phy_scale
	y_floor = position.y + 48 + move.y / 2
	active = true
func deactivate():
	active = false
	
	
