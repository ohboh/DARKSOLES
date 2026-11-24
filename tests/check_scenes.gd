extends SceneTree
var failures=0
func verify(ok:bool,label:String):
	if not ok:
		failures+=1
		push_error(label)
func _initialize(): call_deferred("suite")
func tap(button:Button):
	var pos=button.get_global_rect().get_center()
	for down in [true,false]:
		var e=InputEventScreenTouch.new()
		e.position=pos
		e.pressed=down
		Input.parse_input_event(e)
		Input.flush_buffered_events()
		await process_frame
func suite():
	root.size=Vector2i(540,1170)
	var game=preload("res://game/scenes/main.tscn").instantiate()
	root.add_child(game)
	await process_frame
	await tap(game.ui.get_node("Title/Descend"))
	verify(game.state=="run","Native Descend touch")
	game.set_process(false)
	for operation in ["Leave","Open"]:
		game.reset_run()
		for index in game.tiles.keys():
			if index>=3:
				game.tiles[index].node.queue_free()
				game.tiles.erase(index)
		game.world.tail=3
		game.world.plan=["relic"]
		game.generate()
		for i in 160:
			game._process(.016)
			if game.state=="treasure": break
		await process_frame
		verify(game.ui.get_node("Treasure").visible,"Chest panel")
		await tap(game.ui.get_node("Treasure/BottomRow/"+operation))
		game.ui.refresh()
		if operation=="Leave":
			verify(game.state=="run","Native Leave touch")
		else:
			verify(game.state=="relic","Native Open touch")
			var offer=game.offer
			await tap(game.ui.get_node("Relic/BottomRow/Slot2"))
			verify(game.slots[1]==offer and game.state=="run","Native relic replacement")
	var first=game.world.skeleton_scene.instantiate()
	var other=game.world.wraith_scene.instantiate()
	root.add_child(first)
	root.add_child(other)
	first.base_health=9
	first.heavy_chance=1
	first.start_encounter(0.)
	first.advance_attack(5.,0.)
	verify(first.hp==9 and first.heavy,"Inspector overrides drive enemy combat")
	verify(first.sprite.material_override!=other.sprite.material_override,"Per-instance shader isolation")
	verify(other.get_node("Illustration").material_override.get_shader_parameter("illustration").resource_path.ends_with("Wraith.jpg"),"Inherited variant artwork")
	print("Scene, inheritance and native touch checks: ",failures," failures")
	quit(int(failures>0))

