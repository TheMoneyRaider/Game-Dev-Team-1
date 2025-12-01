extends CanvasLayer
@export var frame_buffer_size: int = 180  # Number of frames to record (~3 sec at 60fps)

@onready var bg_blur: TextureRect = $Control/Game_Blur
@onready var replay_texture: TextureRect = $Control/Replay
@onready var replay_btn: Button = $Control/VBoxContainer/Rewind
@onready var death_box: VBoxContainer = $Control/VBoxContainer

var frame_buffer := []
var capturing := true

enum ButtonsHere {
	Rewind,
	Quit
}

var active = ButtonsHere.Rewind

const HANDLED_ACTIONS = ["ui_accept", "ui_up", "ui_down"]

func _ready():
	hide()
	replay_texture.visible = false
	replay_btn.pressed.connect(_on_replay_pressed)
	
func _process(_delta):
	if capturing:
		capture_frame()

func _input(event):
	if event.is_pressed():
		var occ = ""
		for action in HANDLED_ACTIONS:
			if event.is_action_pressed(action):
				occ = action
		match occ:
			"ui_accept":
				press()
			"ui_up":
				prev_button()
			"ui_down":
				next_button()

func press():
	print(active)
	match active:
		ButtonsHere.Rewind:
			_on_replay_pressed()
		ButtonsHere.Quit:
			get_tree().quit()
			
			

func next_button():
	active = (active + 1) % ButtonsHere.size() as ButtonsHere
func prev_button():
	active = (active + ButtonsHere.size() - 1) % ButtonsHere.size() as ButtonsHere
	


func capture_frame():
	var viewport = get_viewport()
	var img = viewport.get_texture().get_image()
	if frame_buffer.size() >= frame_buffer_size:
		frame_buffer.pop_front()
	frame_buffer.append(img)

func _on_replay_pressed():
	replay_texture.visible = true
	death_box.visible = false
	capturing = false
	play_replay_reverse()

func play_replay_reverse():
	var idx = frame_buffer.size() - 1
	var timer = Timer.new()
	timer.wait_time = 1.0 / 60.0
	timer.one_shot = false
	add_child(timer)
	timer.start()
	timer.timeout.connect(func():
		if idx < 0:
			timer.queue_free()
			end_replay()
			return
		var tex = ImageTexture.create_from_image(frame_buffer[idx])
		replay_texture.texture = tex
		idx -= 1
)
func end_replay():
	pass
