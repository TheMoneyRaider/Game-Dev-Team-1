extends BTAction

func _tick(_delta: float) -> Status: 
	agent = get_agent()
	agent.die()
	return SUCCESS
