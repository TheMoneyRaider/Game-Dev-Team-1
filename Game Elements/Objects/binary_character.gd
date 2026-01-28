extends Label

@export var mono_font: Font
@export var base_color := Color(1.0, 0.0, 0.0)
@export var outline_size := 2
@export var font_size := 64
@export var char_scale := 0.125

var lum_offset := 0.0

func _ready():
	_update_visuals()

	# After visuals update, the size is correct. Center pivot.
	await get_tree().process_frame
	reset_size()
	pivot_offset = -get_combined_minimum_size() * scale * .5


func set_character_data(glyph: String, lum: float):
	text = glyph
	lum_offset = lum
	_update_visuals()


func _update_visuals():
	var h = base_color.h
	var s = base_color.s
	var v = clamp(base_color.v + lum_offset, 0.0, 1.0)
	var final_color = Color.from_hsv(h, s, v, base_color.a)

	add_theme_color_override("font_color", final_color)
	add_theme_constant_override("outline_size", outline_size)
	add_theme_font_override("font", mono_font)
	add_theme_font_size_override("font_size", font_size)

	scale = Vector2(char_scale, char_scale)
