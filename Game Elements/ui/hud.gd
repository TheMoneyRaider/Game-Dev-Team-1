extends CanvasLayer

var is_multiplayer : bool = true
var debug_mode : bool = false
var menu_indicator : bool = false
var display_paths : bool = false
var toggle_invulnerability : bool = false 
var mouse_clamping : bool = false

@onready var health_bar_1 = $RootControl/HealthBar1
@onready var health_bar_2 = $RootControl/HealthBar2
@onready var TimeFabric = $RootControl/TimeFabric
@onready var MaceCooldownBar = $RootControl/MaceCooldownBar
@onready var CrossCooldownBar = $RootControl/CrossCooldownBar
@onready var IconSlotScene = preload("res://Game Elements/ui/remnant_icon.tscn")

var player1
var player2

func _ready():
	load_settings()
	display_debug_setting_header()
	

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
		
func load_settings():
	var config = ConfigFile.new()
	if config.load("user://settings.cfg") == OK:
		debug_mode = config.get_value("debug", "enabled", false)
		
func display_debug_setting_header():
	$RootControl/DebugMenu/GridContainer.set_anchors_preset(Control.PRESET_CENTER_RIGHT)
	if debug_mode == true: 
		$RootControl/DebugMenu/GridContainer.visible = true
		$RootControl/DebugMenu/GridContainer/MenuIndicator.text = "debug menu: H"
		
func _input(event):
	if debug_mode:
		if event.is_action_pressed("display_debug_settings"):
			menu_indicator = !menu_indicator
		
		if event.is_action_pressed("display_paths"):
			display_paths = !display_paths
			if menu_indicator:  
				update_display_paths()
			
		if event.is_action_pressed("toggle_invulnerability"):
			toggle_invulnerability = !toggle_invulnerability
			if menu_indicator:  
				update_invulnerability()
			
		if event.is_action_pressed("mouse_clamp"):
			mouse_clamping = !mouse_clamping
			if menu_indicator:  
				update_clamping()
				
		update_menu_indicator()
	return

# all of these have to be signals. settings menu items don't make sense because individual components 
# update settings at different periods, mostly on load, 

func update_menu_indicator() -> void:
	var paths_string = "  paths: | P | "
	var invul_string = "  invuln: | I | "
	var clamp_string = "  clamp: | C | "
	
	if menu_indicator:
		$RootControl/DebugMenu/GridContainer/Paths.text = paths_string
		update_display_paths()
		$RootControl/DebugMenu/GridContainer/Invulnerability.text = invul_string
		update_invulnerability()
		$RootControl/DebugMenu/GridContainer/Clamping.text = clamp_string
		update_clamping()
	else:
		$RootControl/DebugMenu/GridContainer/Paths.text = ""
		$RootControl/DebugMenu/GridContainer/Invulnerability.text = ""
		$RootControl/DebugMenu/GridContainer/Clamping.text = ""
	return

func update_display_paths() -> void:
	if display_paths:
		$RootControl/DebugMenu/GridContainer/Paths.text += "ON"
	else:
		$RootControl/DebugMenu/GridContainer/Paths.text += "OFF"

func update_invulnerability():
	if toggle_invulnerability:
		$RootControl/DebugMenu/GridContainer/Invulnerability.text += "ON"
	else:
		$RootControl/DebugMenu/GridContainer/Invulnerability.text += "OFF"

func update_clamping():
	if mouse_clamping:
		$RootControl/DebugMenu/GridContainer/Clamping.text += "ON"
	else:
		$RootControl/DebugMenu/GridContainer/Clamping.text += "OFF"
