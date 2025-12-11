extends Node


var is_multiplayer:bool = false
var player1_input
var player2_input


func _ready():
	var config = ConfigFile.new()
	var err = config.load("user://settings.cfg")
	if err == OK:
		player1_input = config.get_value("inputs","player1_input", "key")
		player2_input = config.get_value("inputs","player2_input", "0")
