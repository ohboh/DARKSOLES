extends Node3D
## Distance in corridor tiles at which the player stops and combat begins. One tile is 3 world units.
@export_range(0.25, 3.0, 0.05) var enemy_encounter_range := 1.0
@onready var cam=$Player
@onready var world=$Dungeon
@onready var weapons=$Player/AnimatedWeapons
var hit_stop_remaining := 0.0
var movement_scale := 1.0
@onready var bolt=$Fireball
@onready var ui=$Interface/HUD
@onready var hurt_vignette=$Interface/HurtVignette
@onready var post=$Interface/Dither.material
@onready var quantize=$Interface/Palette.material
@onready var eye_height=cam.position.y
@onready var level_pitch=cam.rotation.x
var state="title"
var p=0.
var hp=5
var maximum=5
var kills=0
var best=0
var equipped := ["sword", "shield"]
var slot_hands := [0, 1, 0]
var offered_weapon := "sword"
var assigned_pickup_slots: Array[int] = []
var selected_hand := 0
var selected_actions: Array[String] = []
var guard_hand := 1
var parry_hand := 0
var slots=["Slash","Shield","Sword Parry"]
var cd=[0.,0.,0.]
var arm=true
var guard=0.
var parry=0.
var flash=0.
var slash=0.
var bash=0.
var success=0.
var shake=0.
var time=0.
var tiles:Dictionary:
	get: return world.tiles
var jt=-1
var pending=9
var fight=-1
var light_dirty=true
var light_clock=0.
var near=-1
var projectile=-1
var flight=0.
var treasure_index=-1
var offer=""
var notice=""
var notice_t=0.
var turn_t=0.
var turn_dir=0
var heading=0.
var origin=Vector3.ZERO
var anchor=0.
var outgoing_corridor: Dictionary={}
var turn_center=Vector3.ZERO
var turn_to=Vector3.ZERO
var turn_entry_heading=0.
const JUNCTION_HALF_WIDTH=1.5
@onready var audio = $Audio
@onready var transition_overlay: ColorRect = $Transition/Black
@export_range(0.1, 2.0, 0.05) var fade_duration := 0.45
var transitioning := false

func _ready():
	weapons.strike.connect(resolve_weapon_strike)
	world.geometry_changed.connect(func(): light_dirty=true)
	ui.bind(self)
	var save=ConfigFile.new()
	if save.load("user://descent.cfg")==OK: best=save.get_value("run","best",0)
	reset_run(false)
	state="title"
	weapons.reset_playback()
	audio.reset()
	fade_title_in()
func fade_title_in():
	transitioning = true
	var tween := create_tween()
	tween.tween_property(transition_overlay, "color:a", 0.0, fade_duration)
	await tween.finished
	transitioning = false

func request_run():
	if transitioning: return
	transitioning = true
	var fade_out := create_tween()
	fade_out.tween_property(transition_overlay, "color:a", 1.0, fade_duration)
	await fade_out.finished
	# Present the black frame before generating the new dungeon.
	await get_tree().process_frame
	reset_run()
	weapons.set_playback_speed(0.0)
	audio.reset()
	ui.refresh()
	await get_tree().create_timer(0.2).timeout
	var fade_in := create_tween()
	fade_in.tween_property(transition_overlay, "color:a", 0.0, fade_duration)
	await fade_in.finished
	weapons.set_playback_speed(1.0)
	weapons.start_run()
	transitioning = false

func clear_outgoing_corridor():
	for tile in outgoing_corridor.values():
		tile.node.queue_free()
	light_dirty=true
	outgoing_corridor.clear()

func reset_run(with_music: bool = true):
	equipped = ["sword", "shield"]
	slot_hands = [0, 1, 0]
	weapons.configure(equipped)
	if with_music: audio.start_gameplay_music()
	audio.reset()
	hit_stop_remaining = 0.0
	movement_scale = 1.0
	weapons.set_playback_speed(1.0)
	weapons.start_run()
	clear_outgoing_corridor()
	treasure_index=-1
	world.reset()
	p=0.; hp=cam.starting_health; maximum=cam.starting_health; kills=0; arm=true; guard=0.; parry=0.; slash=0.; flash=0.; shake=0.; success=0.; bash=0.
	near=-1; fight=-1; projectile=-1; pending=9; jt=-1
	notice_t=0.; slots=[cam.action_name(cam.first_action),cam.action_name(cam.second_action),cam.action_name(cam.third_action)]; cd=[0.,0.,0.]
	for i in 3:
		slot_hands[i] = 1 if slots[i] in ["Shield", "Shield Bash", "Shield Parry"] else 0
	origin=Vector3.ZERO; heading=0.; anchor=0.; state="run"
	generate()
