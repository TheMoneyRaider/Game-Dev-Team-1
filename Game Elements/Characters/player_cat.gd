extends CharacterBody2D
var mouse_sensitivity: float = 1.0

@export var move_speed: float = 100
@export var max_health: float = 10
@export var current_health: float = 10
@onready var current_dmg_time: float = 0.0
@onready var current_liquid_time: float = 0.0
@onready var in_instant_trap: bool = false
@onready var disabled_countdown : int = 0
@onready var i_frames : int = 0

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

@onready var weapon_sprite = $WeaponSprite
@onready var weapon_texture = $WeaponSprite/Sprite2D

@onready var sprite = $Sprite2D
@onready var purple_crosshair = preload("res://art/purple_crosshair.png")
@onready var orange_crosshair = preload("res://art/orange_crosshair.png")
@onready var purple_texture = preload("res://art/Sprout Lands - Sprites - Basic pack/Characters/Basic Purple Spritesheet-export.png")
@onready var orange_texture = preload("res://art/Sprout Lands - Sprites - Basic pack/Characters/Basic Orange Spritesheet-export.png")
var other_player

var tether_momentum = Vector2.ZERO
var is_tethered = false
var tether_gradient
var tether_width_curve

var is_multiplayer = false
var input_device = "-1"
var input_direction : Vector2 = Vector2.ZERO

var effects : Array[Effect] = []
var last_liquid : Globals.Liquid = Globals.Liquid.Buffer


#The scripts for loading default values into the attack
#The list of attacks for playercharacter
var weapons = [Weapon.create_weapon("res://Game Elements/Weapons/Crossbow.tres",self),Weapon.create_weapon("res://Game Elements/Weapons/Mace.tres",self)]
var attacks = [preload("res://Game Elements/Attacks/bolt.tscn"),preload("res://Game Elements/Attacks/smash.tscn")]
var revive = preload("res://Game Elements/Attacks/death_mark.tscn")
var cooldowns = [0,0]
var is_purple = true

signal attack_requested(new_attack : PackedScene, t_position : Vector2, t_direction : Vector2, damage_boost : float)
signal player_took_damage(damage : int, c_health : int, c_node : Node)
signal activate(player_node : Node)
signal special(player_node : Node)
signal swapped_color(player_node : Node)
signal max_health_changed(new_max_health : int, new_current_health : int, player_node : Node)

func _ready():
	_initialize_state_machine()
	update_animation_parameters(starting_direction)
	add_to_group("player")
	weapon_sprite.weapon_type = weapons[is_purple as int].type
	weapon_texture.texture = weapons[is_purple as int].weapon_sprite
	if is_multiplayer:
		tether_gradient = tether_line.gradient
		tether_width_curve = tether_line.width_curve
		tether_line.gradient = null			


func update_input_device(in_dev : String):
	input_device = in_dev
	crosshair.player_input_device = input_device

func _initialize_state_machine():
	#Define State transitions
	state_machine.add_transition(idle_state,move_state, "to_move")
	state_machine.add_transition(move_state,idle_state, "to_idle")
	
	state_machine.initial_state = idle_state
	state_machine.initialize(self)
	state_machine.set_active(true)

func apply_movement(_delta):
	velocity = input_direction * move_speed

func _physics_process(delta):
	if(i_frames > 0):
		i_frames -= 1
	#Trap stuff
	check_traps(delta)
	#Liquid stuff
	
	var idx = 0
	for effect in effects:
		effect.tick(delta,self)
		if effect.cooldown == 0:
			effects.remove_at(idx)
		idx +=1
	check_liquids(delta)
	
	#Cat input detection
	input_direction = Vector2(
		Input.get_action_strength("right_" + input_device) - Input.get_action_strength("left_" + input_device),
		Input.get_action_strength("down_" + input_device) - Input.get_action_strength("up_" + input_device)
	)
	input_direction = input_direction.normalized()
	
	update_animation_parameters(input_direction)	
	
	if !is_multiplayer:
		if Input.is_action_just_pressed("swap_" + input_device):
			swap_color()
	else:
		tether(delta)
	input_direction += (tether_momentum / move_speed)
	weapon_sprite.weapon_direction = (crosshair.position).normalized()
	
	
	if Input.is_action_just_pressed("attack_" + input_device):
		handle_attack()
	if Input.is_action_just_pressed("activate_" + input_device):
		emit_signal("activate",self)
		
	if Input.is_action_pressed("special_" + input_device):
		effects += weapons[is_purple as int].use_special(delta,false, (crosshair.position).normalized(), global_position)
		emit_signal("special",self)
	elif Input.is_action_just_released("special_" + input_device):
		effects += weapons[is_purple as int].use_special(delta, true, (crosshair.position).normalized(), global_position)
		
	adjust_cooldowns(delta)
	red_flash()
	#move and slide function
	if(self.process_mode != PROCESS_MODE_DISABLED and disabled_countdown <= 0):
		move_and_slide()
	if disabled_countdown >= 1:
		disabled_countdown-=1

