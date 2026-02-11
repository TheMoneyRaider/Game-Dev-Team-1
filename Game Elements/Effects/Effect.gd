extends Resource
class_name Effect

# Exposed fields for editor
@export var cooldown: float = 1.0
@export var type: String = "Error"
var value1: float = 0.0




func tick(delta : float, node_to_change : Node):
	if cooldown > 0:
		cooldown-=delta
	if cooldown <= 0:
		cooldown=0
		lost(node_to_change)
	
func gained(node_to_change : Node):
	match type:
		"winter":
			node_to_change.move_speed = ((100-value1)/100 * node_to_change.move_speed)
			var particle =  load("res://Game Elements/Effects/winter_particles.tscn").instantiate()
			particle.position = node_to_change.position
			node_to_change.get_parent().add_child(particle)
		"slow":
			node_to_change.move_speed = ((1-value1) * node_to_change.move_speed)
			var particle =  load("res://Game Elements/Effects/water_particles.tscn").instantiate()
			particle.position = node_to_change.position
			node_to_change.get_parent().add_child(particle)
		"tether":
			node_to_change.move_speed = ((1-value1) * node_to_change.move_speed)
		"charged":
			node_to_change.move_speed = ((1-value1) * node_to_change.move_speed)
			var particle =  load("res://Game Elements/Effects/charged_particles.tscn").instantiate()
			particle.position = node_to_change.position
			node_to_change.get_parent().add_child(particle)
		"speed":
			node_to_change.move_speed = ((1+value1) * node_to_change.move_speed)
			

func lost(node_to_change : Node):
	match type:
		"winter":
			node_to_change.move_speed = node_to_change.move_speed * 100 / (100-value1)
		"slow":
			node_to_change.move_speed = node_to_change.move_speed * 1 / (1-value1)
		"tether":
			node_to_change.move_speed = node_to_change.move_speed * 1 / (1-value1)
		"charged":
			node_to_change.move_speed = node_to_change.move_speed * 1 / (1-value1)
		"speed":
			node_to_change.move_speed = node_to_change.move_speed * 1 / (1+value1)
