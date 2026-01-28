extends Node2D

@export var speed: float = 0
@export var wave_amplitude: float = 0
@export var wave_frequency: float = 0
@export var base_spacing: float = 15.0
@export var min_length: int = 5
@export var max_length: int = 20
@export var digit_string: String = ""

# Optional: assign your own monospace font here (if available)
@export var mono_font: Font

var labels: Array = []
var time_passed: float = 0.0

func _ready():
	randomize()
	time_passed = randf_range(0.0,100)
	# Random length binary string
	var length = randi_range(min_length, max_length)
	digit_string = ""
	for i in range(length):
		digit_string += str(randi() % 2)
	speed = randf_range(40,100)
	wave_amplitude = randf_range(1,6)
	wave_frequency = randf_range(3,5)
	base_spacing = randf_range(14,17)
	create_digit_chain(digit_string)

func get_char_spacing(in_char: String) -> float:
	# Assign spacing per character (customize as needed)
	match in_char:
		"1": return base_spacing * .5
		"0": return base_spacing * 1
		"2","3","4","5","6","7","8","9": return base_spacing * 0.9
		_: return base_spacing


func create_digit_chain(text: String):
	var variation = .2
	var hue_change1 = randf_range(-variation,variation)
	var hue_change2 = randf_range(-variation,variation)
	var hue_change3 = randf_range(-variation,variation)
	var color = Color(0.0, 1.0, 0.0)
	var color2 = Color(0.0, 0.4, 0.0)
	color = Color(color.r+hue_change1,color.g+hue_change2,color.b+hue_change3,color.a)
	color2 = Color(color.r+hue_change1,color.g+hue_change2,color.b+hue_change3,color.a)

	# Create one Label per character
	var x_offset := 0.0
	for char_in in text:
		var lbl := Label.new()
		lbl.text = str(char_in)
		lbl.position = Vector2(x_offset, 0)

		# ---- APPLY GREEN CODING STYLE ----
		lbl.add_theme_color_override("font_color", color)
		lbl.add_theme_color_override("font_outline_color", color2)  # subtle glow
		lbl.add_theme_constant_override("outline_size", 2)

		if mono_font != null:
			lbl.add_theme_font_override("font", mono_font)
		
		lbl.add_theme_font_size_override("font_size", 64)
		lbl.scale = Vector2(0.125, 0.125)
		x_offset += get_char_spacing(char_in) / 2.0
		add_child(lbl)
		labels.append(lbl)


func _process(delta: float):
	time_passed += delta

	# Move forward on +X
	position.x += speed * delta
	for i in range(labels.size()):
		var lbl = labels[i]


		# Apply sine wave motion
		lbl.position.y = sin(time_passed * wave_frequency + float(i)) * wave_amplitude
