extends BTAction

func _tick(_delta: float) -> Status: 
	print("agent_dies")
	agent = get_agent()
	agent.die()
	return SUCCESS
