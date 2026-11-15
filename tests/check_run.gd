extends SceneTree
# Run with Godot --headless --path . --script res://tests/check_run.gd
var errors=0
func expect(ok,description):
	if not ok:
		errors+=1
		push_error(description)
func _initialize(): call_deferred("verify")
func verify():
	seed(42)
	var g=load("res://game/scenes/main.tscn").instantiate()
	root.add_child(g)
	g.reset_run()
	g.set_process(false)
	var turns=0
	var previous=""
	for i in 30000:
		if g.state=="dead": break
		if g.state=="treasure": g.decide_treasure(true)
		if g.state=="relic": g.replace_slot(-1)
		if g.state=="turn" and previous!="turn": turns+=1
		if g.fight>=0:
			g.act(0)
			if g.fight>=0 and g.tiles[g.fight].obj.mode=="wind" and g.tiles[g.fight].obj.timer<.16: g.act(2)
		if g.choices().size(): g.choose(g.choices()[0])
		previous=g.state
		g._process(.016)
		if g.p>=250: break
	expect(g.p>=250 and g.kills>5 and turns>0,"Long descent stalled")
	expect(g.tiles.size()<18,"Corridor retention exceeded lookahead")
	g.world.roaming_enemy_chance=1.
	g.reset_run()
	for frame in 600:
		g._process(.016)
		if g.fight>=0: break
	if g.fight<0:
		push_error("Combat fixture did not reach its first enemy")
		quit(1)
		return
	var t=g.tiles[g.fight].obj
	t.mode="wind"; t.heavy=false; t.timer=.01
	g.act(1); g.combat(t,.02)
	expect(g.hp==5,"Shield missed light strike")
	t.mode="wind"; t.heavy=true; t.timer=.01
	g.combat(t,.02)
	expect(g.hp==4 and g.guard==0,"Heavy guard break damage")
	t.mode="wind"; t.timer=.01; g.act(2); g.combat(t,.02)
	expect(t.mode=="stun" and g.hp==4,"Perfect parry")
	t.hp=8; g.act(0)
	expect(t.hp==6,"Stunned sword damage")
	g.state="relic"; g.offer="Shield Bash"; g.replace_slot(0); g.act(0)
	expect(t.mode=="stun" and is_equal_approx(t.timer,1.3),"Bash stagger")
	g.state="relic"; g.offer="Fireball"; g.replace_slot(0)
	var before=t.hp
	g.act(0)
	expect(g.projectile==g.near and t.hp==before,"Fireball cast")
	for i in 19: g._process(.016)
	expect(t.hp==before-4,"Delayed fireball with stun multiplier")
	g.damage(2)
	expect(not g.arm,"Lost arm")
	g.cd[1]=0.; g.act(1)
	expect(g.guard==0 and g.cd[1]==0,"Guard with missing arm")
	g.state="relic"; g.offer="Mend"; g.replace_slot(0); g.act(0)
	expect(g.hp==3 and not g.arm,"Flask restores health only")
	print("DARKSOLES mechanics checks: ",errors," failures")
	quit(int(errors>0))
