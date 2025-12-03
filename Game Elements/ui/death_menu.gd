extends CanvasLayer
# INPUTS -----------------------------------------------------

#Array of frame buffers, each buffer is an Array of Image
#Buffer 0 = highest FPS (64), buffer 1 = 32, buffer 2 = 16, ... etc.
@export var buffers: Array[Array] = [[],[],[],[],[],[]]

#FPS for each buffer in order:
@export var buffer_fps : Array[int]= [64, 32, 16, 8, 4, 2]

#Total real time (seconds) to complete the rewind
@export var rewind_time : float = 12.0

#Base speed entering buffer 0
var base_speed : float = 1.0
#Max and min shader values
@export var min_shader_intensity : float = 0.0
@export	var max_shader_intensity : float = 1.0

#Seconds stored per buffer
@export var buffer_time : float = 6.0


# INTERNALS ---------------------------------------------------
var T : Array[float] = []                  #duration (seconds) of each buffer
var cumulative_time : Array[float] = []    #prefix sum for each Ti
var total_time : float= 0.0

var progress : float = 0.0         #0->1 during rewind
var ln2 : float = log(2.0)

@onready var replay_texture: TextureRect = $Control/Replay
@onready var death_box: VBoxContainer = $Control/VBoxContainer

var capturing := true
var rewinding := false
var final_frame : Image

var frame_amount = 0

func _ready():
	hide()
	#Disable buttons at start
	for button in death_box.get_children():
		if button is Button:
			button.disabled = true

func _process(delta):
	if capturing:
		total_time += delta
		_capture_frame(0)
	if !rewinding:
		return
	var frame = update_rewind(delta)
	if frame:
		replay_texture.texture = ImageTexture.create_from_image(frame)
		

func activate():
	capturing=false
	show()
	get_tree().paused = true
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	var game_root = get_parent().get_node("game_container/game_viewport/game_root")
	game_root.call_deferred("set", "process_mode", Node.PROCESS_MODE_DISABLED)
	for button in death_box.get_children():
		if button is Button:
			button.disabled = false

func _capture_frame(index : int, frame : Image = null):
	#Check if we need a new frame
	if buffers[index].size() >= int(total_time*buffer_fps[index]):
		return
	#we need a new frame
	if !frame:
		var viewport = get_parent().get_node("game_container/game_viewport") as SubViewport
		frame = viewport.get_texture().get_image()
	
	##Save final frame
	if index==0 and buffers[index].size() == 2:
		final_frame = frame.duplicate(true)
	##Add to buffer
	buffers[index].push_front(frame.duplicate(true))
	if index == 5:
		return
	#Only rotate if not the last buffer
	if buffers[index].size() > int(buffer_time*buffer_fps[index]):
		_capture_frame(index+1,buffers[index].pop_back().duplicate(true))

func _on_quit_pressed():
	get_tree().paused = false
	get_tree().quit()

func _on_menu_pressed():
	get_tree().paused = false
	get_tree().call_deferred("change_scene_to_file", "res://Game Elements/ui/main_menu.tscn")

func _on_replay_pressed():
	replay_texture.visible = true
	death_box.visible = false
	rewinding=true
	#Change rewind time if total time is too low
	if total_time < 1.5 * rewind_time:
		rewind_time = .6 * total_time
	for buf in buffers:
		print(buf.size())
	prepare_rewind()

func prepare_rewind():
	T.clear()
	cumulative_time.clear()

	var time_sum = 0.0

	for i in range(buffers.size()):
		var buffer := buffers[i]
		var count := buffer.size()
		var fps := buffer_fps[i]

		if count == 0:
			T.append(0.0)
			cumulative_time.append(time_sum)
			continue

		#Duration of buffer in seconds
		var Ti := float(count) / float(fps)
		T.append(Ti)

		time_sum += Ti
		cumulative_time.append(time_sum)
	progress = 0.0

func update_rewind(delta: float) -> Image:
	if total_time <= 0.0:
		return null

	# Advance progress (0 -> 1 over rewind_time seconds)
	progress += delta / rewind_time
	progress = clamp(progress, 0.0, 1.0)

	# Map progress to "total frame count" coordinate
	var cursor = progress * rewind_time
	var time_ratio = (rewind_time/total_time)

	# Find which buffer we are in
	var i = 0
	while i < (cumulative_time.size()-1) and cursor > cumulative_time[i] * time_ratio:
		i += 1

	if progress == 1.0:  # rewind complete
		end_replay()
		return null

	var buffer := buffers[i]

	var prev_time = cumulative_time[i - 1]*time_ratio if i > 0 else 0.0
	var local_time = cursor - prev_time

	var frame_index = int(floor(local_time * buffer_fps[i]))
	print("Frame: "+str(frame_index)+" Buffer: "+str(i)+" Progress: "+str(progress))
	frame_index = clamp(frame_index, 0, buffer.size() - 1)
	return buffer[frame_index]


#replay_texture.material.set_shader_parameter("intensity", get_shader_intensity(running_times[weights_len-1-idx], running_times[weights_len-1], min_shader_intensity, max_shader_intensity))
#replay_texture.material.set_shader_parameter("time", running_times[weights_len-1-idx])
func get_shader_intensity(current_time: float, total_time_func: float, min_intensity: float, max_intensity: float, exponent: float = 2.0) -> float:
	var t = clamp(current_time / total_time_func, 0.0, 1.0)
	#Exponential curve: start slow, end fast
	var exp_curve = pow(t, exponent)
	# Map to shader intensity
	return lerp(min_intensity, max_intensity, exp_curve)

func end_replay():
	capturing = false
	buffers.clear()
	
	# Create a full-screen overlay with the last frame
	var overlay = load("res://Game Elements/ui/transition_texture.tscn").instantiate()
	overlay.get_node("TextureRect").texture = ImageTexture.create_from_image(final_frame)
	overlay.get_properties(replay_texture)
	get_tree().get_root().add_child(overlay)
	get_tree().paused = false
	# Load the next scene deferred, the overlay keeps the last frame visible
	get_tree().call_deferred("change_scene_to_file", "res://Game Elements/General Game/layer_manager.tscn")