func update_animation_parameters(move_input : Vector2):
	if(move_input != Vector2.ZERO):
		idle_state.move_direction = move_input
		move_state.move_direction = move_input
		

func request_attack(t_weapon : Weapon) -> float:
	weapon_sprite.flip_direction()
	var attack_direction = (crosshair.position).normalized()
	t_weapon.request_attacks(attack_direction,global_position)
	return t_weapon.cooldown

func take_damage(damage_amount : int, _dmg_owner : Node,_direction = Vector2(0,-1), attack_body : Node = null, attack_i_frames : int = 20):
	if(i_frames <= 0):
		i_frames = attack_i_frames
		current_health = current_health - damage_amount
		emit_signal("player_took_damage",damage_amount,current_health,self)
		if current_health >= 0:
			get_tree().get_root().get_node("LayerManager")._damage_indicator(damage_amount, _dmg_owner,_direction, attack_body,self)
		if(current_health <= 0):
			if(die(true)):
				var instance = revive.instantiate()
				instance.global_position = position
				instance.c_owner = self
				get_tree().get_root().get_node("LayerManager").room_instance.add_child(instance)
				emit_signal("attack_requested",revive, position, Vector2.ZERO, 0)
		_cleric_chance()
		_barb_damage()
	
func swap_color():
	emit_signal("swapped_color", self)
	if(is_purple):
		is_purple = false
		sprite.texture = orange_texture
		crosshair_sprite.texture = orange_crosshair
		weapon_texture.texture = weapons[0].weapon_sprite
		weapon_sprite.weapon_type = weapons[0].type
		tether_line.default_color = Color("Orange")
		weapons[1].special_time_elapsed = 0.0
	else:
		is_purple = true
		sprite.texture = purple_texture
		crosshair_sprite.texture = purple_crosshair
		weapon_texture.texture = weapons[1].weapon_sprite
		weapon_sprite.weapon_type = weapons[1].type
		tether_line.default_color = Color("Purple")
		weapons[0].special_time_elapsed = 0.0

func tether(delta : float):
	if Input.is_action_just_pressed("swap_" + input_device):
		tether_momentum += (other_player.position - position) / 1
		is_tethered = true
	if Input.is_action_pressed("swap_" + input_device):
		var effect = load("res://Game Elements/Effects/tether.tres").duplicate(true)
		effect.cooldown = delta
		effect.value1 = 0.5
		effect.gained(self)
		effects.append(effect)
		
		tether_line.visible = true
		if other_player.is_tethered:
			if is_purple:
				tether_line.gradient = tether_gradient
			else:
				tether_line.visible = false
		else:
			tether_line.gradient = null
		tether_line.points[0] = position + (other_player.position - position).normalized() * 8
		tether_line.points[2] = other_player.position + (position - other_player.position).normalized() * 8
		tether_line.points[1] = (tether_line.points[0] + tether_line.points[2]) / 2
		if ((other_player.position - position) / 25).length() > 8:
			tether_momentum += (other_player.position - position).normalized() * 8 + (((other_player.position - position) - ((other_player.position - position).normalized() * 8)) / 100)
		else:
			tether_momentum += (other_player.position - position) / 25
		tether_momentum *= .995
		tether_line.width_curve.set_point_value(1, min(max(50 / tether_momentum.length(),.4),1))
	else:
		if tether_line.visible == true:
			tether_line.visible = false
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
		get_tree().get_root().get_node("LayerManager").open_death_menu()
		return false
	else:
		if other_player.current_health <= 0:
			insta_die = true
		if insta_die:
			get_tree().get_root().get_node("LayerManager").open_death_menu()
			return false
		if death:
			max_health = max_health - 2
			emit_signal("max_health_changed",max_health,current_health, self)
			self.process_mode = PROCESS_MODE_DISABLED
			visible = false
			if(max_health <= 0):
				#Change to signal 
				get_tree().get_root().get_node("LayerManager").open_death_menu()
				return false
		else:
			current_health = round(max_health / 2)
			emit_signal("player_took_damage",-round(max_health / 2),current_health,self)
			self.process_mode = PROCESS_MODE_INHERIT
			visible = true
	return true

