extends Control
class_name RemnantSlot

@export var index: int = 0

signal slot_selected(index: int)

@onready var btn_select: Button = $btn_select
@onready var art: TextureRect = $btn_select/container/art
@onready var name_label: Label = $btn_select/container/name_label
@onready var desc_label: Label = $btn_select/container/description_label

func _ready():
	btn_select.pressed.connect(_on_button_pressed)

func set_remnant(remnant: Resource) -> void:
	if remnant == null:
		art.texture = null
		name_label.text = "—"
		desc_label.text = ""
		return
	name_label.text = remnant.remnant_name
	desc_label.text = remnant.description
	if remnant.art:
		art.texture = remnant.art
	else:
		art.texture = null

func _on_button_pressed():
	emit_signal("slot_selected", index)
