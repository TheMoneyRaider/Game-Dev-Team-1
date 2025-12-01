extends CanvasLayer
@export var recent_seconds := 8
@export var rewind_time := 10 #can't be smaller than recent_seconds. also the actual rewind time is generally 3 seconds or so greater.
@export var recent_fps : float = 32.0
@export var longterm_fps : float = 8.0
#Note, these goals arn't actually achieved. They're more like weights. 
@export var recent_target_fps = 5*recent_fps # Seconds per second goal by the recent frame buffer end
@export var long_target_fps = 8*longterm_fps # Seconds per second goal by the longterm frame buffer end
@export var longterm_buffer_size := 10000

@onready var replay_texture: TextureRect = $Control/Replay
@onready var death_box: VBoxContainer = $Control/VBoxContainer

var recent_buffer := []
var longterm_buffer := []
var capture_timer: Timer
var capturing := true
var total_time = 0.0

var frame_amount = 0

func _ready():
	hide()
	#Disable buttons at start
	for button in death_box.get_children():
		if button is Button:
			button.disabled = true
	capture_timer = Timer.new()
	capture_timer.wait_time = 1.0 / recent_fps
	capture_timer.one_shot = false
	add_child(capture_timer)
	capture_timer.timeout.connect(_capture_frame)
	capture_timer.start()

func _process(delta):
	if capturing:
		total_time+=delta

func activate():
	capturing=false
	capture_timer.stop()
	show()
	get_tree().paused = true
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	var game_root = get_parent().get_node("game_container/game_viewport/game_root")
	game_root.call_deferred("set", "process_mode", Node.PROCESS_MODE_DISABLED)
	for button in death_box.get_children():
		if button is Button:
			button.disabled = false

func _capture_frame():
	frame_amount +=1
	if not capturing:
		return
	var viewport = get_parent().get_node("game_container/game_viewport") as SubViewport
	var img = viewport.get_texture().get_image()

	#Add to recent buffer (rotating)
	recent_buffer.append(img)
	if recent_buffer.size() > recent_seconds * recent_fps:
		var oldest = recent_buffer.pop_front()
		#Push oldest to long-term buffer
		if frame_amount % int(recent_fps/longterm_fps) == 0:
			longterm_buffer.append(oldest)
			if longterm_buffer.size() > longterm_buffer_size:
				longterm_buffer.pop_front()

func _on_quit_pressed():
	get_tree().quit()
func _on_menu_pressed():
	get_tree().change_scene_to_file("res://Game Elements/ui/main_menu.tscn")

func _on_replay_pressed():
	replay_texture.visible = true
	death_box.visible = false
	play_replay_reverse()

func play_replay_reverse():
	#Concatenate frames
	var frames = longterm_buffer.duplicate()
	frames.append_array(recent_buffer)
	var total_frames = frames.size()
	var running_time = 0.0
	var running_intensity = 0.0
	var min_shader_intensity = .1
	var max_shader_intensity = 1
	
	#Variables
	var recent_len = recent_buffer.size() 
	var long_len = longterm_buffer.size()
	#Remove first few frames(they're bad)
	if long_len > 0:
		long_len-=1
	else:
		recent_len-=1
	total_frames-=1
	
	#Change rewind time if total time is too low
	if total_time < 3/float(2) * rewind_time:
		rewind_time = float(2)/3 * total_time
	
	var base_recent_wait = 1.0 / recent_fps #slowest recent frame 
	var max_recent_wait = 1.0 / recent_target_fps #fastest recent frame
	var base_long_wait = max_recent_wait *  recent_fps / longterm_fps #slowest long-term frame 
	var max_long_wait = 1.0 / float(long_target_fps) #fastest long-term frame
	# Set the first wait_time
	var wait_time = 1.0 / recent_target_fps
	
	var weights = [] 
	var running_times = []
	var total_weight = 0.0
	for idx in range(total_frames,0,-1):
		#Determine if frame is recent or long-term
		if idx >= long_len:
			#Recent buffer: exponential acceleration
			var local_idx = idx - long_len
			var progress = float(local_idx) / float(recent_len) 
			wait_time = base_recent_wait * pow(max_recent_wait / base_recent_wait, 1 - progress)
			weights.append(wait_time) 
			total_weight += wait_time
		else:
			#Long-term buffer: slow frames, but still accelerating
			var local_idx = idx
			var progress = float(local_idx) / float(long_len) 
			wait_time = base_long_wait * pow(max_long_wait / base_long_wait, 1 - progress)
			weights.append(wait_time) 
			total_weight += wait_time
		#Set shader value
		if idx >= long_len:
			running_time+=wait_time
		else:
			running_time+=wait_time*longterm_fps/recent_fps
		running_times.append(running_time)
	
	var weights_len = len(weights)
	
	for idx in range(total_frames,0,-1):
		var tex = ImageTexture.create_from_image(frames[idx])
		replay_texture.texture = tex
		#Set shader value
		if idx >= long_len:
			running_intensity+= 1/ recent_fps
		else:
			running_intensity+= 1/ longterm_fps
		wait_time = (weights[weights_len-1-idx] / total_weight) * rewind_time
		replay_texture.material.set_shader_parameter("intensity", get_shader_intensity(running_intensity, total_time, min_shader_intensity, max_shader_intensity))
		replay_texture.material.set_shader_parameter("time", running_times[weights_len-1-idx])
		await get_tree().create_timer(wait_time).timeout
	end_replay()

func get_shader_intensity(running_time: float, total_time_func: float, min_intensity: float, max_intensity: float, exponent: float = 2.0) -> float:
	var t = clamp(running_time / total_time_func, 0.0, 1.0)
	#Exponential curve: start slow, end fast
	var exp_curve = pow(t, exponent)
	# Map to shader intensity
	return lerp(min_intensity, max_intensity, exp_curve)
func end_replay():
	#TODO do a transition
	capturing = false
	recent_buffer.clear()
	longterm_buffer.clear()
	frame_amount = 0
	
	# Create a full-screen overlay with the last frame
	var overlay = load("res://Game Elements/ui/transition_texture.tscn").instantiate()
	overlay.get_node("TextureRect").texture = replay_texture.texture
	get_tree().get_root().add_child(overlay)

	get_tree().paused = false
	# Load the next scene deferred, the overlay keeps the last frame visible
	get_tree().call_deferred("change_scene_to_file", "res://Game Elements/General Game/layer_manager.tscn")
