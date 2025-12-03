extends Control

@onready var BreakFX = $BreakFX
@onready var UI_Group = $SubViewportContainer/SubViewport/UI_Group

func _ready():
	randomize()
	await get_tree().process_frame
	await get_tree().process_frame
	explode_ui()

func explode_ui():
	UI_Group.visible = false
	#var fragments = make_fragments_debug(10)
	#for f in fragments:
		#BreakFX.add_child(f)
		#f.begin_break()

	var tex = $SubViewportContainer/SubViewport.get_texture() as Texture2D
	print(tex)
	print("Texture size: ", tex.get_size())
	var fragments = make_fragments(tex, 25)
	for f in fragments:
		BreakFX.add_child(f)
		f.begin_break()

func rewind_ui():
	for f in BreakFX.get_children():
		f.begin_rewind()
	# Wait a bit before showing UI_Group again
	await get_tree().create_timer(1.6).timeout
	UI_Group.visible = true

func make_fragments(tex: Texture2D, fragment_count: int) -> Array:
	var pieces = []
	for i in fragment_count:
		var frag = load("res://Game Elements/ui/break_frag.tscn").instantiate()
		frag.position = UI_Group.get_global_position() + UI_Group.size/2
		frag.get_child(0).texture = ImageTexture.create_from_image(tex.get_image())
		pieces.append(frag)
	return pieces
#
#func make_fragments_debug(fragment_count: int) -> Array:
	#var pieces = []
	#var ui_pos = UI_Group.get_global_position() + UI_Group.size / 2
	#for i in fragment_count:
		#var frag = Node2D.new()
		#frag.position = ui_pos
#
		## Add BreakFX script
		#var fx_script = preload("res://Game Elements/ui/break_fx.gd")
		#frag.set_script(fx_script)
#
		## Debug rectangle instead of texture
		#var rect = ColorRect.new()
		#rect.color = Color(randf(), randf(), randf())
		#rect.size = Vector2(50, 50)
		#frag.add_child(rect)
#
		#pieces.append(frag)
	#return pieces
