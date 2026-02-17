extends Node2D

var trap_cells := []
var blocked_cells := []
var liquid_cells : Array[Array]= [[],[],[],[],[],[],[],[],[],[],[],[],[],[],[],[]]

var camera : Node = null
var player1 : Node = null
var player2 : Node = null
var LayerManager : Node = null
var screen : Node = null
var active : bool = false
var is_multiplayer : bool = false

func _ready() -> void:
	is_multiplayer = Globals.is_multiplayer
var lifetime = 0.0
	
	
func _process(delta: float) -> void:
	if !active:
		return
	lifetime+=delta
	if is_multiplayer:
		camera.global_position = (player1.global_position + player2.global_position) / 2 +camera.get_cam_offset(delta)
	else:
		camera.position = player1.global_position+camera.get_cam_offset(delta)
	if lifetime >= 1.5:
		finish_intro()




func finish_intro():
	var tween = create_tween()
	tween.tween_property($CanvasLayer/Transition,"modulate",Color(0.0,0.0,0.0,0.0),.75)
	await tween.finished
	$CanvasLayer.visible = false
	player1.disabled = false
	if is_multiplayer:
		player2.disabled = false
	LayerManager.camera_override = false
	return
	
	


func activate(layermanager : Node, camera_in : Node, player1_in : Node, player2_in : Node):
	print("boss room activate")
	active = true
	camera = camera_in
	player1 = player1_in
	player1.disabled = true
	if is_multiplayer:
		player2 = player2_in
		player2.disabled = true
	LayerManager =layermanager
	screen = LayerManager.get_node("game_container/game_viewport")
	for node in get_children():
		if node.is_in_group("pathway"):
			node.disable_pathway(true)
	
	LayerManager.camera_override = true
	screen.render_target_update_mode = SubViewport.UPDATE_DISABLED
	var transition1 = LayerManager.get_node("Transition")
	transition1.visible = true
	var tween = create_tween()
	tween.tween_property(transition1,"modulate:a",1.0,1.0)
	await tween.finished
	$CanvasLayer.visible = true
	screen.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	transition1.visible = false
	transition1.modulate.a = 0.0
