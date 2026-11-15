extends SceneTree
var failures=0
func check(ok:bool,detail:String):
	if not ok: failures+=1; push_error(detail)
func _initialize():call_deferred("verify")
func verify():
	seed(47)
	var run=preload("res://game/scenes/main.tscn").instantiate()
	root.add_child(run)
	run.reset_run()
	run.set_process(false)
	var stairs=0
	var stair_run=0
	var door_flights=0
	var previous_terrain=""
	var last_landing=-1000
	var doors=0
	var slimes=0
	var turns=0
	var cues=0
	var prev_height=0.
	var checked_index=-1
	for frame in 28000:
		if run.state=="treasure": run.decide_treasure(false)
		if run.choices().size(): run.choose(run.choices()[0])
		if run.fight>=0:
			run.act(0)
			var foe=run.tiles[run.fight].obj if run.fight>=0 else null
			if foe and foe.mode=="wind" and foe.timer<.15: run.act(2)
		run._process(.016)
		var n=int(run.p)
		var tile=run.tiles[n]
		var h=run.world.walking_height(run.p)
		check(h<=prev_height+.001,"Route climbed")
		check(prev_height-h<.15,"Vertical discontinuity")
		prev_height=h
		if n!=checked_index:
			checked_index=n
			if tile.terrain=="door": doors+=1
			if tile.terrain=="stairs":
				if stair_run==0:
					stairs+=1
					check(n-last_landing>=run.world.minimum_stair_spacing,"Stairways clustered")
					if previous_terrain=="door": door_flights+=1
				stair_run+=1
				check(tile.kind=="" and tile.exit_height<tile.node.position.y,"Unsafe or ascending stairs")
			if tile.terrain!="stairs" and stair_run>0:
				check(stair_run==run.world.stair_sections,"Incomplete stair flight")
				last_landing=n
				stair_run=0
			previous_terrain=tile.terrain
			if tile.kind=="foe" and tile.obj.scene_file_path.ends_with("slime.tscn"): slimes+=1
			if tile.paths.size():
				for direction in tile.paths:
					var axis=Vector3(direction,0,0) if direction!=0 else Vector3.FORWARD
					var found=false
					for hint in tile.node.get_children():
						if hint.scene_file_path.ends_with("route_omen.tscn") and hint.position.distance_to(axis)<.1:
							var expected={"relic":0,"shrine":1,"foe":2}[tile.paths[direction]]
							found=hint.material_override.get_shader_parameter("omen")==expected
					check(found,"Branch cue mismatch")
					cues+=1
		if tile.terrain=="stairs": check(run.fight<0,"Combat on stairway")
		if tile.terrain=="door" and run.p-n>.25:check(tile.node.hinge.rotation.y<-1.5,"Door blocks passage")
		if run.state=="turn":turns+=1
		if run.state=="dead" or run.p>=240: break
	check(door_flights>0 and stairs>0 and doors>0 and slimes>0 and turns>0 and cues>0,"Missing content on seeded route")
	print("Transition checks: ",failures," failures; ",stairs," flights (",door_flights," behind doors), ",doors," doors, ",slimes," slimes, ",cues," branch cues")
	quit(int(failures>0))
