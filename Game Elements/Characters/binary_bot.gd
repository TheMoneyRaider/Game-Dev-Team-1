extends Node2D

# ============================================================
# CONFIGURATION
# ============================================================
var GlyphLabel = preload("res://Game Elements/Objects/binary_character.tscn")
# Physics parameters
@export var spring_strength := 1000.0      # pulls each glyph toward the core center
@export var damping := 10.0               # slows velocity
@export var repulsion_force := 2000.0    # prevents collapsing
@export var repulsion_radius := 18.0     # min distance between characters
var particles = []   # Each entry: { label, pos, vel }
var attack_direct = 1
@export var mono_font: Font
var last_position : Vector2
# Characters 
@export var core_char_count := 36
@export var segment_char_count := 4   # chars per leg segment
@export var glyph_choices := "10"

# Visual jitter
@export var jitter_strength := 3.0
var tracked_player : Node = null
var tracked_wave : Node = null

# Legs
const LEG_COUNT := 6
var leg_lengths := { "upper": 35.0, "lower": 30.0 }

# Internal
var last_mode : String = " NONE"
var attack_cooldown := 0.0
var legs = []          # runtime legs array

func _ready():
	get_parent().get_node("Attack").c_owner = get_parent()
	get_parent().get_node("Attack/CollisionShape2D").disabled=true
	last_position = global_position
	_spawn_legs()
	var instance = load("res://Game Elements/Rooms/sci_fi/binary_string.tscn").instantiate()
	instance.position = Vector2(-640, 0)
	instance.min_length = core_char_count
	instance.max_length = core_char_count
	add_child(instance)
	tracked_wave = instance
	tracked_wave.z_index += 20 


# CHARACTER SPAWNING
func _random_glyph() -> String:
	return glyph_choices[randi() % glyph_choices.length()]


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
	

