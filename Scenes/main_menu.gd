extends Control

enum ButtonsHere {
	START,
	SETTINGS,
	QUIT
}

var active = ButtonsHere.START

func press():
	print(active)
	match active:
		ButtonsHere.START:
			_on_start_button_pressed()
		ButtonsHere.SETTINGS:
			_on_settings_button_pressed()
		ButtonsHere.QUIT:
			_on_quit_button_pressed()
			
			

func next_button():
	active = (active + 1) % ButtonsHere.size()
func prev_button():
	active = (active + ButtonsHere.size() - 1) % ButtonsHere.size()
	

const HANDLED_ACTIONS = ["ui_accept", "ui_up", "ui_down"]

func _input(event):
	if event.is_pressed():
		var occ = ""
		for action in HANDLED_ACTIONS:
			if event.is_action_pressed(action):
				occ = action
		match occ:
			"ui_accept":
				press()
			"ui_up":
				prev_button()
			"ui_down":
				next_button()
			


func _on_start_button_pressed() -> void:
	if FileAccess.file_exists("user://run/run_state.json"):
		DirAccess.remove_absolute("user://run/run_state.json")
	
	get_tree().change_scene_to_file("res://Scenes/layer_manager.tscn")


func _on_settings_button_pressed() -> void:
	get_tree().change_scene_to_file("res://Scenes/settings.tscn")
	pass # Replace with function body.


func _on_quit_button_pressed() -> void:
	get_tree().quit()


func _on_resume_button_ready() -> void:
	if !FileAccess.file_exists("user://run/run_state.json"):
		var res_but = $VBoxContainer/ResumeButton
		res_but.disabled = true
		
		#grey it out
	pass # Replace with function body.


func _on_resume_button_pressed() -> void:
	get_tree().change_scene_to_file("res://Scenes/layer_manager.tscn")
	pass # Replace with function body.
