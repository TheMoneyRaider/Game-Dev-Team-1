extends Node2D

@export var anim_frame : int
@export var min_time : float = 2.0
@export var max_time : float = 6.0
var spawn_time : float = 4.0
var time : float = 10.0

func set_frame(frame_in : int):
	get_node("../Sprite2D").frame = frame_in
	if time!=0.0:
		get_node("../Sprite2D").material.set_shader_parameter("frame", frame_in)

func _ready() -> void:
	spawn_time= randf_range(min_time,max_time)
	time= spawn_time
	get_node("../Sprite2D").material.set_shader_parameter("frame", get_node("../Sprite2D").frame)
	get_node("../Sprite2D").material.set_shader_parameter("hframes", get_node("../Sprite2D").hframes)
	get_node("../Sprite2D").material.set_shader_parameter("vframes", get_node("../Sprite2D").vframes)
	start_spawn()
	
func start_spawn():
	get_node("../CollisionShape2D").disabled = true
func end_spawn():
	get_node("../CollisionShape2D").disabled = false
	process_mode = Node.PROCESS_MODE_DISABLED
	get_node("../BTPlayer").blackboard.set_var("state","idle")
	get_node("../Sprite2D").material.set_shader_parameter("progress", 0.0)
	
func _process(delta: float) -> void:
	if time==0.0:
		return
	if time!=0.0 and max(0.0,time-delta)==0.0:
		end_spawn()
	time = max(0.0,time-delta)
	var progress= clamp(float(time/spawn_time),0.0,1.0)
	get_node("../Sprite2D").material.set_shader_parameter("progress", progress)
	