func _make_char_label(parent : Node) -> Label:
	var lbl: Label = GlyphLabel.instantiate()
	var glyph = _random_glyph()
	lbl.set_character_data(glyph)
	parent.add_child(lbl)
	lbl.position = Vector2(0,0)
	return lbl

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

		for n in range(segment_char_count):
			
			var u = _make_char_label(upper_seg)
			upper_chars.append(u)
			var l = _make_char_label(lower_seg)
			lower_chars.append(l)
			var f = _make_char_label(foot_seg)
			foot_chars.append(f)

		# store leg data
		legs.append({
			"root": leg_root,
			"upper": upper_seg,
			"lower": lower_seg,
			"foot": foot_seg,
			"upper_chars": upper_chars,
			"lower_chars": lower_chars,
			"foot_chars": foot_chars,
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
		if attack_mode == "SPAWNING":
			if !tracked_wave:
				board.set_var("attack_mode","MELEE")
			else:
				var labels = tracked_wave.glyphs
				for lbl in labels:
					if lbl.global_position.distance_to(global_position) < 12 or lbl.global_position.x > global_position.x:
						var temp_position = lbl.global_position + Vector2(0,randf_range(-5,5))
						lbl.get_parent().glyphs.erase(lbl)
						lbl.get_parent().remove_child(lbl)
						add_child(lbl)
						lbl.global_position = temp_position
						particles.append({
							"label": lbl,
							"pos": lbl.position,
							"vel": Vector2.ZERO
						})
					
		if last_mode != attack_mode:
			get_parent().get_node("Legs").visible = false
			if attack_mode == "RANGED":
				get_parent().get_node("Legs").visible = true
			last_mode = attack_mode
		var attack_status = board.get_var("attack_status")
		if attack_status == " STARTING" and attack_mode == "MELEE":
			board.set_var("attack_status"," RUNNING")
			_do_melee_attack()
		
		
	attack_cooldown = max(0.0, attack_cooldown - delta)

	_update_physics(delta)
	_process_leg_ik(delta)

func _return_glyph_locations() -> Array[Vector2]:
	var locations: Array[Vector2] = []
	for p in particles:
		var label: Label = p["label"]
		if is_instance_valid(label):
			locations.append(label.global_position)
	for L in legs:
		for c in L["upper_chars"]:
			if is_instance_valid(c):
				locations.append(c.global_position)

		for c in L["lower_chars"]:
			if is_instance_valid(c):
				locations.append(c.global_position)

		for c in L["foot_chars"]:
			if is_instance_valid(c):
				locations.append(c.global_position)

	return locations
	
func _change_glyph_colors(color : Color, time : float, delay : float):
	for p in particles:
		var label: Label = p["label"]
		if is_instance_valid(label):
			label._change_color(color, time, delay)
	for L in legs:
		for c in L["upper_chars"]:
			if is_instance_valid(c):
				c._change_color(color, time, delay)

		for c in L["lower_chars"]:
			if is_instance_valid(c):
				c._change_color(color, time, delay)

		for c in L["foot_chars"]:
			if is_instance_valid(c):
				c._change_color(color, time, delay)
	


func _deflect_melee_attack():
	print("deflect")
	attack_direct = -1

func _get_player_position() -> Vector2:
	var players = get_tree().get_nodes_in_group("player")
	var positions_array = []
	for player in players: 
		positions_array.append(player.global_position)

	var board = get_parent().get_node("BTPlayer").blackboard
	
	tracked_player =players[board.get_var("player_idx")]
	return positions_array[board.get_var("player_idx")]

func _do_melee_attack():
	var tracked_player_pos := _get_player_position()
	attack_direct = 1
	attack_cooldown = 1.2
	print("Shrink")
	var tween := create_tween()
	tween.tween_property(self, "repulsion_force", repulsion_force/8.0, .5)
	_change_glyph_colors(Color(0.487, 0.496, 0.157, 1.0),.5,0.0)
	var track_strength := 6.0  # higher = more accurate, lower = more dodgeable
	while tween.is_running():
		var delta := get_process_delta_time()
		var real_player_pos : Vector2 = tracked_player.global_position
		# Exponential smoothing (frame-rate independent)
		tracked_player_pos = tracked_player_pos.lerp(
			real_player_pos,
			1.0 - exp(-track_strength * delta)
		)
		#var debug = load("res://Game Elements/General Game/debug_scene.tscn").instantiate()
		#get_parent().get_parent().add_child(debug)
		#debug.global_position = tracked_player_pos
		await get_tree().process_frame
	get_parent().get_node("Attack/CollisionShape2D").disabled=false
	# --- Calculate movement ---
	var movement_vector = tracked_player_pos - global_position
	if movement_vector.length() < 348:
		movement_vector = movement_vector.normalized()*48
	var target_vector = movement_vector * 1.5  # 50% overshoot
	print("Lunge forward")
	
	_change_glyph_colors(Color(0.743, 0.247, 0.148, 1.0),.125,0.0)
	var duration := .25  # seconds
	var elapsed := 0.0
	var lunge_velocity := Vector2.ZERO
	while elapsed < duration:
		var delta := get_process_delta_time()
		elapsed += delta

		var t := delta / duration
		lunge_velocity = target_vector * t * 60 * attack_direct
		get_parent().apply_velocity(lunge_velocity)

		await get_tree().process_frame  # wait for next frame

	var friction := 10.0

	while lunge_velocity.length() > 5.0:
		var delta := get_process_delta_time()
		lunge_velocity = lunge_velocity.move_toward(Vector2.ZERO, friction * delta * 100)

		get_parent().apply_velocity(lunge_velocity)
		await get_tree().process_frame
	get_parent().get_node("Attack/CollisionShape2D").disabled=true
	var board = get_parent().get_node("BTPlayer").blackboard
	print("Expand")
	board.set_var("attack_status"," FINISHING")
	var tween_expand := create_tween()
	tween_expand.tween_property(self, "repulsion_force", repulsion_force*8.0, 1.0)
	_change_glyph_colors(Color(0.0, 0.373, 0.067, 1.0),2.0,0.0)
	await get_tree().create_timer(2.0).timeout
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
