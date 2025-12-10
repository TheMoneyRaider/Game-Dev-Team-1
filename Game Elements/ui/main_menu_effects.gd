extends Control

class PlayerState:
	var hover_button: Button = null
	var pressing: bool = false
	var input: String = "-1"

class UIState:
	var player1: PlayerState
	var player2: PlayerState	
	
@onready var BreakFX = $BreakFX
@onready var UI_Group = $SubViewportContainer/SubViewport/UI_Group
@onready var cooldown : float = 0.0
@onready var the_ui : Texture2D
@onready var is_disruptive : bool = true
@onready var is_purple: bool = true
@onready var exploaded: bool = false
@onready var prepared = false
@export var capture_all_states: bool = false
var ui_textures: Dictionary = {}

var UI: UIState = UIState.new()



func _ready():
	if !capture_all_states:
		preload_all_textures()
	UI.player1 = PlayerState.new()
	UI.player2 = PlayerState.new()
	randomize()
	cooldown = 10.0
	await get_tree().process_frame
	await get_tree().process_frame
	# Capture the UI once
	var vp_tex = $SubViewportContainer/SubViewport.get_texture()
	the_ui = ImageTexture.create_from_image(vp_tex.get_image())
	UI_Group.visible = true if capture_all_states else false
	print("explode")
	explode_ui()
	cooldown = -1
	if capture_all_states:
		capture_all_ui_states()

func _begin_explosion_cooldown():
	if cooldown < 0:
		print("explode")
		cooldown = randf_range(2,4)
		exploaded = true

func _process(delta):
	$ColorRect.material.set_shader_parameter("time", $ColorRect.material.get_shader_parameter("time")+delta)
	if Globals.player1_input:
		if !prepared:
			_set_display()
			prepared=true
			UI.player1.input = Globals.player1_input
			UI.player2.input = Globals.player2_input
			if UI.player1.input != "key":
				UI.player1.hover_button = $SubViewportContainer/SubViewport/UI_Group/VBoxContainer.get_child(2)
			if UI.player2.input != "key":
				UI.player2.hover_button = UI_Group.get_child(1)
		if Input.is_action_just_pressed("swap_" + Globals.player1_input):
			is_purple=!is_purple
			is_disruptive = !is_disruptive
	if prepared:
		inputs(UI.player1.input)
		inputs(UI.player2.input)
		update_ui_display() #SUPER LAGGY FIND BETTER WAY #TODO
	cooldown -= delta
	if is_disruptive:
		if get_viewport() != null:
			var mouse_pos = get_viewport().get_mouse_position()
			for frag in $BreakFX.get_children():
				frag.apply_force_frag(mouse_pos)
	if cooldown < 0 and cooldown > -.9 and exploaded:
		exploaded = false
		print("rewind")
		cooldown = 1
		rewind_ui(cooldown)

func get_button_polygon(button: Button, frag_start_pos: Vector2) -> Array:
	var rect = button.get_global_rect()
	return [
		rect.position - frag_start_pos,
		rect.position + Vector2(rect.size.x, 0) - frag_start_pos,
		rect.position + rect.size - frag_start_pos,
		rect.position + Vector2(0, rect.size.y) - frag_start_pos
	]

# Recursive helper to collect leaf nodes
func collect_leaf_children(node: Node, bounds: Dictionary) -> void:
	for child in node.get_children():
		if child.get_child_count() == 0:
			# Leaf node, add to dictionary
			if child is Control and child.get_class() == "Control":
				continue
			bounds[child] = child.get_global_rect()
		else:
			# Recurse into children
			collect_leaf_children(child, bounds)

func explode_ui():
	# Get all leaf children of the SubViewport
	var ui_bounds = {}
	collect_leaf_children($SubViewportContainer/SubViewport, ui_bounds)
		
	var button_bounds = {}
	for button in $SubViewportContainer/SubViewport/UI_Group/VBoxContainer.get_children():
		if button is Button:
			button_bounds[button] = button.get_global_rect()
	# Generate fragments
	var fragments_data = generate_jittered_grid_fragments(the_ui.get_size(),40,40)
	for frag_data in fragments_data:
		# Only create a fragment if it overlaps any UI element
		if not overlaps_any_ui_element(frag_data, ui_bounds):
			continue
		var frag = load("res://Game Elements/ui/break_frag.tscn").instantiate()
		BreakFX.add_child(frag)
		
		# Determine if this fragment belongs to a button
		var assigned_buttons = find_button_for_fragment(frag_data, button_bounds)
		
		# Initialize fragment script
		frag.begin_break(frag_data, the_ui, UI_Group.global_position)
		
		# Add clickable area if belongs to a button
		frag.add_interactive_area(frag_data,assigned_buttons)
	print(BreakFX.get_child_count())

