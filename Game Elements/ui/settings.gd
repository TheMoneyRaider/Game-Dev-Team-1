extends Control

var mouse_sensitivity: float = 1.0
const SETTINGS_FILE = "user://settings.cfg"

func _on_back_pressed() -> void:
	#first save config, then return to main menu
	save_settings()	
	get_tree().change_scene_to_file("res://Game Elements/ui/main_menu.tscn")
	pass # Replace with function body.

@onready var label := $Volume/VolVal
@export var bus_name: String = "Master"

func load_settings():
	var config = ConfigFile.new()
	var err = config.load(SETTINGS_FILE)
	
	if err == OK:
		mouse_sensitivity = config.get_value("controls", "mouse_sensitivity", 1.0)
	else: 
		save_settings()

func _ready() -> void:
	var bus_index = AudioServer.get_bus_index(bus_name)
	var value = AudioServer.get_bus_volume_db(bus_index)
		
	_on_volume_value_changed(value)
	load_settings()

	if has_node("MouseSensitivity"):
		$MouseSensitivity.value = mouse_sensitivity
		update_sensitivity_label()

func save_settings():
	var config = ConfigFile.new()
	
	var volslider = $Volume
	config.set_value("audio", "master", volslider.value)
	
	config.set_value("controls", "mouse_sensitivity", mouse_sensitivity)
	config.save(SETTINGS_FILE)

func set_mouse_sensitivity(value: float): 
	mouse_sensitivity = clamp(value, .1, 2.0)
	update_sensitivity_label()
	save_settings()
	 
func update_sensitivity_label():
	if has_node("MouseSensitivity/SensLabel"):
		$MouseSensitivity/SensLabel.text = "%.2f" % mouse_sensitivity
	
func _on_volume_value_changed(value: float) -> void:
	var bus_index = AudioServer.get_bus_index(bus_name)
	AudioServer.set_bus_volume_db(bus_index, value)
	
	update_label(value)
	pass # Replace with function body.

func update_label(v: float) -> void:
	var percent := db_to_percent(v)
	label.text = str(percent) + "%"
	
func db_to_percent(db: float) -> int:
	# Clamp to avoid weird negative values
	if db <= -40.0:
		return 0
	# Convert dB → linear gain (0.0–1.0)
	var linear := pow(10, db / 20.0)
	return int(round(linear * 100))


func _on_mouse_sensitivity_value_changed(value: float) -> void:
	set_mouse_sensitivity(value)
	pass # Replace with function body.