func at(distance_:float):
	return origin+Vector3(0,0,-3*(distance_-anchor)).rotated(Vector3.UP,heading)
func generate():
	world.generate(p,heading,at)
func say(s):
	notice=s; notice_t=1.1
func damage(n):
	audio.play("hurt")
	hp-=n; flash=.45; shake=.35
	if hp<=0:
		state="dead"
		audio.play("death")
		weapons.cue(&"death",arm)
		best=maxi(best,int(p*2))
		var save=ConfigFile.new()
		save.set_value("run","best",best)
		save.save("user://descent.cfg")
	else:
		weapons.cue(&"hurt",arm)
	if hp>0 and arm and hp<=cam.arm_loss_health:
		arm=false;
		if guard_hand==1: guard=0.
		if parry_hand==1: parry=0.
		flash=.9; shake=.7; say("You lose your arm")
func hit(idx,amount,stun=0.):
	if not tiles.has(idx) or tiles[idx].dead: return
	var t=tiles[idx]
	t.obj.take_hit(amount,stun)
	if amount > 0 or stun > 0:
		audio.play_impact(t.obj)
		hit_stop_remaining = cam.hit_stop_duration
		if hit_stop_remaining > 0: weapons.set_playback_speed(0.0)
	if t.obj.hp<=0:
		t.dead=true; t.obj.hide(); kills+=1; say("Slain")
		if fight==idx: fight=-1
		if near==idx: near=-1
func act(i):
	if transitioning or state!="run" or hit_stop_remaining > 0 or cd[i]>0 or weapons.intro_stage > 0: return
	var id=slots[i]
	if id.is_empty() or (slot_hands[i] == 1 and not arm): return
	weapons.active_hand = slot_hands[i]
	match id:
		"Slash": pass
		"Shield":
			guard_hand = slot_hands[i]
			guard=cam.guard_window
		"Sword Parry", "Shield Parry": parry_hand=slot_hands[i]; parry=cam.parry_window
		"Shield Bash":
			if fight<0: return
			pass
		"Fireball":
			if near<0: return
			projectile=near; flight=cam.flight_duration
		"Mend": hp=mini(maximum,hp+cam.flask_healing); say("Blood flask")
	cd[i]=cam.action_cooldown(id)
	weapons.cue(StringName(id.to_lower().replace(" ","_")),arm)
	if id == "Fireball": audio.play("cast")
	elif id == "Mend": audio.play("heal")
func resolve_weapon_strike(action: StringName, hand: int):
	if hand == 1 and not arm: return
	if state != "run" or fight < 0: return
	match action:
		&"sword":
			slash = .18
			hit(fight, cam.sword_damage)
		&"shield_bash":
			bash = .2
			hit(fight, randi_range(0, cam.bash_max_damage), cam.bash_stun)

func combat(enemy,dt):
	if not enemy.advance_attack(dt,p): return
	if parry>0:
		enemy.mode="stun"
		enemy.timer=cam.parry_stun
		success=.3
		say("PARRY")
		audio.play("parry")
		weapons.cue(&"parry_success",arm)
	elif guard>0:
		if enemy.heavy:
			guard=0.; say("Guard broken"); audio.play("break"); damage(1)
			if hp>0: weapons.cue(&"guard_broken",arm)
		else:
			shake=.12; say("Blocked"); audio.play("block"); weapons.active_hand=guard_hand; weapons.cue(&"blocked",arm)
	else:
		damage(enemy.heavy_damage if enemy.heavy else enemy.light_damage)
