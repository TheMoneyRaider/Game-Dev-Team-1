extends CanvasLayer
@onready var label: Label = $Control/Label
@onready var player = $".."


#func _process(delta: float)-> void:
	#label.text = str(player.current_health)+"/"+str(player.max_health)
