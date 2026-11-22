extends SceneTree
func _initialize(): call_deferred("verify")
func verify():
	var g=load("res://game/scenes/main.tscn").instantiate()
	root.add_child(g)
	g.reset_run(false)
	g.weapons.reset_playback()
	g.transitioning=false
	g.offered_weapon="shield"
	g.state="weapon_offer"
	g.pickup_choice(0)
	g.pickup_choice(0)
	g.pickup_choice(0)
	g.pickup_choice(1)
	g.pickup_choice(2)
	g.pickup_choice(-1)
	g.pickup_choice(0)
	g.pickup_choice(1)
	g.pickup_choice(2)
	assert(g.equipped==["shield","shield"])
	assert(g.slots==["Shield","Shield Bash","Parry"])
	assert(g.slot_hands==[0,0,0])
	g.arm=false
	g.weapons.reset_playback()
	g.act(0)
	assert(g.guard>0 and g.guard_hand==0)
	g.weapons.animate(g,.016)
	assert(g.weapons.rigs[0].visible and not g.weapons.rigs[1].visible)
	g.offered_weapon="sword"
	g.state="weapon_offer"
	var before=g.equipped.duplicate()
	g.pickup_choice(1)
	assert(g.equipped==before and g.state=="run")
	g.queue_free()
	await process_frame
	print("Dual shields, right shield after left loss, and discard passed")
	quit()
