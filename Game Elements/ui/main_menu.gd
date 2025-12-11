extends Control
#
#enum ButtonsHere {
	#START,
	#SETTINGS,
	#QUIT
#}
#
#var active = ButtonsHere.START
#
#func press():
	#print(active)
	#match active:
		#ButtonsHere.START:
			#_on_start_button_pressed()
		#ButtonsHere.SETTINGS:
			#_on_settings_button_pressed()
		#ButtonsHere.QUIT:
			#_on_quit_button_pressed()
			#
			#
#
#func next_button():
	#active = (active + 1) % ButtonsHere.size() as ButtonsHere
#func prev_button():
	#active = (active + ButtonsHere.size() - 1) % ButtonsHere.size() as ButtonsHere
	#
#
#const HANDLED_ACTIONS = ["ui_accept", "ui_up", "ui_down"]
#
#func _input(event):
	#if event.is_pressed():
		#var occ = ""
		#for action in HANDLED_ACTIONS:
			#if event.is_action_pressed(action):
				#occ = action
		#match occ:
			#"ui_accept":
				#press()
			#"ui_up":
				#prev_button()
			#"ui_down":
				#next_button()
			


func _ready() -> void:
	#check if there's a settings file, if there isn't create it and put in "volume", if there is, check if "volume" is there
	var config := ConfigFile.new()
	var err = config.load("user://settings.cfg")
	
	if err == OK:
		var volume = config.get_value("audio", "master")
		var bus_index = AudioServer.get_bus_index("Master")
		AudioServer.set_bus_volume_db(bus_index, volume)

func _on_start_button_pressed() -> void:
	Globals.is_multiplayer = false
	get_tree().change_scene_to_file("res://Game Elements/General Game/layer_manager.tscn")

func _on_start_m_button_pressed() -> void:
	Globals.is_multiplayer =true
	get_tree().change_scene_to_file("res://Game Elements/General Game/layer_manager.tscn")


func _on_settings_button_pressed() -> void:
	get_tree().change_scene_to_file("res://Game Elements/ui/settings.tscn")
	pass # Replace with function body.

func _on_quit_button_pressed() -> void:
	get_tree().quit()
