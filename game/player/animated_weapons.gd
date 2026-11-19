extends Node3D
signal strike(action: StringName)
@export_group("Framing")
@export var view_offset := Vector3(0, -0.04, 0.32)
@export_group("Impact timing")
## Seconds into each slash at which damage lands.
@export var slash_impact_times := PackedFloat32Array([0.20, 0.20, 0.20])
@export_range(0.0, 1.0, 0.01) var bash_impact_time := 0.33


@export var sword_slashes: Array[StringName] = [&"Sword_Slash_1", &"Sword_Slash_2", &"Sword_Slash_3"]
@export var sword_parry: StringName = &"Sword_Parry"
@export var sword_return: StringName = &"Sword_toIdle"
@export var shield_use: StringName = &"Shield_Use"
@export var shield_bash: StringName = &"Shield_Bash"
@export var shield_parry: StringName = &"Shield_Parry"
var players: Array[AnimationPlayer] = []
var next_slash := 0

func _ready():
	var rig = $Rig
	var camera: Camera3D = rig.get_node("Camera")
	rig.transform = camera.transform.affine_inverse()
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
		material.shader = preload("res://game/rendering/shaders/ink.gdshader")
		if original is BaseMaterial3D and original.albedo_texture:
			material.set_shader_parameter("atlas", original.albedo_texture)
		var outline := ShaderMaterial.new()
		outline.shader = preload("res://game/rendering/shaders/contour.gdshader")
		material.next_pass = outline
		mesh.material_override = material
	reset_playback()

func emit_strike(action: StringName):
	strike.emit(action)

func finish_action(clip: StringName, side: int):
	if side == 0 and clip != sword_return:
		play_clip(0, sword_return)
	elif side == 1:
		play_clip(1, shield_use)
		players[1].seek(0, true)
		players[1].pause()

func play_clip(side: int, clip: StringName):
	if players[side].has_animation(clip):
		players[side].play(clip, 0.04)

func cue(action: StringName, has_left: bool):
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

func reset_playback():
	next_slash = 0
	for side in 2:
		play_clip(side, sword_return if side==0 else shield_use)
		players[side].seek(0, true)
		players[side].pause()

func animate(run, _dt):
	$Rig/Sword_armature.visible = "Sword" in run.slots or "Parry" in run.slots
	$Rig/Shield_armature.visible = run.arm and ("Shield" in run.slots or "Shield Bash" in run.slots)