func adjust_cooldowns(time_elapsed : float):
	if cooldowns[is_purple as int] > 0:
		cooldowns[is_purple as int] -= time_elapsed

func handle_attack():
	if cooldowns[is_purple as int] <= 0:
		cooldowns[is_purple as int] = request_attack(weapons[is_purple as int])

func check_traps(delta):
	var tile_pos = Vector2i(int(floor(global_position.x / 16)),int(floor(global_position.y / 16)))
	if tile_pos in get_tree().get_root().get_node("LayerManager").trap_cells:
		var tile_data = get_tree().get_root().get_node("LayerManager").return_trap_layer(tile_pos).get_cell_tile_data(tile_pos)
		if tile_data:
			var dmg = tile_data.get_custom_data("trap_instant")
			#Instant trap
			if dmg and !in_instant_trap:
				if _crafter_chance():
					take_damage(dmg, null)
				in_instant_trap = true
			if !dmg:
				in_instant_trap = false
			#Ongoing trap
			if tile_data.get_custom_data("trap_ongoing"):
				current_dmg_time += delta
				if current_dmg_time >= tile_data.get_custom_data("trap_ongoing_seconds"):
					current_dmg_time -= tile_data.get_custom_data("trap_ongoing_seconds")
					if _crafter_chance():
						take_damage(tile_data.get_custom_data("trap_ongoing_dmg"),null)
			else:
				current_dmg_time = 0
		else:
			current_dmg_time = 0
			in_instant_trap = false
	else:
		current_dmg_time = 0
		in_instant_trap = false

func _check_hydromancer(liquid : Globals.Liquid):
	var remnants : Array[Remnant]
	if is_purple:
		remnants = get_tree().get_root().get_node("LayerManager").player_1_remnants
	else:
		remnants = get_tree().get_root().get_node("LayerManager").player_2_remnants
	var hydromancer = load("res://Game Elements/Remnants/hydromancer.tres")
	for rem in remnants:
		if rem.remnant_name == hydromancer.remnant_name:
			last_liquid = liquid

func check_liquids(delta):
	var tile_pos = Vector2i(int(floor(global_position.x / 16)),int(floor(global_position.y / 16)))
	if tile_pos in get_tree().get_root().get_node("LayerManager").liquid_cells:
		var tile_data = get_tree().get_root().get_node("LayerManager").return_liquid_layer(tile_pos).get_cell_tile_data(tile_pos)
		if tile_data:
			var type = tile_data.get_custom_data("liquid")
			match type:
				Globals.Liquid.Water:
					var effect = load("res://Game Elements/Effects/slow_down.tres").duplicate(true)
					effect.cooldown = 20*delta
					effect.value1 = 0.023
					effect.gained(self)
					effects.append(effect)
					_check_hydromancer(Globals.Liquid.Water)
				Globals.Liquid.Lava:
					var idx = 0
					for effect in effects:
						if effect.type == "slow":
							effect.tick(delta,self)
							if effect.cooldown == 0:
								effects.remove_at(idx)
							current_liquid_time -= .01
						idx +=1
					current_liquid_time += delta
					if current_liquid_time >= .25:
						current_liquid_time -= .25
						take_damage(2,null)
					_check_hydromancer(Globals.Liquid.Lava)
				Globals.Liquid.Conveyer:
					position+=tile_data.get_custom_data("direction").normalized() *delta * 32
				Globals.Liquid.Glitch:
					_glitch_move()
					_check_hydromancer(Globals.Liquid.Glitch)
					
					
func _glitch_move() -> void:
	var direct = -1 if randf() > .5 else 1
	var ground_cells = get_tree().get_root().get_node("LayerManager").room_instance.get_node("Ground").get_used_cells()
	var move_dir = velocity.normalized() *16
	var check_pos = Vector2i(((position + move_dir)/16).floor())
	var attempts = 0
	var max_attempts = 36 # prevent infinite loops
	var checked_cells = []
	while check_pos not in ground_cells and attempts < max_attempts:
		checked_cells.append(check_pos)
		move_dir = move_dir.rotated(direct * deg_to_rad(5))
		check_pos = Vector2i(((position + move_dir)/16).floor())
		attempts += 1
	if velocity.length() < .1:
		return
	position+=move_dir/2.0
	var saved_position = position
	var position_variance = 8
	position+= Vector2(randf_range(-position_variance,position_variance),randf_range(-position_variance,position_variance))
	Spawner.spawn_after_image(self,get_tree().get_root().get_node("LayerManager"),Color(0.584, 0.002, 0.834, 1.0),Color(0.584, 0.002, 0.834, 1.0),0,1.0,1)
	position = saved_position
	position+=move_dir/2.0
	saved_position = position
	position+= Vector2(randf_range(-position_variance,position_variance),randf_range(-position_variance,position_variance))
	Spawner.spawn_after_image(self,get_tree().get_root().get_node("LayerManager"),Color(0.714, 0.29, 0.0, 1.0),Color(0.714, 0.29, 0.0, 1.0),0,1.0,1)
	position = saved_position

