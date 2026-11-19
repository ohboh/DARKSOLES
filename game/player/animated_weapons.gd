extends Node3D
signal strike(action: StringName)
@export_group("Framing")
@export var view_offset := Vector3(0, 0.18, 0)
@export_group("Walking")
@export var walk_bob := Vector2(0.009, 0.012)
@export_range(0.0, 5.0, 0.1) var walk_roll_degrees := 0.7
@export_range(0.1, 4.0, 0.1) var steps_per_tile := 1.6
var previous_distance := 0.0
var walk_strength := 0.0
@export_range(0.0, 6.28, 0.05) var shield_phase_offset := 1.9
@export_range(0.0, 2.0, 0.05) var shield_sway_scale := 0.65
var weapon_roots: Array[Node3D] = []
var rest_transforms: Array[Transform3D] = []
var camera_to_rig := Basis.IDENTITY
var current_shield_depth := -1.0
var shield_material: ShaderMaterial
var shield_outline: ShaderMaterial
@export_group("Impact timing")
## Seconds into each slash at which damage lands.
@export var slash_impact_times := PackedFloat32Array([0.20, 0.20, 0.20])
@export_range(0.0, 1.0, 0.01) var bash_impact_time := 0.33


@export var sword_slashes: Array[StringName] = [&"Sword_Slash_1", &"Sword_Slash_2", &"Sword_Slash_3"]
@export var sword_parry: StringName = &"Sword_Parry"
@export var sword_return: StringName = &"Sword_toIdle"
@export var shield_return: StringName = &"Shield_toIdle"
@export var shield_use: StringName = &"Shield_Use"
@export var shield_bash: StringName = &"Shield_Bash"
@export var shield_parry: StringName = &"Shield_Parry"
var players: Array[AnimationPlayer] = []
var next_slash := 0
var intro_stage := 0
@export var sword_draw: StringName = &"Sword_Draw"

func _ready():
	var rig = $Rig
	var camera: Camera3D = rig.get_node("Camera")
	rig.transform = camera.transform.affine_inverse()
	var gameplay_camera := get_viewport().get_camera_3d()
	if gameplay_camera:
		var factor := tan(deg_to_rad(gameplay_camera.fov)*0.5) / tan(deg_to_rad(camera.fov)*0.5)
		rig.transform = Transform3D(Basis.from_scale(Vector3(factor, factor, 1)), Vector3.ZERO) * rig.transform
	rig.position += view_offset
	camera.current = false
	camera.queue_free()
	var source: AnimationPlayer = rig.get_node("AnimationPlayer")
	source.active = false
	for side in ["Sword", "Shield"]:
		var player := AnimationPlayer.new()
		player.name = side + "Animations"
		rig.add_child(player)
		player.root_node = NodePath("..")
		var library := AnimationLibrary.new()
		for clip in source.get_animation_list():
			if not clip.begins_with(side): continue
			var animation: Animation = source.get_animation(clip).duplicate()
			for track in range(animation.get_track_count()-1, -1, -1):
				if not str(animation.track_get_path(track)).begins_with(side+"_armature/"):
					animation.remove_track(track)
			var slash_index := sword_slashes.find(clip)
			if slash_index >= 0 or clip == shield_bash:
				var impact := bash_impact_time
				var action: StringName = &"shield_bash"
				if slash_index >= 0:
					impact = slash_impact_times[mini(slash_index, slash_impact_times.size()-1)] if not slash_impact_times.is_empty() else animation.length * 0.5
					action = &"sword"
				var track := animation.add_track(Animation.TYPE_METHOD)
				animation.track_set_path(track, NodePath(".."))
				animation.track_insert_key(track, clampf(impact, 0.0, animation.length), {"method": &"emit_strike", "args": [action]})
			library.add_animation(clip, animation)
		player.add_animation_library("", library)
		players.append(player)
		player.animation_finished.connect(finish_action.bind(players.size()-1))
	for mesh in rig.find_children("*", "MeshInstance3D"):
		var original = mesh.get_active_material(0)
		var material := ShaderMaterial.new()
		material.shader = preload("res://game/rendering/shaders/weapon.gdshader")
		if original is BaseMaterial3D and original.albedo_texture:
			material.set_shader_parameter("atlas", original.albedo_texture)
		if original is BaseMaterial3D:
			material.set_shader_parameter("pigment", original.albedo_color)
		var outline := ShaderMaterial.new()
		outline.shader = preload("res://game/rendering/shaders/contour.gdshader")
		# Compress shield depth while preserving its projected position and size.
		if mesh.name == "Shield":
			shield_material = material
			shield_outline = outline
			set_shield_depth(0.25)
		material.next_pass = outline
		mesh.material_override = material
	camera_to_rig = rig.basis.inverse()
	for side in ["Sword", "Shield"]:
		var root: Node3D = rig.get_node(side + "_armature")
		weapon_roots.append(root)
		rest_transforms.append(root.transform)
	reset_playback()

