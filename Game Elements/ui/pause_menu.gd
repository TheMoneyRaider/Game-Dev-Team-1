extends CanvasLayer


var frame_amount = 0
var mouse_mode = null

func _ready():
	hide()

func activate():
	mouse_mode = Input.get_mouse_mode()
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	show()
	get_tree().paused = true
	get_tree().get_root().get_node("LayerManager/DeathMenu").capturing = false
	if Globals.is_multiplayer or Globals.player1_input != "key":
		$Control/VBoxContainer/Return.grab_focus()

func _process(_delta):
	pass

func _on_settings_pressed():
	var setting = load("res://Game Elements/ui/settings.tscn").instantiate()
	add_child(setting)
	setting.get_child(0).is_pause_settings=true

func _on_return_pressed():
	Input.set_mouse_mode(mouse_mode)
	get_tree().get_root().get_node("LayerManager/DeathMenu").capturing = true
	get_tree().paused = false
	hide()

func _on_menu_pressed():
	get_tree().paused = false
	get_tree().call_deferred("change_scene_to_file", "res://Game Elements/ui/main_menu.tscn")
