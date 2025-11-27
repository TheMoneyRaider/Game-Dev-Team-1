extends Control
class_name RemnantOffer

signal remnant_chosen(remnant: Resource)

@onready var crosshair_sprite = $Crosshair/Sprite2D
@onready var purple_crosshair = preload("res://art/purple_crosshair.png")
@onready var orange_crosshair = preload("res://art/orange_crosshair.png")
@onready var slot_nodes: Array = [
	$MarginContainer/slots_hbox/slot0,
	$MarginContainer/slots_hbox/slot1,
	$MarginContainer/slots_hbox/slot2]
var offered_remnants: Array[Resource] = []
var selected_index1: int = -1
var selected_index2: int = -1
@export var is_multiplayer = false

func _ready():
	#connect each slot's signal
	for i in range(slot_nodes.size()):
		var slot = slot_nodes[i]
		slot.index = i
		slot.slot_selected.connect(_on_slot_selected)
	#Pause the rest of the game
	get_tree().paused = true

func popup_offer(is_multiplayer_in : bool):
	crosshair_sprite.texture = purple_crosshair
	is_multiplayer = is_multiplayer_in
	#query the pool for 3 random remnants
	offered_remnants = RemnantManager.get_random_remnants(3)
	selected_index1 = -1
	selected_index2 = -1
	#populate UI
	for i in range(slot_nodes.size()):
		var slot = slot_nodes[i]
		var rem = null
		if i < offered_remnants.size():
			rem = offered_remnants[i]
		slot.set_remnant(rem)
	visible = true
	modulate.a = 0.0
	#Fade in
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 1.0, 0.5)

func _on_slot_selected(idx: int) -> void:
	#if is_multiplayer:
		## ORIGINAL BEHAVIOR FOR MULTIPLAYER
		#selected_index1 = idx
		#for i in range(slot_nodes.size()):
			#var slot = slot_nodes[i]
			#var btn = slot.get_node("btn_select")
			#if i == idx:
				#btn.grab_focus()
			#else:
				#btn.disabled = true
		#return
	#Purple select
	if selected_index1 == -1:
		selected_index1 = idx
		slot_nodes[idx].outline_remnant(slot_nodes[idx].btn_select.get_node("TextureRect"), Color.PURPLE)
		crosshair_sprite.texture = orange_crosshair
		return
	#Orange Select
	if selected_index2 == -1 and idx != selected_index1:
		selected_index2 = idx
		slot_nodes[idx].outline_remnant(slot_nodes[idx].btn_select.get_node("TextureRect"), Color.ORANGE)

		# If we now have two different selections → close the menu
		_close_after_two_chosen()
		return

func _close_after_two_chosen():

	#Fade out animation
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 0.0, .5)
	await tween.finished

	#Emit the two chosen remnants
	emit_signal("remnant_chosen", offered_remnants[selected_index1], offered_remnants[selected_index2])
	visible = false
	get_tree().paused = false
