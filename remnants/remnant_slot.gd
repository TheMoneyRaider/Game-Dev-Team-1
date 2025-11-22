extends Control
class_name RemnantSlot

@export var index: int = 0

signal slot_selected(index: int)

@onready var btn_select: Button = $btn_select
@onready var art: TextureRect = $btn_select/SubViewport/art
@onready var name_label: Label = $btn_select/SubViewport/container/name_label
@onready var desc_label: Label = $btn_select/SubViewport/container/description_label
@onready var rank_label: Label = $btn_select/SubViewport/container/rank_label

func _ready():
	randomize()
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
	var rank : int = (randi() % 5)+1
	rank_label.text = "Rank " + _num_to_roman(rank)
	
	_update_description(remnant, desc_label, rank)

func outline_remnant(child: Node, color: Color = Color.ORANGE):
	var shader = Shader.new()
	shader.code = load("res://Shaders/outline.gdshader").code
	var mat = ShaderMaterial.new()
	mat.shader = shader
	mat.set_shader_parameter("outline_color", color)
	mat.set_shader_parameter("outline_thickness", 5.0)
	child.material = mat


func _on_button_pressed():
	emit_signal("slot_selected", index)
	outline_remnant($btn_select/TextureRect, Color.PURPLE)
	
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

func _update_description(remnant : Resource, desc_label : Label, rank : int) -> void:
	if len(remnant.variable_names) >= 1:
		desc_label.text = desc_label.text.replace(remnant.variable_names[0],str(remnant.variable_1_values[rank-1]))
	if len(remnant.variable_names) >= 2:
		desc_label.text = desc_label.text.replace(remnant.variable_names[1],str(remnant.variable_2_values[rank-1]))
	if len(remnant.variable_names) >= 3:
		desc_label.text = desc_label.text.replace(remnant.variable_names[2],str(remnant.variable_3_values[rank-1]))
	if len(remnant.variable_names) >= 4:
		desc_label.text = desc_label.text.replace(remnant.variable_names[3],str(remnant.variable_4_values[rank-1]))
		
