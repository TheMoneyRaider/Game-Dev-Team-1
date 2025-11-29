extends Control

@onready var progress_bar = $"ProgressBar"
@onready var label = $"Label"
var current_health = 10
var max_health = 10
@export var is_purple : bool

func _ready() -> void:
	update_text()
	set_color()

func set_max_health(health_value : int):
	max_health = health_value
	progress_bar.max_value = max_health
	update_text()

func set_current_health(health_value : int):
	current_health = health_value
	progress_bar.value = current_health
	update_text()

func update_text():
	label.text = str(current_health) + "/" + str(max_health) + " HP"

#If you give it true it makes it purple, if you give false it makes it orange
func set_color(default_color : bool = is_purple):
	is_purple = default_color
	var stylebox_background = get_theme_stylebox("background","ProgressBar").duplicate()
	var stylebox_fill = get_theme_stylebox("fill","ProgressBar").duplicate()
	var font_color = Color(0.627, 0.125, 0.941, 1.0)
	if is_purple:
		stylebox_background.bg_color = Color(0.38, 0.031, 0.588, 1.0)
		stylebox_fill.bg_color =Color(0.686, 0.298, 0.98, 1.0)
	else:
		stylebox_background.bg_color = Color(0.58, 0.367, 0.0, 1.0)
		stylebox_fill.bg_color = Color(1.0, 0.722, 0.367, 1.0)
		font_color = Color(1.0, 0.647, 0.0, 1.0)
	self.theme.set_stylebox("background","ProgressBar",stylebox_background)
	self.theme.set_stylebox("fill","ProgressBar",stylebox_fill)
	self.theme.set_color("font_color","Label",font_color)
