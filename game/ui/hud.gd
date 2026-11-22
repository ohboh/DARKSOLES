extends Control

var action_choice := 0
var run
@export var descriptions={"Shield Bash":"Staggers a foe.","Fireball":"Burns the nearest foe.","Mend":"Restores one life."}

func bind(controller):
	run=controller
	$Title/Descend.pressed.connect(run.request_run)
	$Death/Restart.pressed.connect(run.request_run)
	$Treasure/Open.pressed.connect(run.decide_treasure.bind(true))
	$Treasure/Leave.pressed.connect(run.decide_treasure.bind(false))
	$Relic/Leave.pressed.connect(run.replace_slot.bind(-1))
	for i in 3:
		get_node("Relic/Slot%d"%(i+1)).pressed.connect(pickup_button.bind(i))
		get_node("Play/Slot%d"%(i+1)).pressed.connect(run.act.bind(i))
	refresh()

func refresh():
	$Title.visible=run.state=="title"
	$Relic.visible=run.state.begins_with("weapon_")
	$Death.visible=run.state=="dead"
	$Treasure.visible=run.state=="treasure"
	$Play.visible=run.state in ["run","turn"]
	if $Play.visible:
		$Play/BranchPrompt.visible = run.pending == 9 and run.choices().size() > 1
		$Play/Distance.text="%d m"%int(run.p*2)
		$Play/Notice.text=run.notice if run.notice_t>0 else ""
		for i in 3:
			var slot=get_node("Play/Slot%d"%(i+1))
			var action=run.slots[i]
			slot.get_node("Caption").text=("Slash" if action=="Sword" else action) + (" · R" if run.slot_hands[i]==0 else " · L") if not action.is_empty() else "Empty"
			slot.get_node("Icon").action=action
			var cover=slot.get_node("Cooldown")
			cover.visible=run.cd[i]>0
			cover.anchor_top=1.-run.cd[i]/run.cam.cooldowns.get(action,1.0)
			slot.modulate=Color(.4,.4,.4) if not run.arm and run.slot_hands[i]==1 else Color.WHITE
	elif $Relic.visible:
		refresh_pickup()
	elif $Death.visible:
		$Death/Summary.text="%d m descended   ·   %d foes slain"%[run.p*2,run.kills]
		$Death/Best.text="Best descent   /   %d m"%run.best
	$WeaponPreview.visible=$Relic.visible
	queue_redraw()

func _draw():
	if not run or not $Play.visible: return
	draw_set_transform(Vector2.ZERO,0,size/Vector2(540,1170))
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
			if run.state in ["title","dead"]: run.request_run()
		KEY_1,KEY_A: run.act(0)
		KEY_2,KEY_S: run.act(1)
		KEY_3,KEY_D: run.act(2)
		KEY_LEFT: run.choose(-1)
		KEY_UP: run.choose(0)
		KEY_RIGHT: run.choose(1)

func pickup_button(index: int):
	match run.state:
		"weapon_offer":
			if index == 1: return
			run.pickup_choice(0 if index == 0 else 1)
		"weapon_hand":
			if index == 1:
				run.pickup_choice(-1)
			else:
				action_choice=0
				run.pickup_choice(1 if index==0 else 0)
		"weapon_actions":
			if index == 2:
				if not run.selected_actions.is_empty(): run.pickup_choice(-1)
				return
			if index == 0: run.pickup_choice(action_choice)
			action_choice+=1
			if action_choice >= run.weapon_actions().size():
				if not run.selected_actions.is_empty(): run.pickup_choice(-1)
				action_choice=0
		"weapon_slots":
			run.pickup_choice(index)
	refresh()

func refresh_pickup():
	$Relic/Heading.text="WEAPON FOUND"
	$Relic/Offer.text=run.offer
	$Relic/Description.text="Slash / Parry" if run.offered_weapon=="sword" else "Guard / Bash / Parry"
	$Relic/Leave.visible=false
	var labels: Array = []
	var disabled := [false,false,false]
	match run.state:
		"weapon_offer":
			$Relic/Instruction.text="Take this weapon?"
			labels=["Take","","Discard"]
			disabled[1]=true
		"weapon_hand":
			$Relic/Instruction.text="Replace which hand?"
			labels=["Left","Back","Right"]
			disabled[0]=not run.arm
		"weapon_actions":
			var action: String=run.weapon_actions()[action_choice]
			var caption: String="Slash" if action=="Sword" else action
			$Relic/Instruction.text="Add "+caption+"?"
			labels=["Add "+caption,"Skip","Done"]
			disabled[2]=run.selected_actions.is_empty()
		"weapon_slots":
			$Relic/Instruction.text="Place "+run.selected_actions[0]+" in a slot"
			for action in run.slots: labels.append(action if not action.is_empty() else "Empty")
			for i in run.assigned_pickup_slots: disabled[i]=true
	for i in 3:
		var button=get_node("Relic/Slot%d"%(i+1))
		button.visible=not labels[i].is_empty()
		button.disabled=disabled[i]
		button.text=labels[i]
	$WeaponPreview.show_weapon(run.offered_weapon)
