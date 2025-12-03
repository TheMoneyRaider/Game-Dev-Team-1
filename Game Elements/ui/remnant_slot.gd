extends Control
class_name RemnantSlot

@export var index: int = 0

signal slot_selected(index: int)

@onready var btn_select: Button = $btn_select
@onready var art: TextureRect = $btn_select/SubViewport/art
@onready var name_label: Label = $btn_select/SubViewport/container/name_label
@onready var desc_label: RichTextLabel = $btn_select/SubViewport/container/description_label
@onready var rank_label: Label = $btn_select/SubViewport/container/rank_label

func _ready():
	randomize()
	btn_select.pressed.connect(_on_button_pressed)

func set_remnant(remnant: Resource, is_upgrade : bool) -> void:
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
	rank_label.text = "Rank " + _num_to_roman(remnant.rank) if !is_upgrade else "Rank " + _num_to_roman(remnant.rank) +"->" + _num_to_roman(remnant.rank+1)
	
	_update_description(remnant, desc_label, remnant.rank, is_upgrade)

func outline_remnant(child: Node, color: Color = Color.ORANGE, alpha : float = 0.0):
	var shader = Shader.new()
	shader.code = load("res://Game Elements/Shaders/outline.gdshader").code
	var mat = ShaderMaterial.new()
	mat.shader = shader
	mat.set_shader_parameter("outline_color", color)
	mat.set_shader_parameter("outline_thickness", 5.0)
	mat.set_shader_parameter("outline_opacity", alpha)
	child.material = mat


func _on_button_pressed():
	emit_signal("slot_selected", index)
	#outline_remnant($btn_select/TextureRect, Color.PURPLE)
	
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

func _update_description(remnant: Resource, desc_label_up: RichTextLabel, rank: int, is_upgrade : bool) -> void:
	var new_text := desc_label.text

	for i in remnant.variable_names.size():
		var rem_name : String = remnant.variable_names[i]
		var value := str(remnant["variable_%d_values" % (i + 1)][rank - 1])
		var new_value := str(remnant["variable_%d_values" % (i + 1)][rank])

		var colored_value := "[color=white]" + value
		var colored_new_value := "[color=white]" + new_value

		#Color a trailing % sign if present
		if new_text.find(rem_name + "%") != -1:
			if is_upgrade:
				colored_value += "%->"+colored_new_value+"%[/color]"
			else:
				colored_value += "%[/color]"
			new_text = new_text.replace(rem_name + "%", colored_value)
		else:
			if is_upgrade:
				colored_value += "->"+colored_new_value+"[/color]"
			else:
				colored_value += "[/color]"
			new_text = new_text.replace(rem_name, colored_value)

	desc_label_up.text = new_text
