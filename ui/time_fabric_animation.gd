extends Control

@onready var icon := $HBoxContainer/TextureRect
@onready var label := $HBoxContainer/Label

@export var spritesheet : Texture2D            #The sprite sheet
@export var frame_width : int = 16             #adjust to match your sheet
@export var frame_height : int = 16            #adjust to match your sheet
@export var frame_count : int = 6              #number of frames in sheet
@export var fps := 1                           #animation speed
@export var smear_strength := 0.6              #0=sharp, 1=ghost-smear

var frames : Array[Texture2D] = []
var current_frame := 0
var next_frame := 1
var anim_time := 0.0

func _ready() -> void:
	_slice_frames()

func _process(delta: float) -> void:
	if frames.is_empty():
		return

	var prev_frame_index := int(anim_time)
	anim_time += delta * fps
	var new_frame_index := int(anim_time)

	if new_frame_index != prev_frame_index:
		current_frame = next_frame
		next_frame = (next_frame + 1) % frame_count

	var t := anim_time - int(anim_time)
	var smear_t := pow(t, smear_strength)
	icon.texture = _blend_textures(frames[current_frame], frames[next_frame], smear_t)


func _slice_frames() -> void:
	frames.clear()

	var img := spritesheet.get_image()

	for i in range(frame_count):
		var x := i * frame_width
		var frame_image := Image.create(frame_width, frame_height, false, Image.FORMAT_RGBA8)
		frame_image.blit_rect(img, Rect2i(x, 0, frame_width, frame_height), Vector2i(0, 0))
		var tex := ImageTexture.create_from_image(frame_image)
		frames.append(tex)


func _blend_textures(a: Texture2D, b: Texture2D, t: float) -> Texture2D:
	var img_a := a.get_image()
	var img_b := b.get_image()

	var out := Image.create(img_a.get_width(), img_a.get_height(), false, Image.FORMAT_RGBA8)

	for y in img_a.get_height():
		for x in img_a.get_width():
			var ca = img_a.get_pixel(x, y)
			var cb = img_b.get_pixel(x, y)
			out.set_pixel(x, y, ca.lerp(cb, t))

	return ImageTexture.create_from_image(out)


func set_currency(amount: int) -> void:
	label.text = str(amount)
