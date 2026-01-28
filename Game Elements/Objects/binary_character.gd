extends Label

@export var mono_font: Font
@export var current_color := Color(0.0, 0.373, 0.067, 1.0)
@export var new_color := Color(0.0, 0.373, 0.067, 1.0)
@export var outline_size := 2
@export var font_size := 64
@export var char_scale := 0.125
@export var variation = .1
var change_time = 1.0
var current_time = 0.0

var lum_offset := 0.0

func _ready():
	
	_update_visuals()

	# After visuals update, the size is correct. Center pivot.
	await get_tree().process_frame
	reset_size()
	pivot_offset = -get_combined_minimum_size() * scale * .5


func set_character_data(glyph: String):
	text = glyph
	lum_offset = randf_range(-variation, variation)
	_update_visuals()

func _process(delta: float) -> void:
	current_time = max(0.0, current_time - delta)
	if current_time > 0.0:
		_update_visuals()
		
	

func _change_color(color : Color, time : float = 1.0, delay : float = 0.0):
	if delay > 0.0:
		await get_tree().create_timer(delay).timeout
	change_time = time
	current_time = time
	current_color = new_color
	new_color = color


func _update_visuals():
	var v = clamp(current_color.v + lum_offset, 0.0, 1.0)
	var current_color_edit = Color.from_hsv(current_color.h, current_color.s, v, current_color.a)
	
	var v2 = clamp(new_color.v + lum_offset, 0.0, 1.0)
	var new_color_edit = Color.from_hsv(new_color.h, new_color.s, v2, new_color.a)
	
	var out_color = lerp(current_color_edit,new_color_edit,(change_time-current_time)/change_time)
	
	add_theme_color_override("font_color", out_color)
	add_theme_constant_override("outline_size", outline_size)
	add_theme_font_override("font", mono_font)
	add_theme_font_size_override("font_size", font_size)

	scale = Vector2(char_scale, char_scale)