func decide_treasure(open:bool):
	if state!="treasure": return
	var chest=tiles[treasure_index]
	chest.dead=true
	chest.obj.hide()
	treasure_index=-1
	state="run"
	if not open: return
	audio.play("chest")
	if world.slime_scene and randf() < chest.obj.slime_ambush_chance:
		chest.obj.queue_free()
		chest.obj=world.slime_scene.instantiate()
		chest.node.add_child(chest.obj)
		chest.obj.start_encounter(p)
		chest.kind="foe"
		chest.dead=false
		return
	offered_weapon = chest.obj.weapon_pool.pick_random() if not chest.obj.weapon_pool.is_empty() else "sword"
	offer = "Broken Sword" if offered_weapon == "sword" else "Shield"
	state = "weapon_offer"

func weapon_actions() -> Array:
	return ["Slash", "Sword Parry"] if offered_weapon == "sword" else ["Shield", "Shield Bash", "Shield Parry"]

func pickup_choice(index: int):
	match state:
		"weapon_offer":
			if index == 0: state = "weapon_hand"
			else: state = "run"
		"weapon_hand":
			if index < 0:
				state = "weapon_offer"
				return
			if index == 1 and not arm: return
			selected_hand = index
			selected_actions.clear()
			assigned_pickup_slots.clear()
			state = "weapon_actions"
		"weapon_actions":
			var available := weapon_actions()
			if index >= 0 and index < available.size():
				var action: String = available[index]
				if action in selected_actions: selected_actions.erase(action)
				elif selected_actions.size() < 3: selected_actions.append(action)
			elif index == -1 and not selected_actions.is_empty():
				# Remove this hand's actions before assigning the chosen new ones.
				for i in 3:
					if slot_hands[i] == selected_hand:
						slots[i] = ""
						cd[i] = 0.0
				state = "weapon_slots"
		"weapon_slots":
			if index < 0 or index in assigned_pickup_slots: return
			assigned_pickup_slots.append(index)
			slots[index] = selected_actions.pop_front()
			slot_hands[index] = selected_hand
			cd[index] = 0.0
			if selected_actions.is_empty():
				equipped[selected_hand] = offered_weapon
				weapons.configure(equipped)
				audio.play("relic")
				state = "run"

func replace_slot(i):
	pickup_choice(i)

func choices():
	if state=="run" and jt>=0 and fight<0 and jt+1-p<3: return tiles[jt].paths.keys()
	return []
func choose(d):
	if d in choices(): pending=d; audio.play("choice")
func junction_time_scale() -> float:
	if state == "run" and near < 0 and pending == 9 and choices().size() > 1:
		return 0.28
	return 1.0

func advance(dt):
	near=-1; jt=-1
	for n in range(int(p),int(p)+4):
		if not tiles.has(n): break
		var t=tiles[n]
		if t.paths.size() and not t.done: jt=n; break
		if near<0 and t.kind=="foe" and not t.dead: near=n
	if jt>=0 and tiles[jt].paths.size()==1:
		pending=tiles[jt].paths.keys()[0]
	var slow := junction_time_scale()
	movement_scale = slow
	audio.set_playback_speed(slow)
	var previous_position: float = p
	p+=dt*(cam.walking_speed+minf(1.4,p/120))*slow
	var encounter_position: float = near - enemy_encounter_range
	if near>=0: p=minf(p,maxf(previous_position,encounter_position))
	if jt>=0 and pending!=0: p=minf(p,jt+.5)
	fight=near if near>=0 and p>=encounter_position-0.001 else -1
	if fight>=0: combat(tiles[fight].obj,dt)
	if jt>=0 and near<0 and p>=jt+.5:
		if pending==9: pending=tiles[jt].paths.keys().pick_random()
		var t=tiles[jt]
		t.done=true
		if pending!=0:
			state="turn"; turn_dir=pending; turn_t=0.; turn_center=t.node.position
			turn_entry_heading=heading
			t.node.get_node("Passage%d"%pending).queue_free()
			world.branch(jt,t.paths[pending],outgoing_corridor)
			turn_to=turn_center+Vector3(pending*JUNCTION_HALF_WIDTH,0,0).rotated(Vector3.UP,heading)
			origin=turn_to; anchor=jt+1.; heading-=pending*PI/2; p=anchor
		pending=9; jt=-1
	var ahead=int(p+.60)
	if state=="run" and fight<0 and tiles.has(ahead):
		var chest=tiles[ahead]
		if chest.kind=="relic" and not chest.dead:
			treasure_index=ahead
			state="treasure"
	if tiles.has(int(p)) and p>=int(p)+.5:
		var t=tiles[int(p)]
		if not t.dead and t.kind=="shrine":
			t.dead=true
			t.obj.hide()
			hp=mini(maximum,hp+t.obj.healing)
			say(t.obj.message)
			audio.play("heal")
	generate()
	for k in tiles.keys():
		if k<int(p)-2: tiles[k].node.queue_free(); tiles.erase(k)
