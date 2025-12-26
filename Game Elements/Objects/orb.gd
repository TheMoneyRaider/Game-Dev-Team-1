extends Area2D

@export var interact_key := "activate"
@onready var prompt1 := $Prompt1
var tracked_bodies: Array = []

func _ready():
	prompt1.visible = false
	self.connect("body_entered", Callable(self, "_on_body_entered"))
	self.connect("body_exited", Callable(self, "_on_body_exited"))


func _on_body_entered(body):
	if body.is_in_group("player"):
		tracked_bodies.append(body)
		prompt1.visible = true
		if len(tracked_bodies) == 1:
			_set_display(tracked_bodies[0])
func _on_body_exited(body):
	if body in tracked_bodies:
		tracked_bodies.erase(body)
	if len(tracked_bodies) == 0:
		prompt1.visible = false
	else:
		_set_display(tracked_bodies[0])
		
		
func _set_display(body : Node):
	if body.input_device == "key":
			prompt1.get_child(0).bbcode_text = "[font=res://addons/input_prompt_icon_font/icon.ttf]keyboard_e_outline[/font]"
	else:
		prompt1.get_child(0).bbcode_text = "[font=res://addons/input_prompt_icon_font/icon.ttf]playstation_button_cross_outline[/font]"