func rewind_ui(time : float):
	for f in BreakFX.get_children():
		if "begin_rewind" in f:
			f.begin_rewind(time)

func overlaps_any_ui_element(frag_poly: Array, button_bounds: Dictionary) -> bool:
	for p in frag_poly:
		var global_point = UI_Group.global_position + p
		for rect in button_bounds.values():
			if rect.has_point(global_point):
				return true
	return false

func generate_jittered_grid_fragments(size_tex: Vector2, grid_x: int, grid_y: int, jitter: float = 10.0) -> Array:
	var fragments = []
	var cell_w = size_tex.x / grid_x
	var cell_h = size_tex.y / grid_y
	var points = []
	for x in range(grid_x + 1):
		points.append([])
		for y in range(grid_y + 1):
			points[x].append(Vector2.ZERO)
	var stop = false
	for y in range(grid_y+1):
		for x in range(grid_x+1):
			var px = x * cell_w
			var py = y * cell_h
			for vec in [Vector2(0,0),Vector2(0,size_tex.y),Vector2(size_tex.x,0),Vector2(size_tex.x,size_tex.y)]:
				if Vector2(px,py)==vec:
					points[x][y]= Vector2(px,py)
					stop = true
					break
			if stop:
				stop = false
			elif px == size_tex.x or px == 0:
				points[x][y] = Vector2(
					px,
					jitter_point(py, jitter, 0, size_tex.y)
				)
			elif py == size_tex.y or py == 0:
				points[x][y] = Vector2(
					jitter_point(px, jitter, 0, size_tex.x),
					py
				)
			else:
				points[x][y] = Vector2(
					jitter_point(px, jitter, 0, size_tex.x),
					jitter_point(py, jitter, 0, size_tex.y)
				)
	for y in range(grid_y):
		for x in range(grid_x):
			# Convex hull to ensure valid polygon
			var poly = [points[x][y],points[x+1][y],points[x+1][y+1],points[x][y+1]]
			# Remove last point if it equals the first
			if poly.size() > 1 and poly[0] == poly[poly.size() - 1]:
				poly.remove_at(poly.size() - 1)
			fragments.append(poly)
	return fragments
	
func jitter_point(p: float, jitter: float, min_val: float, max_val: float) -> float:
	return clamp(p + randf_range(-jitter, jitter), min_val, max_val)
	
func find_button_for_fragment(frag_poly: Array, button_bounds: Dictionary) -> Array[Button]:
	var overlapping_buttons : Array[Button]= []
	for button in button_bounds.keys():
		var rect = button_bounds[button]
		for p in frag_poly:
			var global_point = p + UI_Group.global_position
			if rect.has_point(global_point):
				overlapping_buttons.append(button)
				break
	return overlapping_buttons
	
func _set_display():
	if Globals.player1_input == "key":
		$RichTextLabel.bbcode_text = "[font=res://addons/input_prompt_icon_font/icon.ttf]keyboard_space[/font]: Enable/Disable Fracturing"
	else:
		$RichTextLabel.bbcode_text = "[font=res://addons/input_prompt_icon_font/icon.ttf]playstation_button_triangle_outline[/font]: Enable/Disable Fracturing"
	

func preload_all_textures():
	var buttons = []
	for button in $SubViewportContainer/SubViewport/UI_Group/VBoxContainer.get_children():
		if button is Button:
			buttons.append(button)
	var states = generate_all_valid_ui_states(buttons)
	for state in states:
		var fname = generate_filename(state)
		ui_textures[fname] = load("res://ui_captures/" + fname + ".png")

func generate_all_valid_ui_states(buttons: Array) -> Array:
	var states = []
	for p1_hover in [null] + buttons:
		for p1_press in [false, true]:
			if p1_press and p1_hover == null:
				continue
			for p2_hover in [null] + buttons:
				# Avoid duplicate hover (both players on same button)
				if p2_hover != null and p2_hover == p1_hover:
					continue
				for p2_press in [false, true]:
					if p2_press and p2_hover == null:
						continue
					var state = {
						"p1_hover": p1_hover,
						"p1_press": p1_press,
						"p2_hover": p2_hover,
						"p2_press": p2_press
					}
					states.append(state)
	return states
	
func update_ui_display():
	var state = normalize_ui_state({
		"p1_hover": UI.player1.hover_button,
		"p1_press": UI.player1.pressing,
		"p2_hover": UI.player2.hover_button,
		"p2_press": UI.player2.pressing
	})
	var fname = generate_filename(state)
	for frag in $BreakFX.get_children():
		frag.set_display_texture(ui_textures[fname])
	
