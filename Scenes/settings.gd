extends Control



func _on_back_pressed() -> void:
	get_tree().change_scene_to_file("res://Scenes/main_menu.tscn")
	pass # Replace with function body.


@onready var label := $Volume/VolVal
@export var bus_name: String = "Master"

func _ready() -> void:
	var bus_index = AudioServer.get_bus_index(bus_name)
	var value = AudioServer.get_bus_volume_db(bus_index)
	
	_on_volume_value_changed(value)
	pass # Replace with function body.


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
