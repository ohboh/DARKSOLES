extends SceneTree
var errors:=0
func check(ok:bool,desc:String):
	if not ok:
		push_error(desc)
		errors+=1
func _initialize():call_deferred("verify")
func verify():
	var run=preload("res://game/scenes/main.tscn").instantiate()
	root.add_child(run)
	run.reset_run()
	run.set_process(false)
	var arms=run.hands
	var left=arms.channels[0]
	var right=arms.channels[1]
	var lib=arms.get_node("ClipLibrary").get_animation_library("")
	var clip=Animation.new()
	clip.length=.5
	for side in ["L","R"]:
		var t=clip.add_track(Animation.TYPE_ROTATION_3D)
		var bone=arms.skeleton.find_bone("Bone.021."+side)
		clip.track_set_path(t,NodePath("Rig/Armature/Skeleton3D:Bone.021."+side))
		var rest=arms.skeleton.get_bone_pose_rotation(bone)
		clip.track_insert_key(t,0.,rest)
		clip.track_insert_key(t,.5,rest*Quaternion(Vector3.RIGHT,.65))
	lib.add_animation("test_both",clip)
	left.shield=&"test_both"
	right.sword=&"test_both"
	var blade_transform=arms.blade.global_transform
	run.act(0)
	check(right.active_slot=="sword" and left.active_slot=="","Sword routed only to right assignment")
	run.act(1)
	check(right.active_slot=="sword" and left.active_slot=="shield","Sword and Shield overlap")
	for i in 12:run._process(.016)
	await process_frame
	check(not arms.blade.global_transform.is_equal_approx(blade_transform),"Animated palm moves the sword")
	for i in 2:
		var channel=arms.channels[i]
		var action="shield" if i==0 else "sword"
		var masked=channel.clips.get_animation(action)
		check(masked.get_track_count()==1 and str(masked.track_get_path(0)).ends_with(".L" if i==0 else ".R"),"Mask follows arm")
		var bone=arms.skeleton.find_bone("Bone.021."+("L" if i==0 else "R"))
		check(not arms.skeleton.get_bone_pose_rotation(bone).is_equal_approx(channel.rest_poses[bone].basis.get_rotation_quaternion()),"Arm bones animated")
	left.mend=&"Armature|drinking"
	check(left.begin(&"mend",false),"Imported animation resolves against the rig")
	run.damage(3)
	run._process(.016)
	check(not run.arm and not arms.shield.visible and left.active_slot=="","Lost arm stops playback")
	for i in 60:run._process(.016)
	check(right.active_slot=="","Finished action returns to fallback")
	run.reset_run()
	check(run.arm and not left.one_shot and not right.one_shot,"Restart clears both channels")
	print("Arm animation checks: ",errors," failures")
	quit(int(errors>0))
