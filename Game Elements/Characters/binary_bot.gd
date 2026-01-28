extends Node2D

# ============================================================
# CONFIGURATION
# ============================================================

# Physics parameters
@export var spring_strength := 1000.0      # pulls each glyph toward the core center
@export var damping := 10.0               # slows velocity
@export var repulsion_force := 2000.0    # prevents collapsing
@export var repulsion_radius := 18.0     # min distance between characters
var particles = []   # Each entry: { label, pos, vel }

@export var mono_font: Font
var last_position : Vector2
# Characters 
@export var core_char_count := 36
@export var segment_char_count := 4   # chars per leg segment
@export var glyph_choices := "@#%*&+=~/?<>"

# Visual jitter
@export var jitter_strength := 3.0

# Legs
const LEG_COUNT := 6
var leg_lengths := { "upper": 35.0, "lower": 30.0 }

# Internal
var last_mode : String = " NONE"
var attack_cooldown := 0.0
var legs = []          # runtime legs array

func _ready():
	last_position = global_position
	_spawn_core_characters()
	_spawn_legs()


# CHARACTER SPAWNING
func _random_glyph() -> String:
	return glyph_choices[randi() % glyph_choices.length()]

func get_lum_variation() -> float:
	var variation = .5
	return randf_range(-variation, variation)

func change_color(label_to_change : Label, time_step : float, og_color : Color, new_color : Color, lum : float):
	var time = clamp(time_step,0.0,1.0)
	# Convert to HSV
	var h = og_color.h
	var s = og_color.s
	var v = clamp(og_color.v + lum, 0.0, 1.0)
	var base_color = Color.from_hsv(h, s, v, og_color.a)
	h = new_color.h
	s = new_color.s
	v = clamp(new_color.v + lum, 0.0, 1.0)
	var roof_color = Color.from_hsv(h, s, v, new_color.a)
	var time_color = lerp(base_color,roof_color,time)
	label_to_change.add_theme_color_override("font_color", time_color)
	

func _make_char_label(lum_offset : float) -> Label:
	var base_color = Color(1.0, 0.0, 0.0, 1.0)
	# Convert to HSV
	var h = base_color.h
	var s = base_color.s
	var v = clamp(base_color.v + lum_offset, 0.0, 1.0)

	var text_color = Color.from_hsv(h, s, v, base_color.a)
	
	var lbl := Label.new()
	lbl.text = _random_glyph()
	lbl.position = Vector2.ZERO

	# ---- APPLY GREEN CODING STYLE ----
	lbl.add_theme_color_override("font_color", text_color)
	lbl.add_theme_constant_override("outline_size", 2)
	lbl.add_theme_font_override("font", mono_font)
	lbl.add_theme_font_size_override("font_size", 64)
	lbl.scale = Vector2(0.125, 0.125)
	return lbl

func _spawn_core_characters():
	var spawn_distance = 4
	for i in range(core_char_count):
		var lum = get_lum_variation()
		var ch = _make_char_label(lum)
		add_child(ch)
		ch.position = Vector2(randf_range(-spawn_distance,spawn_distance),randf_range(-spawn_distance,spawn_distance))

		particles.append({
			"label": ch,
			"pos": ch.position,
			"vel": Vector2.ZERO,
			"lum": lum
		})

func _spawn_legs():
	var legs_root := Node2D.new()
	legs_root.name = "Legs"
	get_parent().add_child.call_deferred(legs_root)

	for i in range(LEG_COUNT):
		var leg_angle = deg_to_rad((360.0 / LEG_COUNT) * i)

		var leg_root := Node2D.new()
		leg_root.name = "leg_%d" % (i+1)
		legs_root.add_child(leg_root)

		# Upper, lower, foot segments
		var upper_seg := Node2D.new()
		var lower_seg := Node2D.new()
		var foot_seg  := Node2D.new()

		upper_seg.name = "upper"
		lower_seg.name = "lower"
		foot_seg.name  = "foot"

		leg_root.add_child(upper_seg)
		leg_root.add_child(lower_seg)
		leg_root.add_child(foot_seg)

		# spawn characters inside each segment
		var upper_chars = []
		var lower_chars = []
		var foot_chars = []
		var upper_chars_lum = []
		var lower_chars_lum = []
		var foot_chars_lum = []

		for n in range(segment_char_count):
			
			var lum = get_lum_variation()
			var u = _make_char_label(lum)
			upper_seg.add_child(u)
			upper_chars.append(u)
			upper_chars_lum.append(lum)
			lum = get_lum_variation()
			var l = _make_char_label(lum)
			lower_seg.add_child(l) 
			lower_chars.append(l)
			lower_chars_lum.append(lum)
			lum = get_lum_variation()
			var f = _make_char_label(lum)
			foot_seg.add_child(f)
			foot_chars.append(f)
			foot_chars_lum.append(lum)

		# store leg data
		legs.append({
			"root": leg_root,
			"upper": upper_seg,
			"lower": lower_seg,
			"foot": foot_seg,
			"upper_chars": upper_chars,
			"lower_chars": lower_chars,
			"foot_chars": foot_chars,
			"upper_chars_var": upper_chars_lum,
			"lower_chars_var": lower_chars_lum,
			"foot_chars_var": foot_chars_lum,
			"angle": leg_angle,
			"step_timer": randf_range(0.0, 1.0),
			"foot_target": Vector2.ZERO,
		})