func _crafter_chance() -> bool:
	randomize()
	var remnants : Array[Remnant]
	if is_purple:
		remnants = get_tree().get_root().get_node("LayerManager").player_1_remnants
	else:
		remnants = get_tree().get_root().get_node("LayerManager").player_2_remnants
	var crafter = load("res://Game Elements/Remnants/crafter.tres")
	for rem in remnants:
		if rem.remnant_name == crafter.remnant_name:
			if rem.variable_1_values[rem.rank-1] > randf()*100:
				var particle =  load("res://Game Elements/Effects/crafter_particles.tscn").instantiate()
				particle.position = self.position
				get_parent().add_child(particle)
				return false
			
	return true

func _cleric_chance():
	randomize()
	var remnants : Array[Remnant]
	if is_purple:
		remnants = get_tree().get_root().get_node("LayerManager").player_1_remnants
	else:
		remnants = get_tree().get_root().get_node("LayerManager").player_2_remnants
	var cleric = load("res://Game Elements/Remnants/cleric.tres")
	for rem in remnants:
		if rem.remnant_name == cleric.remnant_name:
			if rem.variable_1_values[rem.rank-1] > randf()*100:
				var particle =  load("res://Game Elements/Effects/heal_particles.tscn").instantiate()
				particle.position = self.position
				get_parent().add_child(particle)
				change_health(rem.variable_2_values[rem.rank-1])

func _barb_damage():
	var remnants : Array[Remnant]
	if is_purple:
		remnants = get_tree().get_root().get_node("LayerManager").player_1_remnants
	else:
		remnants = get_tree().get_root().get_node("LayerManager").player_2_remnants
	var barbarian = load("res://Game Elements/Remnants/barbarian.tres")
	for rem in remnants:
		if rem.remnant_name == barbarian.remnant_name:
			for weapon in weapons:
				weapon.damage = weapon.damage * (1 + rem.variable_1_values[rem.rank-1] / 100.0)
			_reset_barb_damage(rem.variable_1_values[rem.rank-1] / 100.0,rem.variable_2_values[rem.rank-1])

func _reset_barb_damage(percent : float, time : float):
	await get_tree().create_timer(time).timeout
	for weapon in weapons:
		weapon.damage = weapon.damage / (1 + percent)

func hunter_percent_boost() -> float:
	randomize()
	var remnants : Array[Remnant]
	if is_purple:
		remnants = get_tree().get_root().get_node("LayerManager").player_1_remnants
	else:
		remnants = get_tree().get_root().get_node("LayerManager").player_2_remnants
	var hunter = load("res://Game Elements/Remnants/hunter.tres")
	for rem in remnants:
		if rem.remnant_name == hunter.remnant_name:
			var min_dist = 100000
			for child in get_tree().get_root().get_node("LayerManager").room_instance.get_children():
				if child is DynamEnemy:
					min_dist = min(min_dist,self.position.distance_to(child.position))
			if rem.variable_2_values[rem.rank-1]*16 < min_dist:
				print("boosted")
				return float(rem.variable_1_values[rem.rank-1])
	return 0.0

func change_health(add_to_current : int, add_to_max : int = 0):
	current_health+=add_to_current
	max_health+=add_to_max
	current_health = clamp(current_health,0,max_health)
	emit_signal("max_health_changed",max_health,current_health,self)

func red_flash() -> void:
	if(i_frames > 0):
		sprite.self_modulate = Color(1.0, 0.378, 0.31, 1.0)
	else:
		sprite.self_modulate = Color(1.0, 1.0, 1.0)

func set_weapon(purple : bool, resource_loc : String):
	weapons[purple as int] = Weapon.create_weapon(resource_loc,self)
	
func update_weapon(resource_name : String):
	var resource_loc = "res://Game Elements/Weapons/" + resource_name + ".tres"
	weapons[is_purple as int] = Weapon.create_weapon(resource_loc,self)
	weapon_texture.texture = weapons[is_purple as int].weapon_sprite
	weapon_sprite.weapon_type = weapons[is_purple as int].type
