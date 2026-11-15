extends Node3D

@export_group("Procedural fallback")
@export var right_grip_position := Vector3(.151,-.225,-.63)
@export var left_grip_position := Vector3(-.16,-.225,-.60)

@onready var skeleton: Skeleton3D = $Rig/Armature/Skeleton3D
@onready var channels = [$LeftHand,$RightHand]
@onready var left_socket: BoneAttachment3D = skeleton.get_node("LeftGrip")
@onready var right_socket: BoneAttachment3D = skeleton.get_node("RightGrip")
@onready var blade: Node3D = right_socket.get_node("Sword")
@onready var shield: Node3D = left_socket.get_node("Shield")
@onready var left_book: Node3D = left_socket.get_node("Tome")
@onready var right_book: Node3D = right_socket.get_node("Tome")
@onready var sword_grip := blade.transform
var shoulders: Array[int] = []
var shoulder_poses: Array[Vector3] = []
var palms: Array[Vector3] = []
var guard_lift := 0.
var previous_distance := 0.
var left_available := true

func _ready():
	# Imported and locally authored libraries remain available for editor preview.
	$ClipLibrary.active=false
	$Rig/AnimationPlayer.active=false
	for side in 2:
		var channel=channels[side]
		var shoulder=skeleton.find_bone(channel.shoulder_bone)
		var palm=skeleton.find_bone(channel.palm_bone)
		shoulders.append(shoulder)
		shoulder_poses.append(skeleton.get_bone_pose_position(shoulder))
		palms.append(skeleton.get_bone_global_pose(palm).origin)
		place_palm(side,left_grip_position if side==0 else right_grip_position)
		var alignment=skeleton.get_bone_pose_position(shoulder)-skeleton.get_bone_rest(shoulder).origin
		channel.setup(skeleton,alignment)

func cue(slot:StringName, has_left:bool):
	for side in 2:
		if side==1 or has_left: channels[side].begin(slot,false)

func reset_playback():
	for channel in channels: channel.restore()
	previous_distance=0.
	left_available=true
	guard_lift=0.

func place_palm(side:int,target:Vector3):
	var local_target=skeleton.to_local(to_global(target))
	skeleton.set_bone_pose_position(shoulders[side],shoulder_poses[side]+local_target-palms[side])

func animate(run,dt):
	var moving=run.state in ["run","turn"] and (run.p>previous_distance or run.state=="turn")
	previous_distance=run.p
	if not run.arm and left_available: channels[0].restore()
	left_available=run.arm
	var guarding=run.guard>0 or run.bash>0
	var left_animated=run.arm and channels[0].update_hand(dt,moving,guarding)
	var right_animated=channels[1].update_hand(dt,moving,run.slash>0 or run.parry>0)

	blade.visible="Sword" in run.slots or "Parry" in run.slots
	shield.visible=run.arm and ("Shield" in run.slots or "Shield Bash" in run.slots)
	var has_book="Fireball" in run.slots and (not shield.visible or not blade.visible)
	left_book.visible=has_book and blade.visible and run.arm
	right_book.visible=has_book and not left_book.visible

	guard_lift=lerpf(guard_lift,1. if guarding else 0.,minf(1.,dt*14.))
	var breathing=Vector3.UP*(.004*sin(run.time*2.1)+.004*sin(run.p*TAU))
	if not left_animated:
		var guard_offset=Vector3(.048,.12,0)*guard_lift+Vector3.FORWARD*run.bash*.24
		place_palm(0,left_grip_position+guard_offset+breathing if run.arm else Vector3(-3,-3,1))
	blade.transform=sword_grip
	if not right_animated:
		var swing=sin(PI*run.slash/.18)
		place_palm(1,right_grip_position+Vector3(-.12,.07,-.07)*swing+breathing)
		# Only the fallback rotates the sword in camera space. Authored clips use the grip socket.
		var bind_basis=(global_transform.affine_inverse()*skeleton.global_transform*skeleton.get_bone_global_pose(right_socket.bone_idx)).basis
		blade.basis=bind_basis.inverse()*Basis(Vector3.BACK,swing*1.6+run.parry*3)*bind_basis*sword_grip.basis
