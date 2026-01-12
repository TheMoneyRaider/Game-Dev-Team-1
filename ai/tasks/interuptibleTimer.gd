extends BTAction

@export var duration: float = 1.0 
var time_passed: float = 0.0

func _tick(delta):
	time_passed += delta
	
	if time_passed >= duration:
		time_passed = 0.0
		return SUCCESS
	
	if blackboard.get_var("interrupted"):
		blackboard.set_var("interrupted", false)
		time_passed = 0.0
		return FAILURE
	
	return RUNNING
