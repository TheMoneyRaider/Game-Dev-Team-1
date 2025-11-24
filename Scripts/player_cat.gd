extends CharacterBody2D
const attack = preload("res://Scripts/attack.gd")

@export var move_speed: float = 100
@export var max_health: float = 10
@export var current_health: float = 10
@export var current_dmg_time: float = 0.0
@export var in_instant_trap: bool = false

@export var state_machine : LimboHSM

#States
@onready var idle_state = $LimboHSM/Idle
@onready var move_state = $LimboHSM/Move
@onready var attack_state = $LimboHSM/Attack
@onready var swap_state = $LimboHSM/Swap

@export var starting_direction : Vector2 =  Vector2(0,1)

@onready var tether_line = $Line2D
@onready var crosshair = $Crosshair
@onready var crosshair_sprite = $Crosshair/Sprite2D
@onready var sprite = $Sprite2D
@onready var purple_crosshair = preload("res://art/purple_crosshair.png")
@onready var orange_crosshair = preload("res://art/orange_crosshair.png")
@onready var purple_texture = preload("res://art/Sprout Lands - Sprites - Basic pack/Characters/Basic Purple Spritesheet-export.png")
@onready var orange_texture = preload("res://art/Sprout Lands - Sprites - Basic pack/Characters/Basic Orange Spritesheet-export.png")
var other_player

var tether_momentum = Vector2.ZERO
var is_tethered = false
var tether_gradient

var is_multiplayer = false
var input_device = "key"
var input_direction : Vector2 = Vector2.ZERO

@onready var chosen_remnants: Array[Resource] = []

func add_remnant(remnant: Resource) -> void:
	chosen_remnants.append(remnant)

func has_remnant(remnant: Resource) -> bool:
	return remnant in chosen_remnants


#The scripts for loading default values into the attack
var smash = preload("res://Scripts/Attacks/smash.gd")
var bolt = preload("res://Scripts/Attacks/bolt.gd")
var death_mark = preload("res://Scripts/Attacks/death_mark.gd")
#The list of attacks for playercharacter
var attacks = [attack.create_from_resource("res://Scenes/Attacks/smash.tscn",smash),attack.create_from_resource("res://Scenes/Attacks/bolt.tscn",bolt)]
var revive = attack.create_from_resource("res://Scenes/Attacks/death_mark.tscn",death_mark)
var cooldowns = [0,0]
var is_purple = true


signal attack_requested(new_attack : Attack, t_position : Vector2, t_direction : Vector2)
signal player_took_damage(damage : int, c_health : int, c_node : Node)

func _ready():
	_initialize_state_machine()
	update_animation_parameters(starting_direction)
	add_to_group("player")
	if is_multiplayer:
		tether_gradient = tether_line.gradient
		tether_line.gradient = null			

func _initialize_state_machine():
	#Define State transitions
	state_machine.add_transition(idle_state,move_state, "to_move")
	state_machine.add_transition(move_state,idle_state, "to_idle")
	
	state_machine.initial_state = idle_state
	state_machine.initialize(self)
	state_machine.set_active(true)

func apply_movement(_delta):
	velocity = input_direction * move_speed

func _physics_process(_delta):
	#Trap stuff
	var tile_pos = Vector2i(int(floor(global_position.x / 16)),int(floor(global_position.y / 16)))
	if tile_pos in get_parent().trap_cells:
		var tile_data = get_parent().return_trap_layer(tile_pos).get_cell_tile_data(tile_pos)
		if tile_data:
			var dmg = tile_data.get_custom_data("trap_instant")
			#Instant trap
			if dmg and !in_instant_trap:
				take_damage(dmg)
				in_instant_trap = true
			if !dmg:
				in_instant_trap = false
			#Ongoing trap
			if tile_data.get_custom_data("trap_ongoing"):
				current_dmg_time += _delta
				if current_dmg_time >= tile_data.get_custom_data("trap_ongoing_seconds"):
					current_dmg_time -= tile_data.get_custom_data("trap_ongoing_seconds")
					take_damage(tile_data.get_custom_data("trap_ongoing_dmg"))
			else:
				current_dmg_time = 0
		else:
			current_dmg_time = 0
			in_instant_trap = false
	else:
		current_dmg_time = 0
		in_instant_trap = false
	#Cat input detection
	input_direction = Vector2(
		Input.get_action_strength("right_" + input_device) - Input.get_action_strength("left_" + input_device),
		Input.get_action_strength("down_" + input_device) - Input.get_action_strength("up_" + input_device)
	)
	input_direction = input_direction.normalized()
	
	update_animation_parameters(input_direction)
	# Update velocity
	#velocity = input_direction * move_speed		
	
	if !is_multiplayer:
		if Input.is_action_just_pressed("swap_" + input_device):
			swap_color()
	else:
		tether()
	input_direction += (tether_momentum / move_speed)
	
	if Input.is_action_just_pressed("attack_" + input_device):
		handle_attack()
	
	adjust_cooldowns(_delta)
	#move and slide function
	if(self.process_mode != PROCESS_MODE_DISABLED):
		move_and_slide()
	

