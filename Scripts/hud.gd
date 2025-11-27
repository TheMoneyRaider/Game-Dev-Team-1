extends CanvasLayer

var is_multiplayer : bool = false
@onready var health_bar_1 = $HealthBar1
@onready var health_bar_2 = $HealthBar2
@onready var TimeFabric = $TimeFabric
var player1
var player2

func set_timefabric_amount(timefabric_collected : int):
	$TimeFabric/MarginContainer/HBoxContainer/Label.text = str(timefabric_collected)

func set_players(player1_node : Node, player2_node : Node = null):
	player1 = player1_node
	player2 = player2_node
	if(player2_node == null):
		health_bar_2.visible = false

func connect_signals(player_node : Node):
	player_node.player_took_damage.connect(_on_player_take_damage)
	player_node.swapped_color.connect(_on_player_swap)
	player_node.max_health_changed.connect(_on_max_health_changed)

func _on_player_swap(player_node : Node):
	if player1 == player_node:
		health_bar_1.set_color(!player1.is_purple)
	else:
		health_bar_2.set_color(!player2.is_purple)

func _on_player_take_damage(_damage_amount : int, current_health : int, player_node : Node):
	if current_health < 0:
		current_health = 0
	if(player_node == player1):
		health_bar_1.set_current_health(current_health)
	else:
		health_bar_2.set_current_health(current_health)

func _on_max_health_changed(max_health : int, player_node : Node):
	if(player_node == player1):
		health_bar_1.set_max_health(max_health)
	else:
		health_bar_2.set_max_health(max_health)