func _process(delta):
	if transitioning: return
	if hit_stop_remaining > 0:
		hit_stop_remaining = maxf(0.0, hit_stop_remaining - delta)
		if hit_stop_remaining > 0: return
		weapons.set_playback_speed(movement_scale)
	var frame_dt := minf(delta, .05)
	var time_scale := junction_time_scale()
	audio.set_playback_speed(time_scale)
	var dt := frame_dt * time_scale
	time+=dt
	if state not in ["title","dead"]:
		for i in 3: cd[i]=maxf(0.,cd[i]-dt)
		guard=maxf(0.,guard-dt); parry=maxf(0.,parry-dt); flash=maxf(0.,flash-dt); shake=maxf(0.,shake-dt)
		slash=maxf(0.,slash-dt); success=maxf(0.,success-dt); bash=maxf(0.,bash-dt); notice_t=maxf(0.,notice_t-dt)
		if projectile>=0:
			flight-=dt
			if flight<=0:
				hit(projectile,cam.fireball_damage); projectile=-1; say("Burned"); audio.play("fire_hit")
		if state=="run": advance(frame_dt)
		elif state=="turn":
			turn_t+=dt/.7
			if turn_t>=1:
				clear_outgoing_corridor()
				state="run"
	var yaw=heading
	var loc=at(p)
	if state=="turn":
		# Plant at the crossing, finish the quarter turn, then leave on the new axis.
		var pivot=smoothstep(0.,.50,turn_t)
		yaw=turn_entry_heading-turn_dir*PI*.5*pivot
		loc=turn_center.lerp(turn_to,clampf((turn_t-.50)*2.,0.,1.))
	if state!="turn": loc.y=world.walking_height(p)
	world.update_doors(p)
	var index=floori(p)
	var descent_weight=1. if tiles.has(index) and tiles[index].terrain=="stairs" else 0.
	if descent_weight==0. and tiles.has(index+1) and tiles[index+1].terrain=="stairs":
		descent_weight=smoothstep(.25,1.,p-index)
	var pitch_target=level_pitch-deg_to_rad(cam.stair_look_down)*descent_weight
	cam.rotation.x=lerp_angle(cam.rotation.x,pitch_target,1.-exp(-7.*dt))
	cam.rotation.y=yaw
	cam.position=loc+Vector3(sin(time*97)*shake*.06,eye_height+.018*sin(p*TAU)+cos(time*83)*shake*.04,0)
	weapons.animate(self,dt)
	audio.update_steps(p, state=="run" and fight<0 and weapons.intro_stage==0, weapons.steps_per_tile)
	bolt.visible=projectile>=0 and tiles.has(projectile)
	if bolt.visible: bolt.position=cam.position.lerp(tiles[projectile].node.position+Vector3.UP,1.-flight/cam.flight_duration)
	for t in tiles.values():
		if t.dead: continue
		if t.kind=="foe": t.obj.animate(dt,time)
	light_clock+=dt
	if light_clock>.12: light_clock=0.; light_dirty=true
	if light_dirty:
		var lights: Array[Vector3]=[]
		collect_lights(tiles,lights)
		collect_lights(outgoing_corridor,lights)
		lights.sort_custom(func(a,b): return cam.position.distance_squared_to(a)<cam.position.distance_squared_to(b))
		while lights.size()<6: lights.append(Vector3(1e6,1e6,1e6))
		lights.resize(6)
		for i in 6:
			RenderingServer.global_shader_parameter_set("torch_%d"%i,lights[i])
		light_dirty=false
	hurt_vignette.update_health(hp,maximum,flash,dt)
	post.set_shader_parameter("parry",success)
	quantize.set_shader_parameter("menu",state in ["title","dead"])
	ui.refresh()



func collect_lights(sections:Dictionary,lights:Array[Vector3]):
	for tile in sections.values(): tile.node.append_lights(lights)
