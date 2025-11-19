extends Control
class_name RemnantSlot

@export var index: int = 0

signal slot_selected(index: int)

@onready var btn_select: Button = $btn_select
@onready var art: TextureRect = $btn_select/SubViewportContainer/SubViewport/container/art
@onready var name_label: Label = $btn_select/SubViewportContainer/SubViewport/container/name_label
@onready var desc_label: Label = $btn_select/SubViewportContainer/SubViewport/container/description_label

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
