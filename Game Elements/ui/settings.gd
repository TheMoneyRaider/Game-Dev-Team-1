extends Control

var mouse_sensitivity: float = 1.0
const SETTINGS_FILE = "user://settings.cfg"
var debug_mode: bool = false

func load_settings():
	var config = ConfigFile.new()
	var err = config.load(SETTINGS_FILE)
	
	if err == OK:
		mouse_sensitivity = config.get_value("controls", "mouse_sensitivity", 1.0)
		print(config.get_value("debug", "enabled", false))
		debug_mode = config.get_value("debug", "enabled", false)
		$MarginContainer/VBoxContainer/Volume/Volume.value = config.get_value("audio", "master", 100)
	else: 
		save_settings()
		
func save_settings():
	var config = ConfigFile.new()
	
	var volslider = $MarginContainer/VBoxContainer/Volume/Volume
	config.set_value("audio", "master", volslider.value)
	config.set_value("controls", "mouse_sensitivity", mouse_sensitivity)
	config.set_value("debug", "enabled", debug_mode)
	config.save(SETTINGS_FILE)

func _on_back_pressed() -> void:
	#first save config, then return to main menu
	save_settings()	
	get_tree().change_scene_to_file("res://Game Elements/ui/main_menu.tscn")
	pass # Replace with function body.

@onready var label := $MarginContainer/VBoxContainer/Volume/VolVal
@export var bus_name: String = "Master"

func _ready() -> void:
	var bus_index = AudioServer.get_bus_index(bus_name)
	var value = AudioServer.get_bus_volume_db(bus_index)
		
	_on_volume_value_changed(value)
	load_settings()

	$MarginContainer/VBoxContainer/Mouse/MouseSensitivity.value = mouse_sensitivity
	update_sensitivity_label()
		
	$MarginContainer/VBoxContainer/Debug/DebugMode.button_pressed = debug_mode
	update_debug_menu_label()
	 
func _on_volume_value_changed(value: float) -> void:
	var bus_index = AudioServer.get_bus_index(bus_name)
	AudioServer.set_bus_volume_db(bus_index, value)
	
	update_label(value)
	pass # Replace with function body.

func update_label(v: float) -> void:
	label.text = str(int(v)) + "%"
	
#func db_to_percent(db: float) -> int:
	## Clamp to avoid weird negative values
	#if db <= -40.0:
		#return 0
	## Convert dB → linear gain (0.0–1.0)
	#var linear := pow(10, db / 20.0)
	#return int(round(linear * 100))


func set_mouse_sensitivity(value: float): 
	mouse_sensitivity = clamp(value, .1, 2.0)
	update_sensitivity_label()
	save_settings()

func update_sensitivity_label():
	$MarginContainer/VBoxContainer/Mouse/SensLabel.text = "%.2f" % mouse_sensitivity

func _on_mouse_sensitivity_value_changed(value: float) -> void:
	set_mouse_sensitivity(value)
	pass # Replace with function body.

func set_debug_value(toggled_on: bool) -> void:
	debug_mode = toggled_on
	update_debug_menu_label()
	save_settings()

func update_debug_menu_label() -> void:
	if debug_mode == false: 
		$MarginContainer/VBoxContainer/Debug/DebugLabel.text = "Off"
	else:
		$MarginContainer/VBoxContainer/Debug/DebugLabel.text = "On"
		
func _on_debug_mode_toggled(toggled_on: bool) -> void:
	set_debug_value(toggled_on)
	pass # Replace with function body.
