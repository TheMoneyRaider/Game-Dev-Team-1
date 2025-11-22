extends Control
class_name RemnantOffer

signal remnant_chosen(remnant: Resource)

@onready var slot_nodes: Array = [
	$MarginContainer/container/slots_hbox/slot0,
	$MarginContainer/container/slots_hbox/slot1,
	$MarginContainer/container/slots_hbox/slot2]
@onready var confirm_btn: Button = $MarginContainer/container/btn_confirm

var offered_remnants: Array[Resource] = []
var selected_index: int = -1

func _ready():
	#connect each slot's signal
	for i in range(slot_nodes.size()):
		var slot = slot_nodes[i]
		slot.index = i
		slot.slot_selected.connect(_on_slot_selected)
	confirm_btn.pressed.connect(_on_confirm_pressed)

func popup_offer():
	#query the pool for 3 random remnants
	offered_remnants = RemnantManager.get_random_remnants(3)
	selected_index = -1
	#populate UI
	for i in range(slot_nodes.size()):
		var slot = slot_nodes[i]
		var rem = null
		if i < offered_remnants.size():
			rem = offered_remnants[i]
		slot.set_remnant(rem)
	visible = true

func _on_slot_selected(idx: int) -> void:
	# set selection to idx
	selected_index = idx
	#Disable other buttons and highlight chosen slot
	for i in range(slot_nodes.size()):
		var slot = slot_nodes[i]
		var btn = slot.get_node("btn_select")
		if i == idx:
			btn.grab_focus()
		else:
			btn.disabled = true

func _on_confirm_pressed():
	if selected_index < 0 or selected_index >= offered_remnants.size():
		return
	#Give the remnant to player data
	emit_signal("remnant_chosen", offered_remnants[selected_index])
	#close UI
	_close_offer()

func _close_offer():
	visible = false
