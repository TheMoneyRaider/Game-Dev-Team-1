extends Node2D

var trap_cells := []
var blocked_cells := []
var liquid_cells : Array[Array]= [[],[],[],[],[],[],[],[],[],[],[],[],[],[],[],[]]

var camera : Node = null
var player1 : Node = null
var player2 : Node = null
var LayerManager : Node = null
var Hud : Node = null
var screen : Node = null
var active : bool = false
var is_multiplayer : bool = false
var phase = 0

@export var boss_splash_art : Texture2D
@export var healthbar_underlays : Array[Texture2D]
@export var healthbar_overlays : Array[Texture2D]
@export var boss_names : Array[String]
@export var boss_name_settings : Array[LabelSettings]
@export var boss : Node
@export var boss_name : String
@export var boss_font : Font
#This is what values the bossbar shader is looking for
@export var phase_overlay_index : Array[int]
@export var boss_type : String =""
var phase_changing : bool = false
var animation : String = ""


func _ready() -> void:
	LayerManager = get_tree().get_root().get_node("LayerManager")
	is_multiplayer = Globals.is_multiplayer
	boss.boss_phase_change.connect(_on_boss_phase_change)
	boss.enemy_took_damage.connect(LayerManager._on_enemy_take_damage)
	
func _on_boss_phase_change(boss_in : Node):
	match boss_in.phase:
		0:
			pass
		1:
			if boss_type=="scifi":
				scifi_phase1_to_2()
		2:
			if boss_type=="scifi":
				scifi_phase2_to_3()
			
	
func scifi_phase1_to_2():
	if phase_changing:
		return
	phase_changing = true
	phase = boss.phase
	
	boss.hitable = false
	$Forcefield/CollisionShape2D.set_deferred("disabled", true)
	var tween = create_tween()
	tween.tween_property($Forcefield,"modulate",Color(1.0,1.0,1.0,0.0),1.0)
	await tween.finished
	boss.get_node("AnimationTree").set("parameters/conditions/idle",true)
	print(boss.get_node("AnimationTree").get("parameters/conditions/idle"))
	await get_tree().create_timer(3.0).timeout
	boss.get_node("CollisionShape2D").set_deferred("disabled", false)
	animation_change("idle")
	$Forcefield.queue_free()
	boss.current_health = boss.boss_healthpools[phase]
	boss.max_health = boss.boss_healthpools[phase]
	phase_changing = false
	boss.hitable = true
	boss.get_node("BTPlayer").blackboard.set_var("phase", phase)

	
func scifi_phase2_to_3():
	if phase_changing:
		return
	boss.hitable = false
	Hud.update_bossbar(0.0)
	phase_changing = true
	phase=boss.phase
	#Wave Attack
	var attack_inst = load("res://Game Elements/Bosses/scifi/wave_attack.tscn").instantiate()
	attack_inst.damage = 10
	attack_inst.global_position = boss.global_position
	attack_inst.c_owner = boss
	attack_inst.direction = Vector2.UP
	call_deferred("add_child",attack_inst)
	var s_material = LayerManager.get_node("game_container").material
	s_material.set_shader_parameter("ultimate", true)
	var tween = create_tween()
	tween.parallel().tween_property(LayerManager.hud.get_node("RootControl"),"modulate",Color(1.0,1.0,1.0,0.0),3.0)
	tween.parallel().tween_property(LayerManager.awareness_display,"modulate",Color(1.0,1.0,1.0,0.0),3.0)
	await get_tree().create_timer(6).timeout
	Hud.show_boss_bar(healthbar_underlays[phase],healthbar_overlays[phase],boss_names[phase],boss_name_settings[phase],phase_overlay_index[phase])
	Hud.update_bossbar(1.0)
	if boss_type == "scifi":
		$Ground.visible = false
		$Filling.visible = false
		$Ground_Cyber.visible = true
		$ColorRect.visible = true
		$Filling_Cyber.visible = true
	
	
	
	phase_changing = false
	boss.current_health = boss.boss_healthpools[phase]
	boss.max_health = boss.boss_healthpools[phase]
	await get_tree().create_timer(3).timeout
	var tween2 = create_tween()
	tween2.parallel().tween_property(LayerManager.hud.get_node("RootControl"),"modulate",Color(1.0,1.0,1.0,1.0),3.0)
	tween2.parallel().tween_property(LayerManager.awareness_display,"modulate",Color(1.0,1.0,1.0,1.0),3.0)

	boss.hitable = true
	await get_tree().create_timer(3).timeout
	s_material.set_shader_parameter("ultimate", false)
	boss.get_node("BTPlayer").blackboard.set_var("phase", phase)
	

