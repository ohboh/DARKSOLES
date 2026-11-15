extends Control

var run
@export var descriptions={"Shield Bash":"Stagger a foe. Requires your shield arm.","Fireball":"Cast at the nearest foe for two damage.","Mend":"Drink the blood flask to restore one life."}

func bind(controller):
	run=controller
	$Title/Descend.pressed.connect(run.reset_run)
	$Death/Restart.pressed.connect(run.reset_run)
	$Treasure/Open.pressed.connect(run.decide_treasure.bind(true))
	$Treasure/Leave.pressed.connect(run.decide_treasure.bind(false))
	$Relic/Leave.pressed.connect(run.replace_slot.bind(-1))
	for i in 3:
		get_node("Relic/Slot%d"%(i+1)).pressed.connect(run.replace_slot.bind(i))
		get_node("Play/Slot%d"%(i+1)).pressed.connect(run.act.bind(i))
	refresh()

func refresh():
	$Title.visible=run.state=="title"
	$Relic.visible=run.state=="relic"
	$Death.visible=run.state=="dead"
	$Treasure.visible=run.state=="treasure"
	$Play.visible=run.state in ["run","turn"]
	if $Play.visible:
		$Play/Distance.text="%d m"%int(run.p*2)
		$Play/Notice.text=run.notice if run.notice_t>0 else ""
		for i in 3:
			var slot=get_node("Play/Slot%d"%(i+1))
			var action=run.slots[i]
			slot.get_node("Caption").text=action
			slot.get_node("Icon").action=action
			var cover=slot.get_node("Cooldown")
			cover.visible=run.cd[i]>0
			cover.anchor_top=1.-run.cd[i]/run.cam.cooldowns[action]
			slot.modulate=Color(.4,.4,.4) if not run.arm and action in ["Shield","Shield Bash"] else Color.WHITE
	elif $Relic.visible:
		$Relic/Offer.text=run.offer
		$Relic/Description.text=descriptions.get(run.offer,"")
		for i in 3: get_node("Relic/Slot%d"%(i+1)).text=run.slots[i]
	elif $Death.visible:
		$Death/Summary.text="%d m descended   ·   %d foes slain"%[run.p*2,run.kills]
		$Death/Best.text="Best descent   /   %d m"%run.best
	queue_redraw()

func _draw():
	if not run or not $Play.visible: return
	draw_set_transform(Vector2.ZERO,0,size/Vector2(540,1170))
	if run.slash>0: draw_line(Vector2(432,351),Vector2(108,725),Color.WHITE,2)
	if run.success>0: draw_arc(Vector2(270,491),6+(0.3-run.success)*648,0,TAU,72,Color.WHITE,2)
	if run.fight<0: return
	var enemy=run.tiles[run.fight].obj
	var center=run.cam.unproject_position(enemy.glow.global_position)*Vector2(540,1170)/size
	if enemy.mode=="wind":
		draw_arc(center,42,0,TAU,80,Color.WHITE,2)
		draw_arc(center,42+114*enemy.timer/enemy.dur,0,TAU,100,Color.RED if enemy.heavy else Color.WHITE,4)
	elif enemy.mode=="stun":
		draw_string(get_theme_default_font(),Vector2(0,center.y-137),"STUNNED",HORIZONTAL_ALIGNMENT_CENTER,540,17)

func _gui_input(event):
	if not run: return
	if event is InputEventScreenTouch or event is InputEventMouseButton:
		if not event.pressed: return
		if event is InputEventMouseButton and event.button_index!=MOUSE_BUTTON_LEFT: return
		if event.position.y/size.y<1027./1170.:
			run.choose(clampi(int(event.position.x/size.x*3.),0,2)-1)

func _unhandled_key_input(event):
	if not run or not event.pressed or event.echo: return
	match event.keycode:
		KEY_ENTER,KEY_SPACE:
			if run.state in ["title","dead"]: run.reset_run()
		KEY_1,KEY_A: run.act(0)
		KEY_2,KEY_S: run.act(1)
		KEY_3,KEY_D: run.act(2)
		KEY_LEFT: run.choose(-1)
		KEY_UP: run.choose(0)
		KEY_RIGHT: run.choose(1)
