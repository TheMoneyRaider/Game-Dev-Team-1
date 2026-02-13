extends CanvasLayer

var is_multiplayer : bool = true
@onready var health_bar_1 = $RootControl/Left_Bottom_Corner/HealthBar
@onready var health_bar_2 = $RootControl/Right_Bottom_Corner/HealthBar
@onready var TimeFabric = $RootControl/TimeFabric
@onready var LeftCooldownBar = $RootControl/Left_Bottom_Corner/CooldownBar
@onready var RightCooldownBar = $RootControl/Right_Bottom_Corner/CooldownBar
@onready var IconSlotScene = preload("res://Game Elements/ui/remnant_icon.tscn")
const HIGHLIGHT_SHADER := preload("res://Game Elements/ui/highlight.gdshader")
@onready var combo1 = $RootControl/Left_Bottom_Corner/Combo
@onready var combo2 = $RootControl/Right_Bottom_Corner/Combo
var player1
var player2
var player1_max_time = 1.0
var player1_time = 0.0
var player1_combo = 1.0
var player1_combo_inc = 1.0
var player1_combo_max = 1.0
var player2_max_time = 1.0
var player2_time = 0.0
var player2_combo = 1.0
var player2_combo_inc = 1.0
var player2_combo_max = 1.0

func _ready():
	$RootControl/Notification.modulate.a = 0.0
	combo1.visible = false
	combo2.visible = false
	LeftCooldownBar.get_node("CooldownBar").material =LeftCooldownBar.get_node("CooldownBar").material.duplicate(true)
	RightCooldownBar.get_node("CooldownBar").material =RightCooldownBar.get_node("CooldownBar").material.duplicate(true)

func set_timefabric_amount(timefabric_collected : int):
	$RootControl/TimeFabric/HBoxContainer/Label.text = str(timefabric_collected)

func set_remnant_icons(player1_remnants: Array, player2_remnants: Array, ranked_up1: Array[String] = [], ranked_up2: Array[String] = []):
	for child in $RootControl/RemnantIcons/LeftRemnants.get_children():
		child.queue_free()
	for child in $RootControl/RemnantIcons/RightRemnants.get_children():
		child.queue_free()
	for remnant in player1_remnants:
		if ranked_up1.has(remnant.remnant_name):
			_add_slot($RootControl/RemnantIcons/LeftRemnants, remnant,true)
		else:
			_add_slot($RootControl/RemnantIcons/LeftRemnants, remnant,false)
	#add in reverse so GridContainer displays them right->left
	for i in range(player2_remnants.size() - 1, -1, -1):
		if ranked_up2.has(player2_remnants[i].remnant_name):
			_add_slot($RootControl/RemnantIcons/RightRemnants, player2_remnants[i],true)
		else:
			_add_slot($RootControl/RemnantIcons/RightRemnants, player2_remnants[i],false)
	
func _add_slot(grid: Node, remnant: Resource, has_ranked : bool = false):
	var slot := IconSlotScene.instantiate()
	var tex := slot.get_node("TextureRect")
	var label := slot.get_node("Label")
	tex.texture = remnant.icon
	tex.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	tex.custom_minimum_size = remnant.icon.get_size() * 2
	if has_ranked:
		label.text = _num_to_roman(remnant.rank-1)
	else:
		label.text = _num_to_roman(remnant.rank)
	grid.add_child(slot)
	if has_ranked:
		var mat := ShaderMaterial.new()
		mat.shader = HIGHLIGHT_SHADER
		mat.set_shader_parameter("start_time", Time.get_ticks_msec() / 1000.0)
		slot.get_node("TextureRect").material = mat
		await get_tree().create_timer(.5).timeout
		label.text = _num_to_roman(remnant.rank)
		
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
		RightCooldownBar.cover_cooldown()
	set_cooldown_icons()
	set_max_cooldowns()