func update_animation_parameters(move_input : Vector2):
	if(move_input != Vector2.ZERO):
		idle_state.move_direction = move_input
		move_state.move_direction = move_input
		

func request_attack(t_attack : Attack):
	var attack_direction = (crosshair.position).normalized()
	var attack_position = attack_direction * 20 + global_position
	emit_signal("attack_requested",t_attack, attack_position, attack_direction)

func take_damage(damage_amount : int):
	current_health = current_health - damage_amount
	emit_signal("player_took_damage",damage_amount,current_health,self)
	if(current_health <= 0):
		if(die(true)):
			emit_signal("attack_requested",revive, position, Vector2.ZERO)
	
func swap_color():
	if(is_purple):
		is_purple = false
		sprite.texture = orange_texture
		crosshair_sprite.texture = orange_crosshair
		tether_line.default_color = Color("Orange")
	else:
		is_purple = true
		sprite.texture = purple_texture
		crosshair_sprite.texture = purple_crosshair
		tether_line.default_color = Color("Purple")

func tether():
	if Input.is_action_just_pressed("swap_" + input_device):
		tether_momentum += (other_player.position - position) / 1
		move_speed /= 2
		is_tethered = true
	if Input.is_action_pressed("swap_" + input_device):
		tether_line.visible = true
		if other_player.is_tethered:
			if is_purple:
				tether_line.gradient = tether_gradient
			else:
				tether_line.visible = false
		else:
			tether_line.gradient = null
		tether_line.points[0] = position + (other_player.position - position).normalized() * 8
		tether_line.points[1] = other_player.position + (position - other_player.position).normalized() * 8
		if ((other_player.position - position) / 25).length() > 8:
			tether_momentum += (other_player.position - position).normalized() * 8 + (((other_player.position - position) - ((other_player.position - position).normalized() * 8)) / 100)
		else:
			tether_momentum += (other_player.position - position) / 25
		tether_momentum *= .995
	else:
		if Input.is_action_just_released("swap_" + input_device):
			tether_line.visible = false
			move_speed *= 2
			is_tethered = false
		if(abs(tether_momentum.length_squared()) <  .1):
			tether_momentum = Vector2.ZERO
		else:
			tether_momentum *= .92

func die(death : bool , insta_die : bool = false) -> bool:
	if !is_multiplayer:
		#Change to signal something
		self.process_mode = PROCESS_MODE_DISABLED
		visible = false
		get_tree().change_scene_to_file("res://Scenes/main_menu.tscn")
		return false
	else:
		if insta_die:
			get_tree().change_scene_to_file("res://Scenes/main_menu.tscn")
			return false
		if death:
			max_health = max_health - 2
			current_health = round(max_health / 2)
			self.process_mode = PROCESS_MODE_DISABLED
			visible = false
			if(max_health <= 0):
				#Change to signal something
				get_tree().change_scene_to_file("res://Scenes/main_menu.tscn")
				return false
		else:
			self.process_mode = PROCESS_MODE_INHERIT
			visible = true
	return true

func adjust_cooldowns(time_elapsed : float):
	if is_purple:
		if cooldowns[0] > 0:
			cooldowns[0] -= time_elapsed
	else:
		if cooldowns[1] > 0:
			cooldowns[1] -= time_elapsed

func handle_attack():
	if(is_purple):
		if cooldowns[0] <= 0:
			await get_tree().create_timer(attacks[0].start_lag).timeout
			request_attack(attacks[0])
			cooldowns[0] = attacks[0].cooldown
	else:
		if cooldowns[1] <= 0:
			await get_tree().create_timer(attacks[1].start_lag).timeout
			request_attack(attacks[1])
			cooldowns[1] = attacks[1].cooldown
	
