extends Area2D


func take_damage(damage : int, dmg_owner : Node, direction = Vector2(0,-1), attack_body : Node = null):
	get_parent().take_damage(damage, dmg_owner, direction, attack_body)
