extends BTAction


var enemies = ["res://Game Elements/Characters/robot.tscn","res://Game Elements/Characters/laser_enemy.tscn"]

func _tick(_delta: float) -> Status: 
	agent.boss_signal("spawn_enemies",8 + int(8 * randf()),enemies[randi()%2])
	return SUCCESS
