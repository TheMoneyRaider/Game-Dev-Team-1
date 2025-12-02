extends CanvasLayer

var is_multiplayer : bool = true
@onready var health_bar_1 = $RootControl/HealthBar1
@onready var health_bar_2 = $RootControl/HealthBar2
@onready var TimeFabric = $RootControl/TimeFabric
@onready var MaceCooldownBar = $RootControl/MaceCooldownBar
@onready var CrossCooldownBar = $RootControl/CrossCooldownBar
@onready var IconSlotScene = preload("res://Game Elements/ui/remnant_icon.tscn")
var player1
var player2

func set_timefabric_amount(timefabric_collected : int):
	$RootControl/TimeFabric/HBoxContainer/Label.text = str(timefabric_collected)

func set_remnant_icons(player1_remnants: Array, player2_remnants: Array):
	for child in $RootControl/RemnantIcons/LeftRemnants.get_children():
		child.queue_free()
	for child in $RootControl/RemnantIcons/RightRemnants.get_children():
		child.queue_free()
	for remnant in player1_remnants:
		_add_slot($RootControl/RemnantIcons/LeftRemnants, remnant)
	#add in reverse so GridContainer displays them right->left
	for i in range(player2_remnants.size() - 1, -1, -1):
		_add_slot($RootControl/RemnantIcons/RightRemnants, player2_remnants[i])
	

func _add_slot(grid: Node, remnant: Resource):
	var slot := IconSlotScene.instantiate()
	var tex := slot.get_node("TextureRect")
	var label := slot.get_node("Label")
	tex.texture = remnant.icon
	tex.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	tex.custom_minimum_size = remnant.icon.get_size() * 2
	label.text = _num_to_roman(remnant.rank)
	grid.add_child(slot)



func _num_to_roman(input : int) -> String:
	match input:
		1:
			return "I"
		2:
			return "II"
		3:
			return "III"
		4:
			return "IV"
		5:
			return "V"
	return "error"

func set_players(player1_node : Node, player2_node : Node = null):
	player1 = player1_node
	player2 = player2_node
	if(player2_node == null):
		is_multiplayer = false
		CrossCooldownBar.cover_cooldown()
		health_bar_2.visible = false

func connect_signals(player_node : Node):
	player_node.player_took_damage.connect(_on_player_take_damage)
	player_node.swapped_color.connect(_on_player_swap)
	player_node.max_health_changed.connect(_on_max_health_changed)

func set_max_cooldowns():
	if is_multiplayer:
		MaceCooldownBar.set_max_cooldown(player1.attacks[1].cooldown)
		CrossCooldownBar.set_max_cooldown(player2.attacks[0].cooldown)
	else:
		MaceCooldownBar.set_max_cooldown(player1.attacks[1].cooldown)
		CrossCooldownBar.set_max_cooldown(player1.attacks[0].cooldown)

func set_cooldowns():
	if is_multiplayer:
		MaceCooldownBar.set_current_cooldown(player1.cooldowns[1])
		CrossCooldownBar.set_current_cooldown(player2.cooldowns[0])
	else:
		MaceCooldownBar.set_current_cooldown(player1.cooldowns[1])
		CrossCooldownBar.set_current_cooldown(player1.cooldowns[0])

func set_cross_position():
	if is_multiplayer:
		CrossCooldownBar.offset_left = 1838
		CrossCooldownBar.offset_right = 1956
	else:
		CrossCooldownBar.offset_left = 94
		CrossCooldownBar.offset_right = 212
	
func _on_player_swap(player_node : Node):
	if player1 == player_node:
		health_bar_1.set_color(!player1.is_purple)
		if(!is_multiplayer):
			MaceCooldownBar.cover_cooldown()
			CrossCooldownBar.cover_cooldown()
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