var lifetime = 0.0
var animation_time = 7.0
var fade_time = .75
var camera_move_time = 3.0
func _process(delta: float) -> void:
	if !active:
		return
	lifetime+=delta
	
	if lifetime >= animation_time and lifetime < animation_time+fade_time:
		finish_animation()
	if lifetime >= animation_time+fade_time and lifetime < animation_time+fade_time+camera_move_time:
		var linear_t = (lifetime-(animation_time+fade_time))/camera_move_time
		var t = ease(linear_t, -2.0) # smooth ease in/out
		camera.global_position = ((player1.global_position + player2.global_position) / 2).lerp(boss.global_position,t) +camera.get_cam_offset(delta)
	elif lifetime >= animation_time+fade_time+camera_move_time and lifetime < animation_time+fade_time+camera_move_time+camera_move_time:
		var linear_t = (lifetime-(animation_time+fade_time+camera_move_time))/camera_move_time
		var t = ease(linear_t, -2.0) # smooth ease in/out
		camera.global_position = ((player1.global_position + player2.global_position) / 2).lerp(boss.global_position,1-t) +camera.get_cam_offset(delta)
	elif lifetime>= animation_time+fade_time+camera_move_time+camera_move_time:
		finish_intro()		
	if animation!= "":
		boss_animation()

func finish_intro():
	player1.disabled = false
	if is_multiplayer:
		player2.disabled = false
	LayerManager.camera_override = false
	boss.get_node("BTPlayer").blackboard.set_var("attack_mode", "NONE")
	return


func boss_signal(sig :String, value1, value2):
	match sig:
		"spawn_enemies":
			if is_multiplayer:
				Spawner.spawn_enemies([player1,player2], self, LayerManager.placable_cells.duplicate(),LayerManager.room_instance_data,LayerManager,true,value1,value2)
			else:
				Spawner.spawn_enemies([player1], self, LayerManager.placable_cells.duplicate(),LayerManager.room_instance_data,LayerManager,true,value1,value2)
			var enemies : Array[Node]= []
			var positions : Array[Vector2] = []
			positions.append(player1.global_position)
			if is_multiplayer:
				positions.append(player2.global_position)
			for child in get_children():
				if child.is_in_group("enemy"):
					enemies.append(child)
				
					var board = child.get_node("BTPlayer").blackboard
					if board.get_var("state") == "spawning":
						continue
					if phase < 2 and !child.is_boss:
						child.global_position.y = max(child.global_position.y,-80)
					var distances_squared = []
					for pos in positions: 
						distances_squared.append(child.global_position.distance_squared_to(pos))
					var i = 0
					if distances_squared.size()>1 and distances_squared[1]<distances_squared[0]:
						i= 1
					board.set_var("target_pos", positions[i])
					board.set_var("player_idx", i)
					board.set_var("state", "agro")
			LayerManager.awareness_display.enemies = enemies.duplicate()


func finish_animation():
	var tween = create_tween()
	tween.tween_property(LayerManager.BossIntro.get_node("Transition"),"modulate",Color(0.0,0.0,0.0,0.0),fade_time)
	await tween.finished
	LayerManager.BossIntro.visible = false
	LayerManager.BossIntro.get_node("Transition").modulate = Color(0.0,0.0,0.0,1.0)
	return



func boss_death():
	Hud.hide_boss_bar()


func _on_enemy_take_damage(_damage : int,current_health : int,_enemy : Node, direction = Vector2(0,-1)) -> void:
	var boss_health1 = boss.current_health
	if boss_type =="scifi" and current_health <= 0 and phase == 0:
		if is_multiplayer:
			if .5 < randf():
				boss.take_damage(10,player1,direction)
			else:
				boss.take_damage(10,player2,direction)
		else:
			boss.take_damage(10,player1,direction)
		pass
	var boss_health2 = boss.current_health
	if boss_type == "scifi":
		var mini_phase1 = int(( boss_health1 / float(boss.max_health) ) * 3)
		var mini_phase2 = int(( boss_health2 / float(boss.max_health) ) * 3)
		print("P1: "+str(mini_phase1)+"P2: "+str(mini_phase2))
		if  mini_phase1 != 3 and mini_phase1 >  mini_phase2:
			scifi_phase1_middles()
		
var middle_active : int = 0
func scifi_phase1_middles():
	var attack_inst = load("res://Game Elements/Bosses/scifi/wave_attack.tscn").instantiate()
	attack_inst.global_position = boss.global_position
	attack_inst.c_owner = boss
	attack_inst.direction = Vector2.UP
	call_deferred("add_child",attack_inst)
	var bt_player = boss.get_node("BTPlayer")
	var board = bt_player.blackboard
	if board:
		board.set_var("attack_mode", "DISABLED")
	middle_active +=1
	# Disable the forcefield collision
	$Forcefield/CollisionShape2D.set_deferred("disabled", true)
	# Enable the boss collision
	boss.get_node("CollisionShape2D").set_deferred("disabled", false)
	var tween = create_tween()
	tween.tween_property($Forcefield,"modulate",Color(1.0,1.0,1.0,0.0),1.0)
	await get_tree().create_timer(8.0).timeout
	if middle_active <= 1:
		# Disable the boss collision
		boss.get_node("CollisionShape2D").set_deferred("disabled", true)
		# Enable the forcefield collision
		$Forcefield/CollisionShape2D.set_deferred("disabled", false)
	var tween2 = create_tween()
	tween2.tween_property($Forcefield,"modulate",Color(1.0,1.0,1.0,1.0),1.0)
	if board:
		board.set_var("attack_mode", "NONE")
	middle_active -=1
	




