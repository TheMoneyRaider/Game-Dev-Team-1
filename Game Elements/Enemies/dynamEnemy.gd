class_name DynamEnemy
extends CharacterBody2D
@export var max_health: int = 10
@export var display_damage: bool =true
@export var hit_range: int = 64
@export var agro_distance: float = 150.0
@export var enemy_type : String = ""
@export var displays : Array[NodePath] = []
@export var min_timefabric = 10
@export var max_timefabric = 20
var current_health: int = 10
@export var move_speed: float = 70
@onready var current_dmg_time: float = 0.0
@onready var in_instant_trap: bool = false
var damage_direction = Vector2(0,-1)
var damage_taken = 0
var debug_mode = false
@export var weapon_cooldowns : Array[float] = []

var effects : Array[Effect] = []

var attacks = [preload("res://Game Elements/Attacks/bad_bolt.tscn")]
signal attack_requested(new_attack : PackedScene, t_position : Vector2, t_direction : Vector2, damage_boost : float)

signal enemy_took_damage(damage : int,current_health : int,c_node : Node, direection : Vector2)

func handle_attack(target_position: Vector2):
	var attack_direction = (target_position - global_position).normalized()
	var attack_position = attack_direction * 0		 + global_position
	request_attack(attacks[0], attack_position, attack_direction)

func request_attack(t_attack: PackedScene, attack_position: Vector2, attack_direction: Vector2):
	var instance = t_attack.instantiate()
	instance.global_position = attack_position
	instance.direction = attack_direction
	instance.c_owner = self
	get_parent().add_child(instance)
	emit_signal("attack_requested", t_attack, attack_position, attack_direction)
# import like, takes damage or something like that

func load_settings():
	if Globals.config_safe:
		debug_mode = Globals.config.get_value("debug", "enabled", false)
	

func _ready():
	current_health = max_health
	add_to_group("enemy") #TODO might not be needed anymore. I added a global group and just put the scenes in that group
	load_settings()
	Globals.config_changed.connect(load_settings)

#need this for flipping the sprite movement
func update_flip(dir: float):
	var sprite2d=get_node_or_null("Sprite2D")
	if sprite2d: 
		sprite2d.flip_h = dir < 0

func move(target_pos: Vector2, _delta: float): 
	
	var direction = (target_pos - global_position).normalized()
	
	var target_velocity = direction * move_speed
	velocity = velocity.lerp(target_velocity, 0.05)
	
	update_flip(direction.x)
	
	move_and_slide()
	
func apply_velocity(vel : Vector2):
	velocity=vel
	move_and_slide()
	
func _process(delta):
	for i in range(weapon_cooldowns.size()):
		weapon_cooldowns[i]-=delta
		
	#Trap stuff
	check_traps(delta)
	
	var idx = 0
	for effect in effects:
		effect.tick(delta,self)
		if effect.cooldown == 0:
			effects.remove_at(idx)
		idx +=1
	check_liquids(delta)
	
	if debug_mode:
		queue_redraw()
	

func take_damage(damage : int, dmg_owner : Node, direction = Vector2(0,-1), attack_body : Node = null, _i_frames : int = 0):
	if current_health >= 0 and display_damage:
		get_tree().get_root().get_node("LayerManager")._damage_indicator(damage, dmg_owner,direction, attack_body,self)
	if dmg_owner != null and dmg_owner.is_in_group("player"):
		var remnants : Array[Remnant] = []
		if dmg_owner.is_purple:
			remnants = get_tree().get_root().get_node("LayerManager").player_1_remnants
		else:
			remnants = get_tree().get_root().get_node("LayerManager").player_2_remnants
		var winter = load("res://Game Elements/Remnants/winters_embrace.tres")
		var effect : Effect
		for rem in remnants:
			if rem.remnant_name == winter.remnant_name:
				effect = load("res://Game Elements/Effects/winter_freeze.tres").duplicate(true)
				effect.cooldown = rem.variable_2_values[rem.rank-1]
				effect.value1 =  rem.variable_1_values[rem.rank-1]
				effect.gained(self)
				effects.append(effect)
	#const KNOCKBACK_FORCE: float = 150.0
	#velocity = direction * KNOCKBACK_FORCE
	if current_health-damage < 0 and enemy_type == "laser_e":
		var bt_player = get_node("BTPlayer")
		var board = bt_player.blackboard
		if board:
			board.set_var("kill_laser", true)
			board.set_var("kill_damage", damage)
			board.set_var("kill_direction", direction)
		return
	emit_signal("enemy_took_damage",damage,current_health,self,direction)
	current_health -= damage

func check_traps(delta):
	var tile_pos = Vector2i(int(floor(global_position.x / 16)),int(floor(global_position.y / 16)))
	if tile_pos in get_tree().get_root().get_node("LayerManager").trap_cells:
		var tile_data = get_tree().get_root().get_node("LayerManager").return_trap_layer(tile_pos).get_cell_tile_data(tile_pos)
		if tile_data:
			var dmg = tile_data.get_custom_data("trap_instant")
			#Instant trap
			if dmg and !in_instant_trap:
				take_damage(dmg, null)
				in_instant_trap = true
			if !dmg:
				in_instant_trap = false
			#Ongoing trap
			if tile_data.get_custom_data("trap_ongoing"):
				current_dmg_time += delta
				if current_dmg_time >= tile_data.get_custom_data("trap_ongoing_seconds"):
					current_dmg_time -= tile_data.get_custom_data("trap_ongoing_seconds")
					take_damage(tile_data.get_custom_data("trap_ongoing_dmg"), null)
			else:
				current_dmg_time = 0
		else:
			current_dmg_time = 0
			in_instant_trap = false
	else:
		current_dmg_time = 0
		in_instant_trap = false

func check_liquids(delta):
	if enemy_type == "laser_e":
		return
	var tile_pos = Vector2i(int(floor(global_position.x / 16)),int(floor(global_position.y / 16)))
	if tile_pos in get_tree().get_root().get_node("LayerManager").liquid_cells[0]:
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
				Globals.Liquid.Conveyer:
					position+=tile_data.get_custom_data("direction").normalized() *delta * 32
				Globals.Liquid.Glitch:
					_glitch_move()

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

func _draw():
	if !debug_mode:
		return
	# Get path from blackboard if behavior tree exists
	if not has_node("BTPlayer"):
		return
	
	var bt_player = get_node("BTPlayer")
	if not bt_player.blackboard.has_var("path"):
		return
		
	var path = bt_player.blackboard.get_var("path", [])
	if path.is_empty():
		return
	# Draw lines between waypoints
	for i in range(path.size() - 1):
		var start = to_local(path[i])
		var end = to_local(path[i + 1])
		draw_line(start, end, Color.YELLOW, 2.0)
	
	# Draw circles at each waypoint
	for waypoint in path:
		draw_circle(to_local(waypoint), 4, Color.RED)
		
	# Draw larger circle at current target
	var waypoint_index = bt_player.blackboard.get_var("waypoint_index", 0)
	if waypoint_index < path.size():
		draw_circle(to_local(path[waypoint_index]), 6, Color.GREEN)
