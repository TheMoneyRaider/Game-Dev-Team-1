extends BTAction


var enemies = ["res://Game Elements/Characters/laser_enemy.tscn","res://Game Elements/Characters/robot.tscn",]
var enemy_count_linear = [8,4]
var enemy_count_rand = [8,4]
func _tick(_delta: float) -> Status: 
	var enemy_id = clamp(randi()%3,0,1)
	agent.boss_signal("spawn_enemies",enemy_count_linear[enemy_id] + int(enemy_count_rand[enemy_id] * randf()),enemies[enemy_id])
	return SUCCESS
