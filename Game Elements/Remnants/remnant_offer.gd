extends Control
class_name RemnantOffer

signal remnant_chosen(remnant: Resource)

@onready var crosshair_sprite = $Crosshair/Sprite2D
@onready var purple_crosshair = preload("res://art/purple_crosshair.png")
@onready var orange_crosshair = preload("res://art/orange_crosshair.png")
@onready var slot_nodes: Array = [
	$MarginContainer/slots_hbox/slot0,
	$MarginContainer/slots_hbox/slot1,
	$MarginContainer/slots_hbox/slot2,
	$MarginContainer/slots_hbox/slot3]
var offered_remnants: Array[Resource] = []
var selected_index1: int = -1 #Purple
var selected_index2: int = -1 #Orange
var player1_remnants = []
var player2_remnants = []
var hover_index : int = 0 #Orange
@export var is_multiplayer = false

var nav_cooldown := 0.15
var nav_timer := 0.0

func _ready():
	for i in range(slot_nodes.size()):
		slot_nodes[i].index = i
		slot_nodes[i].slot_selected.connect(_on_slot_selected)
	get_tree().paused = true

func _process(delta):
	if nav_timer > 0:
		nav_timer -= delta
	for i in range(offered_remnants.size()):
		slot_nodes[i].outline_remnant(slot_nodes[i].btn_select.get_node("TextureRect"), Color.GREEN, 0.0)
	if hover_index!=-1:
		slot_nodes[hover_index].outline_remnant(slot_nodes[hover_index].btn_select.get_node("TextureRect"), Color.ORANGE, .5)
	if selected_index1 != -1:
		slot_nodes[selected_index1].outline_remnant(slot_nodes[selected_index1].btn_select.get_node("TextureRect"), Color.PURPLE, 1)
	if selected_index2 != -1:
		slot_nodes[selected_index2].outline_remnant(slot_nodes[selected_index2].btn_select.get_node("TextureRect"), Color.ORANGE, 1)
	if selected_index1 != selected_index2 and selected_index1 != -1 and selected_index2 != -1:
		#If we now have two different selections -> close the menu
		_close_after_two_chosen()

func popup_offer(is_multiplayer_in : bool, player1_remnants_in : Array, player2_remnants_in : Array, rank_weights : Array = [50,35,10,5,0]):
	player1_remnants = player1_remnants_in
	player2_remnants = player2_remnants_in
	crosshair_sprite.texture = purple_crosshair
	is_multiplayer = is_multiplayer_in
	if !is_multiplayer:
		hover_index = -1
	#query the pool for 4 random remnants(2 from each player)
	offered_remnants = RemnantManager.get_random_remnants(4,player1_remnants, player2_remnants)
	selected_index1 = -1
	selected_index2 = -1
	#populate UI
	for i in range(slot_nodes.size()):
		if i < offered_remnants.size():
			slot_nodes[i].set_remnant(offered_remnants[i],rank_weights)
		else:
			slot_nodes[i].queue_free()
	visible = true
	modulate.a = 0.0
	#Fade in
	var _tween = create_tween().tween_property(self, "modulate:a", 1.0, 0.5)


func _check_if_remnant_viable(remnant : Resource, remnant_array : Array):
	var names = []
	for r in remnant_array:
		names.append(r.remnant_name)
	if remnant.remnant_name not in names:
		return true
	return false

func _unhandled_input(event):
	if not visible:
		return
	if is_multiplayer:
		_handle_multiplayer_input(event)

func _handle_multiplayer_input(event):
	if nav_timer > 0:
		return

	if event.is_action_pressed("menu_left_0"):
		hover_index = max(0, hover_index - 1)
		nav_timer = nav_cooldown

	if event.is_action_pressed("menu_right_0"):
		hover_index = min(offered_remnants.size() - 1, hover_index + 1)
		nav_timer = nav_cooldown
	if Input.is_action_just_pressed("activate_0"):
		if _check_if_remnant_viable(offered_remnants[hover_index], player2_remnants) and hover_index != selected_index2:
			selected_index2 = hover_index



func _on_slot_selected(idx: int) -> void:
	if is_multiplayer:
		if _check_if_remnant_viable(offered_remnants[idx], player1_remnants) and idx != selected_index2:
			#Purple select
			selected_index1 = idx
	else:
		#Purple select
		if selected_index1 == -1:
			if _check_if_remnant_viable(offered_remnants[idx], player1_remnants):
				selected_index1 = idx
				crosshair_sprite.texture = orange_crosshair
			return
		#Orange Select
		if selected_index2 == -1 and idx != selected_index1 and _check_if_remnant_viable(offered_remnants[idx], player2_remnants):
			selected_index2 = idx
			#If we now have two different selections -> close the menu
			_close_after_two_chosen()

func _close_after_two_chosen():
	#Fade out animation
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 0.0, .5)
	await tween.finished
	#Emit the two chosen remnants
	emit_signal("remnant_chosen", offered_remnants[selected_index1], offered_remnants[selected_index2])
	visible = false
	get_tree().paused = false
