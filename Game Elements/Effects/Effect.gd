extends Resource
class_name Effect

# Exposed fields for editor
@export var cooldown: float = 1.0
@export var type: String = "Error"
var value1: float = 0.0



var saved_value1: float = 0.0

func tick(delta : float, node_to_change : Node):
	if cooldown > 0:
		cooldown-=delta
	if cooldown <= 0:
		cooldown=0
		lost(node_to_change)
	
func gained(node_to_change : Node):
	if type == "winter":
		saved_value1= node_to_change.SPEED
		node_to_change.SPEED = ((100-value1)/100 * saved_value1)
		var particle =  load("res://Game Elements/Effects/winter_particles.tscn").instantiate()
		particle.position = node_to_change.position
		node_to_change.get_parent().add_child(particle)
	pass

func lost(node_to_change : Node):
	if type == "winter":
		node_to_change.SPEED = saved_value1
	pass