func connect_signals(player_node : Node):
	player_node.player_took_damage.connect(_on_player_take_damage)
	player_node.swapped_color.connect(_on_player_swap)
	player_node.max_health_changed.connect(_on_max_health_changed)
	player_node.special_changed.connect(_on_special_changed)
	player_node.special_reset.connect(_on_special_reset)

func set_max_cooldowns():
	LeftCooldownBar.set_max_cooldown(player1.weapons[1].cooldown)
	RightCooldownBar.set_max_cooldown(player1.weapons[0].cooldown)

func set_cooldowns():
	if is_multiplayer:
		LeftCooldownBar.set_current_cooldown(player1.cooldowns[1])
		RightCooldownBar.set_current_cooldown(player2.cooldowns[0])
	else:
		LeftCooldownBar.set_current_cooldown(player1.cooldowns[1])
		RightCooldownBar.set_current_cooldown(player1.cooldowns[0])

func set_cooldown_icons():
	if is_multiplayer:
		LeftCooldownBar.set_cooldown_icon(player1.weapons[1].cooldown_icon)
		RightCooldownBar.set_cooldown_icon(player2.weapons[0].cooldown_icon)
	else:
		LeftCooldownBar.set_cooldown_icon(player1.weapons[1].cooldown_icon)
		RightCooldownBar.set_cooldown_icon(player1.weapons[0].cooldown_icon)	

func set_cross_position():
	if is_multiplayer:
		RightCooldownBar.offset_left = 1838
		RightCooldownBar.offset_right = 1956
	else:
		RightCooldownBar.offset_left = 94
		RightCooldownBar.offset_right = 212
	
func combo(remnant: Remnant, is_purple : bool):
	if is_purple:
		combo1.visible = true
		player1_max_time = remnant.variable_3_values[remnant.rank-1]
		player1_combo_inc = remnant.variable_1_values[remnant.rank-1]/100.0
		player1_combo_max = 1.0+remnant.variable_2_values[remnant.rank-1]/100.0
		combo1.get_node("TextureProgressBar").max_value = player1_max_time
		combo1.get_node("TextureProgressBar").value = player1_time
		combo1.get_node("TextureProgressBar/Label").text = str(player1_combo)+"x"
	else:
		combo2.visible = true
		player2_max_time = remnant.variable_3_values[remnant.rank-1]
		player2_combo_inc = remnant.variable_1_values[remnant.rank-1]/100.0
		player2_combo_max = 1.0+remnant.variable_2_values[remnant.rank-1]/100.0
		combo2.get_node("TextureProgressBar").max_value = player2_max_time
		combo2.get_node("TextureProgressBar").value = player2_time
		combo2.get_node("TextureProgressBar/Label").text = str(player2_combo)+"x"
	
func combo_change(player_value : bool, increase_value : bool):
	if player_value:
		#Player1
		if increase_value:
			player1_combo = min(player1_combo+player1_combo_inc, player1_combo_max)
			var tween = create_tween()
			var scale_val = (1.0+(player1_combo-1.0)/2.0)*.125
			tween.tween_property(combo1.get_node("TextureProgressBar/Label"), "scale", Vector2(scale_val, scale_val), 0.15)
			tween.tween_property(combo1.get_node("TextureProgressBar/Label"), "scale", Vector2(.125, .125), 0.2)
		else:
			player1_combo = max(player1_combo-player1_combo_inc, 1.0)
		player1_time = player1_max_time
		combo1.get_node("TextureProgressBar/Label").text = str(player1_combo)+"x"
	else:
		#Player2
		if increase_value:
			player2_combo = min(player2_combo+player2_combo_inc, player2_combo_max)
			var tween = create_tween()
			var scale_val = (1.0+(player2_combo-1.0)/2.0)*.125
			tween.tween_property(combo2.get_node("TextureProgressBar/Label"), "scale", Vector2(scale_val, scale_val), 0.15)
			tween.tween_property(combo2.get_node("TextureProgressBar/Label"), "scale", Vector2(.125, .125), 0.2)
		else:
			player2_combo = max(player2_combo-player2_combo_inc, 1.0)
		player2_time = player2_max_time
		combo2.get_node("TextureProgressBar/Label").text = str(player2_combo)+"x"

