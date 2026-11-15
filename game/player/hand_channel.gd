@tool
extends AnimationPlayer

## Animation tracks are restricted to this arm and its fingers. The two players can
## play different clips, including different halves of the same imported take.
@export_group("Rig")
@export var shoulder_bone: StringName = &"Bone.004.L"
@export var palm_bone: StringName = &"Bone.008.L"
## Detached control bones belonging to this side of the imported rig.
@export var control_roots: Array[StringName] = []
@export_group("Locomotion")
@export var idle: StringName = &"Unassigned"
@export var walk: StringName = &"Unassigned"
@export_group("Actions")
@export var sword: StringName = &"Unassigned"
@export var shield: StringName = &"Unassigned"
@export var parry: StringName = &"Unassigned"
@export var shield_bash: StringName = &"Unassigned"
@export var fireball: StringName = &"Unassigned"
@export var mend: StringName = &"Unassigned"
@export_group("Reactions")
@export var hurt: StringName = &"Unassigned"
@export var blocked: StringName = &"Unassigned"
@export var guard_broken: StringName = &"Unassigned"
@export var parry_success: StringName = &"Unassigned"
@export var death: StringName = &"Unassigned"

const SLOTS = ["idle","walk","sword","shield","parry","shield_bash","fireball","mend","hurt","blocked","guard_broken","parry_success","death"]
const NONE = &"Unassigned"
var rig: Skeleton3D
var shoulder_index: int
var bones: Array[int] = []
var rest_poses: Dictionary = {}
var shoulder_offset: Vector3
var clips := AnimationLibrary.new()
var prepared_names := {}
var unavailable := {}
var active_slot: StringName = &""
var one_shot := false

func sources() -> Array:
	return [get_node_or_null("../ClipLibrary"),get_node_or_null("../Rig/AnimationPlayer")]

func _validate_property(property: Dictionary):
	if property.name not in SLOTS: return
	var choices := PackedStringArray([NONE])
	for source in sources():
		if source:
			for clip in source.get_animation_list():
				if clip!="RESET" and clip not in choices: choices.append(clip)
	property.hint=PROPERTY_HINT_ENUM
	property.hint_string=",".join(choices)

func setup(skeleton: Skeleton3D, alignment: Vector3):
	rig=skeleton
	shoulder_offset=alignment
	shoulder_index=rig.find_bone(shoulder_bone)
	# Bones in this FBX have mixed L/R suffixes. Follow actual parent chains.
	for index in rig.get_bone_count():
		var root_index=index
		while rig.get_bone_parent(root_index)>=0:
			root_index=rig.get_bone_parent(root_index)
		if root_index==shoulder_index or rig.get_bone_name(root_index) in control_roots:
			bones.append(index)
			rest_poses[index]=rig.get_bone_pose(index)
	callback_mode_process=AnimationMixer.ANIMATION_CALLBACK_MODE_PROCESS_MANUAL
	add_animation_library(&"",clips)

func restore():
	stop()
	for index in bones: rig.set_bone_pose(index,rest_poses[index])
	active_slot=&""
	one_shot=false

func prepare(slot: StringName, looping: bool) -> bool:
	var selected: StringName=get(slot)
	if selected==NONE or selected==&"": return false
	if prepared_names.get(slot)==selected: return true
	if unavailable.get(slot)==selected: return false
	if clips.has_animation(slot):
		clips.remove_animation(slot)
		prepared_names.erase(slot)
	for source in sources():
		if not source or not source.has_animation(selected): continue
		var clip:Animation=source.get_animation(selected).duplicate()
		var source_root:Node=source.get_node(source.root_node)
		for track in range(clip.get_track_count()-1,-1,-1):
			var path=clip.track_get_path(track)
			var bone_index=-1
			if path.get_subname_count()==1 and source_root.get_node_or_null(NodePath(path.get_concatenated_names()))==rig:
				bone_index=rig.find_bone(path.get_subname(0))
			if bone_index not in bones or clip.track_get_type(track) not in [Animation.TYPE_POSITION_3D,Animation.TYPE_ROTATION_3D,Animation.TYPE_SCALE_3D]:
				clip.remove_track(track)
				continue
			clip.track_set_path(track,NodePath(str(get_node(root_node).get_path_to(rig))+":"+str(rig.get_bone_name(bone_index))))
			if source==get_node("../Rig/AnimationPlayer") and bone_index==shoulder_index and clip.track_get_type(track)==Animation.TYPE_POSITION_3D:
				for key in clip.track_get_key_count(track):
					clip.track_set_key_value(track,key,clip.track_get_key_value(track,key)+shoulder_offset)
		if clip.get_track_count()==0:
			unavailable[slot]=selected
			push_warning("%s: %s has no bone tracks for %s" % [name,selected,shoulder_bone])
			return false
		clip.loop_mode=Animation.LOOP_LINEAR if looping else Animation.LOOP_NONE
		clips.add_animation(slot,clip)
		prepared_names[slot]=selected
		unavailable.erase(slot)
		return true
	unavailable[slot]=selected
	push_warning("%s: assigned clip '%s' is missing from the source libraries" % [name,selected])
	return false

func begin(slot: StringName, looping: bool) -> bool:
	if not prepare(slot,looping): return false
	restore()
	play(slot)
	advance(0.)
	active_slot=slot
	one_shot=not looping
	return true

func update_hand(dt:float, moving:bool, procedural_action:bool) -> bool:
	if one_shot:
		advance(dt)
		if is_playing() or active_slot==&"death": return true
		restore()
	if procedural_action:
		if active_slot!=&"": restore()
		return false
	var target=&"walk" if moving and walk!=NONE else &"idle"
	if active_slot!=target:
		if not begin(target,true):
			if active_slot!=&"": restore()
			return false
	advance(dt)
	return true
