extends CanvasLayer

var is_multiplayer : bool = false
@onready var health_bar_1 = $RootControl/HealthBar1
@onready var health_bar_2 = $RootControl/HealthBar2
@onready var TimeFabric = $RootControl/TimeFabric
var player1
var player2

func set_timefabric_amount(timefabric_collected : int):
	$RootControl/TimeFabric/HBoxContainer/Label.text = str(timefabric_collected)

func add_remnants(remnant1 : Resource,remnant2 : Resource):
	var icon1 = TextureRect.new()
	var icon2 = TextureRect.new()
	icon1.texture = remnant1.icon
	icon2.texture = remnant2.icon
	icon1.stretch_mode = TextureRect.STRETCH_SCALE
	icon1.custom_minimum_size = icon1.texture.get_size() * 2
	icon2.stretch_mode = TextureRect.STRETCH_SCALE
	icon2.custom_minimum_size = icon2.texture.get_size() * 2
	$RootControl/RemnantIcons/LeftRemnants.add_child(icon1)
	$RootControl/RemnantIcons/RightRemnants.add_child(icon2)

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

func _on_player_take_damage(_damage_amount : int, current_health : int, player_node : Node, _direction = Vector2(0,-1)):
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