func capture_all_ui_states():		
	var buttons = []
	for button in $SubViewportContainer/SubViewport/UI_Group/VBoxContainer.get_children():
		if button is Button:
			buttons.append(button)
	
	var valid_states = generate_all_valid_ui_states(buttons)
	for state in valid_states:
		var img = await capture_state(state)
		var filename = generate_filename(state)
		img.get_image().save_png("res://ui_captures/"+filename+".png")

func capture_state(state: Dictionary) -> ViewportTexture:
	# Update UI: apply hover/press for each player
	set_player_ui_state(state)
	
	await get_tree().process_frame

	var vp_tex = $SubViewportContainer/SubViewport.get_texture()
	return vp_tex
	
func generate_filename(state: Dictionary) -> String:
	var norm_state = normalize_ui_state(state)
	var p1_name =  norm_state["p1_hover"].name if norm_state["p1_hover"] != null else "none"
	var p2_name =  norm_state["p2_hover"].name if norm_state["p2_hover"] != null else "none"
	var p1_press =  "press" if norm_state["p1_press"] else "hover"
	var p2_press = "press" if norm_state["p2_press"] else "hover"
	return "p1_%s_%s_p2_%s_%s" % [p1_name, p1_press, p2_name, p2_press]

func set_player_ui_state(state: Dictionary) -> void:
	#Reset all buttons
	for button in $SubViewportContainer/SubViewport/UI_Group/VBoxContainer.get_children():
		if button is Button:
			button.button_pressed = false
			button.add_theme_stylebox_override("normal", button.get_theme_stylebox("focus"))

	# Set P1
	if state["p1_hover"] != null:
		var b = state["p1_hover"]
		b.add_theme_stylebox_override("normal", b.get_theme_stylebox("hover"))
		if state["p1_press"]:
			b.add_theme_stylebox_override("normal", b.get_theme_stylebox("pressed"))

	# Set P2
	if state["p2_hover"] != null:
		var b = state["p2_hover"]
		b.add_theme_stylebox_override("normal", b.get_theme_stylebox("hover"))
		if state["p2_press"]:
			b.add_theme_stylebox_override("normal", b.get_theme_stylebox("pressed"))

func inputs(input_device):
	if input_device=="key":
		return
	if Input.is_action_just_pressed("menu_left_"+input_device):
		if UI.player1.input == input_device:
			UI.player1.hover_button = get_next_button(UI.player1.hover_button, true)
		if UI.player2.input == input_device:
			UI.player2.hover_button = get_next_button(UI.player1.hover_button, true)
	if Input.is_action_just_pressed("menu_right_"+input_device):
		if UI.player1.input == input_device:
			UI.player1.hover_button = get_next_button(UI.player1.hover_button, false)
		if UI.player2.input == input_device:
			UI.player2.hover_button = get_next_button(UI.player1.hover_button, false)
	if Input.is_action_just_pressed("activate_"+input_device):
		if UI.player1.input == input_device:
			UI.player1.pressing = true
		if UI.player2.input == input_device:
			UI.player1.pressing = true
	if Input.is_action_just_released("activate_"+input_device):
		if UI.player1.input == input_device:
			UI.player1.hover_button.emit_signal("pressed")
		if UI.player2.input == input_device:
			UI.player2.hover_button.emit_signal("pressed")

func normalize_ui_state(state: Dictionary) -> Dictionary:
	var p1_hover = state["p1_hover"]
	var p2_hover = state["p2_hover"]
	var p1_press = state["p1_press"]
	var p2_press = state["p2_press"]
	#If both players hover different buttons, order them by button name
	if p1_hover != null and p2_hover != null:
		if p1_hover.name > p2_hover.name:
			# Swap players
			var tmp_hover = p1_hover
			var tmp_press = p1_press
			p1_hover = p2_hover
			p1_press = p2_press
			p2_hover = tmp_hover
			p2_press = tmp_press

	# Otherwise, leave state as-is
	return {
	"p1_hover": p1_hover,
	"p1_press": p1_press,
	"p2_hover": p2_hover,
	"p2_press": p2_press
	}


func get_next_button(current_button: Button, reverse_order : bool, container: VBoxContainer = $SubViewportContainer/SubViewport/UI_Group/VBoxContainer) -> Button:
	var children = container.get_children()

	#Reverse the list if needed
	if reverse_order:
		children.reverse()

	var found_current = false
	for child in children:
		if child is Button:
			if found_current:
				return child  #Next button found
			if child == current_button:
				found_current = true

	#Wrap around: return the first button in the (possibly reversed) list
	for child in children:
		if child is Button:
			return child
	return null  #No buttons found