func boss_animation():
	if boss_type=="scifi":
		var eye = boss.get_node("Segments/Eye/3")
		var board = boss.get_node("BTPlayer").blackboard
		var is_purple = board.get_var("player_idx") as bool
		var track_position = player1.global_position if is_purple else player2.global_position
		eye.position = (track_position-eye.global_position).normalized()*6
		match animation:
			"idle":
				boss.get_node("Segments").z_index=0
				var count = 0
				for child in boss.get_node("Segments/Rims").get_children():
					count+=1
					var angle = 45 *count+lifetime*20
					var new_position =Vector2.UP.rotated(deg_to_rad(angle)) * (32 +sin(lifetime*count/3)*2)
					child.get_node("RimVis").global_position = new_position + boss.global_position
					child.get_node("RimVis").global_rotation = deg_to_rad(angle - 224)
			"basic_laser":
				var gun = boss.get_node("Segments/GunParts")
				gun.rotation = lerp_angle(gun.rotation, (track_position - boss.global_position).angle(), 0.03)
var resetting = 0

func animation_change(new_anim: String) -> void:
	animation_reset()
	animation = new_anim

func animation_reset() -> void:
	var rims = boss.get_node("Segments/Rims")
	for rim in rims.get_children():
		var rimvis = rim.get_node("RimVis")
		rimvis.position = Vector2.ZERO
		rimvis.rotation = 0

func scifi_laser_attack(num_lasers):
	animation_change("basic_laser")
	boss.get_node("AnimationTree").set("parameters/conditions/laser_basic",true)
	await get_tree().create_timer(3.0).timeout
	boss.get_node("AnimationTree").set("parameters/conditions/laser_basic",false)
	
	var gun = boss.get_node("Segments/GunParts")
	var board = boss.get_node("BTPlayer").blackboard
	var is_purple = board.get_var("player_idx") as bool
	var track_position = player1.global_position if is_purple else player2.global_position
	var inst = load("res://Game Elements/Bosses/scifi/singul_laser_attack.tscn").instantiate()
	
	inst.direction = Vector2.RIGHT.rotated(lerp_angle(gun.rotation, (track_position - boss.global_position).angle(), 0.03))
	
	inst.global_position = boss.global_position
	inst.c_owner= boss
	inst.laser_rotation = false
	inst.num_lasers = num_lasers
	inst.laser_wave_width = 2048
	inst.lifespan = 12.1
	call_deferred("add_child",inst)
	
	
	# Optional longer idle wait, also using frame loop
	var idle_timer = Timer.new()
	idle_timer.wait_time = 12.0
	idle_timer.one_shot = true
	add_child(idle_timer)
	idle_timer.start()
	while idle_timer.time_left > 0:
		track_position = player1.global_position if is_purple else player2.global_position
		
		# Update laser direction
		inst.direction = Vector2.RIGHT.rotated(gun.rotation)
		inst.global_position = boss.global_position
		inst.l_rotation = rad_to_deg(gun.rotation)
		inst._update_laser_collision_shapes()
		#Update shader
		var s_material = LayerManager.get_node("game_container").material
		s_material.set_shader_parameter("laser_rotation",inst.l_rotation)
		s_material.set_shader_parameter("laser_impact_world_pos",inst.global_position)
		if get_tree():
			await get_tree().process_frame
	animation_change("idle")
	


func activate(camera_in : Node, player1_in : Node, player2_in : Node):
	print("boss room activate")
	active = true
	camera = camera_in
	player1 = player1_in
	player2 = player1_in
	if boss_type=="scifi":
		animation_change("dead")
		var bt_player = boss.get_node("BTPlayer")
		bt_player.blackboard.set_var("attack_mode", "DISABLED")
	#return
	player1.disabled = true
	print(player1.disabled)
	print(player1)
	if is_multiplayer:
		player2 = player2_in
		player2.disabled = true
	Hud =LayerManager.hud
	LayerManager.BossIntro.get_node("BossName").text = boss_name
	LayerManager.BossIntro.get_node("Boss").texture = boss_splash_art
	LayerManager.BossIntro.get_node("BossName").add_theme_font_override("font", boss_font)
	screen = LayerManager.get_node("game_container/game_viewport")
	for node in get_children():
		if node.is_in_group("pathway"):
			node.disable_pathway(true)
	LayerManager.camera_override = true
	screen.render_target_update_mode = SubViewport.UPDATE_DISABLED
	var transition1 = LayerManager.get_node("Transition/Transition")
	transition1.visible = true
	var tween = create_tween()
	tween.tween_property(transition1,"modulate:a",1.0,1.0)
	await tween.finished
	LayerManager.BossIntro.visible = true
	screen.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	transition1.visible = false
	transition1.modulate.a = 0.0
	LayerManager.BossIntro.get_node("AnimationPlayer").play("main")
	camera.global_position = ((player1.global_position + player2.global_position) / 2)
	Hud.show_boss_bar(healthbar_underlays[phase],healthbar_overlays[phase],boss_names[phase],boss_name_settings[phase],phase_overlay_index[phase])