# PROCESS LOOP
func _process(delta):
	var bt_player = get_parent().get_node("BTPlayer")
	var board = bt_player.blackboard
	if board:
		var attack_mode = board.get_var("attack_mode")
		if last_mode != attack_mode:
			if attack_mode == "MELEE":
				get_parent().get_node("Legs").visible = false
			if attack_mode == "RANGED":
				get_parent().get_node("Legs").visible = true
			last_mode = attack_mode
		var attack_status = board.get_var("attack_status")
		if attack_status == " STARTING" and attack_mode == " MELEE":
			board.set_var("attack_status"," RUNNING")
			_do_melee_attack()
		
		
	attack_cooldown = max(0.0, attack_cooldown - delta)

	_update_physics(delta)
	_process_leg_ik(delta)

func _get_player_position() -> Vector2:
	var players = get_tree().get_nodes_in_group("player")
	var positions_array = []
	for player in players: 
		positions_array.append(player.global_position)

	var board = get_parent().get_node("BTPlayer").blackboard
	return positions_array[board.get_var("player_idx")]

func _do_melee_attack():
	var player_position = _get_player_position()
	attack_cooldown = 1.2
	print("Shrink")
	var tween := create_tween()
	tween.tween_property(self, "repulsion_force", repulsion_force/4.0, 1.0)
	await tween.finished
	# --- Calculate movement ---
	var movement_vector = player_position - global_position
	var target_vector = movement_vector * 1.4  # 40% overshoot
	
	var debug = load("res://Game Elements/General Game/debug_scene.tscn").instantiate()
	get_parent().get_parent().add_child(debug)
	debug.global_position = player_position
	#
	#print("Lunge forward")
	#
#
	#var duration := .25  # seconds
	#var elapsed := 0.0
#
	#while elapsed < duration:
		#var delta := get_process_delta_time()
		#elapsed += delta
#
		## Compute fraction of the total distance to move this frame
		#var t := delta / duration
#
		#get_parent().apply_velocity(target_vector * t)
		#print("Move")
#
		#await get_tree().process_frame  # wait for next frame
#
	#
	print("Expand")
	var tween_expand := create_tween()
	tween_expand.tween_property(self, "repulsion_force", repulsion_force*4.0, 2.0)
	await get_tree().create_timer(2.0).timeout
	var board = get_parent().get_node("BTPlayer").blackboard
	board.set_var("attack_status"," DONE")


func _update_physics(delta):
	var pos_difference = last_position - global_position
	last_position = global_position
	var center = Vector2.ZERO   # relative to parent

	# --- First, compute forces for each particle ---
	for i in range(particles.size()):
		var p = particles[i]
		var pos = p.pos + pos_difference
		var vel = p.vel

		# 1) Spring toward center
		var to_center = (center - pos)
		var force = to_center * spring_strength

		# 2) Repulsion from other particles
		for j in range(particles.size()):
			if i == j:
				continue
			var other = particles[j]
			var offset = pos - other.pos
			var dist = offset.length()
			if dist > 0 and dist < repulsion_radius:
				var push = (repulsion_radius - dist) / repulsion_radius
				force += offset.normalized() * repulsion_force * push

		# 3) Damping
		force -= vel * damping

		# 4) Integrate motion
		vel += force * delta
		pos += vel * delta

		# Store updated
		p.pos = pos
		p.vel = vel

	# --- Update visual label positions ---
	for p in particles:
		p["label"].position = p.pos

# LEG IK + MOTION + JITTER
func _process_leg_ik(delta):
	for L in legs:
		var angle = L["angle"]

		# leg root circles around the core
		var root_pos = Vector2(cos(angle), sin(angle)) * 40
		L["root"].position = L["root"].position.lerp(root_pos, delta * 10)

		# step logic
		L["step_timer"] -= delta
		if L["step_timer"] <= 0:
			L["step_timer"] = randf_range(0.4, 0.7)
			L["foot_target"] = root_pos + Vector2(cos(angle), sin(angle)) * 60 + Vector2(randf()*20-10, randf()*20-10)

		# move foot
		var foot_pos = L["foot"].position.lerp(L["foot_target"], delta * 8)
		L["foot"].position = foot_pos

		# IK: compute lower joint
		var lower_dir = (L["root"].position - foot_pos).normalized()
		L["lower"].position = foot_pos + lower_dir * leg_lengths["lower"]

		# IK: compute upper joint
		var upper_dir = (L["root"].position - L["lower"].position).normalized()
		L["upper"].position = L["lower"].position + upper_dir * leg_lengths["upper"]

		# jitter characters
		_jitter_segment(L["upper_chars"], delta)
		_jitter_segment(L["lower_chars"], delta)
		_jitter_segment(L["foot_chars"], delta)

func _jitter_segment(chars, delta):
	for c in chars:
		var jitter = Vector2(
			randf_range(-jitter_strength, jitter_strength),
			randf_range(-jitter_strength, jitter_strength)
		)
		c.position = c.position.lerp(jitter, delta * 12)