func emit_strike(action: StringName):
	strike.emit(action)

func hold_idle(side: int):
	var clip: StringName = &"Sword_Idle" if side == 0 else &"Shield_Idle"
	# Apply the idle immediately before pausing, without retaining the previous blend.
	players[side].play(clip, 0.0)
	players[side].seek(0, true)
	players[side].pause()

func start_run():
	reset_playback()
	intro_stage = 1
	players[1].play(shield_return, 0.0)
	players[1].seek(0, true)
	players[1].pause()
	players[0].play(sword_draw, 0.0)
	players[0].advance(0)

func finish_action(clip: StringName, side: int):
	if intro_stage > 0:
		if intro_stage == 1 and side == 0 and clip == sword_draw:
			intro_stage = 2
			play_clip(0, sword_return)
		elif intro_stage == 2 and side == 0 and clip == sword_return:
			hold_idle(0)
			intro_stage = 3
			play_clip(1, shield_return)
		elif intro_stage == 3 and side == 1 and clip == shield_return:
			hold_idle(1)
			intro_stage = 0
		return
	var return_clip := sword_return if side == 0 else shield_return
	if clip != return_clip and players[side].has_animation(return_clip):
		play_clip(side, return_clip)
	else:
		hold_idle(side)

func play_clip(side: int, clip: StringName):
	if players[side].has_animation(clip):
		players[side].play(clip, 0.04)

func cue(action: StringName, has_left: bool):
	if intro_stage > 0: return
	match action:
		&"sword":
			if not sword_slashes.is_empty():
				play_clip(0, sword_slashes[next_slash % sword_slashes.size()])
				next_slash += 1
		&"parry":
			play_clip(0, sword_parry)
		&"shield":
			if has_left: play_clip(1, shield_use)
		&"shield_bash":
			if has_left: play_clip(1, shield_bash)
		&"blocked":
			if has_left: play_clip(1, shield_parry)

func set_shield_depth(depth: float):
	if depth == current_shield_depth: return
	current_shield_depth = depth
	shield_material.set_shader_parameter("view_depth_scale", depth)
	shield_outline.set_shader_parameter("view_depth_scale", depth)

func reset_playback():
	intro_stage = 0
	next_slash = 0
	previous_distance = 0.0
	walk_strength = 0.0
	for side in weapon_roots.size():
		weapon_roots[side].transform = rest_transforms[side]
	for side in 2:
		hold_idle(side)

func animate(run, dt):
	var moving: bool = intro_stage == 0 and run.state == "run" and run.fight < 0 and run.p > previous_distance
	previous_distance = run.p
	walk_strength = move_toward(walk_strength, 1.0 if moving else 0.0, dt * 7.0)
	var phase: float = run.p * TAU * steps_per_tile
	for side in 2:
		var hand_phase := phase + (shield_phase_offset if side == 1 else 0.0)
		var strength := walk_strength * (shield_sway_scale if side == 1 else 1.0)
		var lateral := sin(hand_phase * 0.5)
		var offset := Vector3(lateral * walk_bob.x, sin(hand_phase) * walk_bob.y, 0) * strength
		var pose := rest_transforms[side]
		pose.origin += camera_to_rig * offset
		var roll := Basis(Vector3.BACK, lateral * deg_to_rad(walk_roll_degrees) * strength)
		pose.basis = camera_to_rig * roll * $Rig.basis * pose.basis
		weapon_roots[side].transform = pose
	var parrying: bool = players[0].is_playing() and players[0].current_animation == sword_parry
	set_shield_depth(1.0 if parrying else 0.25)
	weapon_roots[0].visible = "Sword" in run.slots or "Parry" in run.slots
	weapon_roots[1].visible = run.arm and ("Shield" in run.slots or "Shield Bash" in run.slots)