func _process(delta: float) -> void:
	if is_multiplayer or player1.is_purple:
		player1_time = max(player1_time-delta, 0.0)
	if is_multiplayer or !player1.is_purple:
		player2_time = max(player2_time-delta, 0.0)
	if player1_time != 0.0:
		combo1.get_node("TextureProgressBar").value = player1_time
	if player1_time == 0.0:
		if player1_combo > 1.0:
			combo_change(true, false)
	if player2_time != 0.0:
		combo2.get_node("TextureProgressBar").value = player2_time
	if player2_time == 0.0:
		if player2_combo > 1.0:
			combo_change(false, false)

func _on_player_swap(player_node : Node):
	if player1 == player_node:
		if(!is_multiplayer):
			LeftCooldownBar.cover_cooldown()
			RightCooldownBar.cover_cooldown()

func _on_player_take_damage(_damage_amount : int, current_health : int, player_node : Node, _direction = Vector2(0,-1)):
	if current_health < 0:
		current_health = 0
	if(player_node == player1):
		health_bar_1.set_current_health(current_health)
		if(!is_multiplayer):
			health_bar_2.set_current_health(current_health)
	else:
		health_bar_2.set_current_health(current_health)

func _on_max_health_changed(max_health : int, current_health : int,player_node : Node):
	if(player_node == player1):
		health_bar_1.set_max_health(max_health)
		health_bar_1.set_current_health(current_health)
	else:
		health_bar_2.set_max_health(max_health)
		health_bar_2.set_current_health(current_health)

func _on_special_reset(is_purple : bool):
	if is_purple:
		update_shader(LeftCooldownBar.get_node("CooldownBar").material,0.0, true)
		return
	update_shader(RightCooldownBar.get_node("CooldownBar").material,0.0, true)


func _on_special_changed(is_purple : bool, new_progress):
	if is_purple:
		update_shader(LeftCooldownBar.get_node("CooldownBar").material,new_progress)
		return
	update_shader(RightCooldownBar.get_node("CooldownBar").material,new_progress)

func update_shader(material: ShaderMaterial, new_prog : float, reset : bool = false):
	if reset:
		material.set_shader_parameter("prev_progress", 0.0)
		material.set_shader_parameter("progress",  0.0)
		material.set_shader_parameter("time_offset", Time.get_ticks_msec() / 1000.0+material.get_shader_parameter("interp_time"))
		return
		
	
	var t = clamp((Time.get_ticks_msec() / 1000.0 - material.get_shader_parameter("time_offset")) / material.get_shader_parameter("interp_time"), 0.0, 1.0);
	if t >= .98:
		material.set_shader_parameter("prev_progress", material.get_shader_parameter("progress"))
		material.set_shader_parameter("progress", new_prog)
		material.set_shader_parameter("time_offset", Time.get_ticks_msec() / 1000.0-1)
	else:
		var current_progress = lerp(material.get_shader_parameter("prev_progress"), material.get_shader_parameter("progress"), t);
		material.set_shader_parameter("prev_progress", current_progress)
		material.set_shader_parameter("progress", new_prog)
		material.set_shader_parameter("time_offset", Time.get_ticks_msec() / 1000.0-1)
		
func display_notification(text : String, fade_in : float = 1.0, hold : float= 1.0, fade_out : float= 1.0):
	var hud_notification := $RootControl/Notification
	var label := $RootControl/Notification/Noti/RichTextLabel

	label.text = text
	hud_notification.modulate.a = 0.0
	hud_notification.visible = true
	if hud_notification.has_meta("tween"):
		hud_notification.get_meta("tween").kill()
	var tween := create_tween()
	tween.set_trans(Tween.TRANS_SINE)
	tween.set_ease(Tween.EASE_OUT)

	tween.tween_property(hud_notification, "modulate:a", 1.0, fade_in)
	tween.tween_interval(hold)
	tween.tween_property(hud_notification, "modulate:a", 0.0, fade_out)
