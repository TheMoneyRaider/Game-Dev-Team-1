extends Control

@onready var mace_bar = $MaceBar

var max_cooldown = .5
var current_cooldown = 0

func _ready() -> void:
	mace_bar.step = max_cooldown/100
	
func set_max_cooldown(cooldown_value : float) -> void:
	max_cooldown = cooldown_value
	mace_bar.max_value = max_cooldown

func set_current_cooldown(cooldown_value : float) -> void:
	current_cooldown = cooldown_value
	mace_bar.value = current_cooldown
