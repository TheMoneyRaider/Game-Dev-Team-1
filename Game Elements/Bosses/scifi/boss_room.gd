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
@export var boss : Node
@export var boss_name : String
@export var boss_font : Font
#This is what values the bossbar shader is looking for
@export var phase_overlay_index : Array[int]
@export var boss_type : String =""
var phase_changing : bool = false


func _ready() -> void:
	LayerManager = get_tree().get_root().get_node("LayerManager")
	is_multiplayer = Globals.is_multiplayer
	boss.boss_phase_change.connect(_on_boss_phase_change)
	boss.enemy_took_damage.connect(LayerManager._on_enemy_take_damage)
	
func _on_boss_phase_change(boss_in : Node):
	var hits = boss_in.hitable
	boss_in.hitable = false
	Hud.update_bossbar(0.0)
	if phase_changing:
		return
	phase_changing = true
	phase=boss_in.phase
	#Wave Attack
	var attack_inst = load("res://Game Elements/Bosses/scifi/wave_attack.tscn").instantiate()
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
	Hud.show_boss_bar(healthbar_underlays[phase],healthbar_overlays[phase],phase_overlay_index[phase])
	Hud.update_bossbar(1.0)
	if boss_type == "scifi":
		$Ground.visible = false
		$Filling.visible = false
		$Ground_Cyber.visible = true
		$ColorRect.visible = true
		$Filling_Cyber.visible = true
	
	
	
	phase_changing = false
	boss_in.current_health = boss_in.boss_healthpools[phase]
	boss_in.max_health = boss_in.boss_healthpools[phase]
	await get_tree().create_timer(3).timeout
	var tween2 = create_tween()
	tween2.parallel().tween_property(LayerManager.hud.get_node("RootControl"),"modulate",Color(1.0,1.0,1.0,1.0),3.0)
	tween2.parallel().tween_property(LayerManager.awareness_display,"modulate",Color(1.0,1.0,1.0,1.0),3.0)

	boss_in.hitable = true
	await get_tree().create_timer(3).timeout
	s_material.set_shader_parameter("ultimate", false)
	

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

func finish_intro():
	player1.disabled = false
	if is_multiplayer:
		player2.disabled = false
	LayerManager.camera_override = false
	return


func finish_animation():
	var tween = create_tween()
	tween.tween_property(LayerManager.BossIntro.get_node("Transition"),"modulate",Color(0.0,0.0,0.0,0.0),fade_time)
	await tween.finished
	LayerManager.BossIntro.visible = false
	LayerManager.BossIntro.get_node("Transition").modulate = Color(0.0,0.0,0.0,1.0)
	return



func boss_death():
	Hud.hide_boss_bar()

	


func activate(camera_in : Node, player1_in : Node, player2_in : Node):
	print("boss room activate")
	active = true
	camera = camera_in
	player1 = player1_in
	player2 = player1_in
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
	Hud.show_boss_bar(healthbar_underlays[phase],healthbar_overlays[phase],phase_overlay_index[phase])
