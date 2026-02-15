extends CanvasLayer


var frame_amount = 0
var mouse_mode = null

@onready var slot_nodes: Array = [
	$Control/MarginContainer/slots_hbox/slot0,
	$Control/MarginContainer/slots_hbox/slot1,
	$Control/MarginContainer/slots_hbox/slot2]

func _ready():
	for i in range(slot_nodes.size()):
		slot_nodes[i].index = i
		slot_nodes[i].slot_selected.connect(_on_slot_selected)
		slot_nodes[i].hide_visuals(true)
	hide()
	slot_nodes[1].set_enabled(false)

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






func _on_slot_selected(_idx: int) -> void:
	pass
	#if Globals.is_multiplayer:
		#if Globals.player1_input == "key" and _check_if_remnant_viable(offered_remnants[idx], player1_remnants) and idx != selected_index2:
			#selected_index1 = idx
		#elif Globals.player2_input == "key" and _check_if_remnant_viable(offered_remnants[idx], player2_remnants) and idx != selected_index1:
			#selected_index2 = idx
	#else:
		#if is_purple:
			#if  _check_if_remnant_viable(offered_remnants[idx], player1_remnants):
				#if idx == selected_index2:
					#selected_index2=-1
				#selected_index1 = idx
		#else:
			#if _check_if_remnant_viable(offered_remnants[idx], player2_remnants):
				#if idx == selected_index1:
					#selected_index1=-1
				#selected_index2 = idx
		#if selected_index1 != selected_index2 and selected_index1 != -1 and selected_index2 != -1: #If we now have two different selections -> close the menu
			#_close_after_two_chosen()


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
	get_tree().call_deferred("change_scene_to_file", "res://Game Elements/ui/main_menu/main_menu.tscn")
