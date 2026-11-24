@tool
extends Node3D

@export_group("Hit audio")
@export_enum("flesh", "bone", "slime", "wood", "metal", "shield", "spectral") var impact_material := "flesh"
## Optional sound for this enemy, overriding the material preset.
@export var impact_sound: AudioStream
@export_group("Health")
@export_range(1, 50) var base_health := 2
@export_range(1, 50) var minimum_health := 2
@export_group("Attack")
@export_range(0, 1, .01) var heavy_chance := .45
@export_range(.1, 5, .01) var light_windup := .9
@export_range(.1, 5, .01) var heavy_windup := 1.15
@export var light_damage := 1
@export var heavy_damage := 2
## Multiplies windup and recovery durations. Lower values make attacks faster.
@export_range(0.5, 1.5, 0.01) var attack_timing_scale := 0.92
@export var first_attack_delay := .7
@export var recovery_range := Vector2(.7,1.3)
@export var stun_damage_multiplier := 2

@export_group("Conversation")
## Plead, Reason, Threaten: chance to peacefully end this encounter.
@export var talk_chances := Vector3(0.15, 0.0, 0.35)
@export var talk_greeting := "It watches you without a word."
## Response lists follow the action bar order: Plead, Reason, Threaten.
@export var peaceful_replies := PackedStringArray(["Your lowered hands quiet it. It moves aside.", "It studies you, then steps aside.", "It shrinks back from your voice."])
@export var angry_replies := PackedStringArray(["It takes your trembling for weakness.", "It waits for your voice to stop. Then it lunges.", "It answers your challenge with a lunge."])
@export var wounded_greeting := "It flinches when you raise your empty hand."
@export var wounded_chances := Vector3(0.05, 0.0, 0.55)
@export var wounded_peaceful_replies := PackedStringArray(["It waits until your weapon drops, then slips past.", "It watches your blade as it withdraws.", "One glance at your weapon sends it scrambling aside."])
@export var wounded_angry_replies := PackedStringArray(["Your plea comes too late. It bears down on you.", "Its eyes follow the weapon that struck it.", "Wounded and cornered, it springs at you."])
var was_attacked := false

func talk_reply(choice: int, spared: bool) -> String:
	var replies := peaceful_replies if spared else angry_replies
	if was_attacked:
		replies = wounded_peaceful_replies if spared else wounded_angry_replies
	if choice < replies.size() and not replies[choice].is_empty():
		return replies[choice]
	return "It steps aside." if spared else "It lunges."

@export_range(1, 6) var anger_attacks := 3
@export_range(0.3, 2.0, 0.05) var anger_windup := 0.7
@export_range(0.1, 2.0, 0.05) var anger_recovery := 0.45
@export_range(0.3, 2.0, 0.05) var anger_first_delay := 0.25
var talked := false
var flurry := 0
var flurry_attack := false

func provoke():
	flurry = anger_attacks
	mode = "idle"
	timer = anger_first_delay

var hp: int
var mode := "idle"
var timer := 0.
var heavy := false
var dur := 1.
var hit := 0.
@onready var sprite: MeshInstance3D = $Illustration
@onready var glow: Sprite3D = $AttackGlow
@onready var rest_pose: Transform3D = sprite.transform

func _ready():
	start_encounter(0.)

func start_encounter(depth: float):
	was_attacked = false
	talked = false
	hp = maxi(minimum_health,base_health + mini(3,int(depth/30.)))
	timer = first_attack_delay * attack_timing_scale

func take_hit(amount: int, stun: float):
	if amount > 0 or stun > 0:
		was_attacked = true
	hit = .15
	hp -= amount * (stun_damage_multiplier if mode=="stun" else 1)
	if hp>0 and stun>0:
		mode="stun"
		timer=stun

# Return true once, on the frame an attack lands. The player resolves guard and parry.
func advance_attack(dt: float, depth: float) -> bool:
	timer -= dt
	if timer>0: return false
	match mode:
		"idle":
			flurry_attack = flurry > 0
			heavy = flurry_attack or randf()<heavy_chance
			dur = (heavy_windup if heavy else light_windup)*(1.-minf(.3,depth/500.))*attack_timing_scale
			if flurry_attack: dur = anger_windup
			timer=dur
			mode="wind"
		"wind":
			mode="idle"
			timer=randf_range(recovery_range.x,recovery_range.y)*attack_timing_scale
			if flurry_attack:
				flurry -= 1
				timer = anger_recovery
			return true
		"stun":
			mode="idle"
			timer=.6
	return false

func animate(dt: float, clock: float):
	hit=maxf(0.,hit-dt)
	glow.visible=mode=="wind" and not heavy
	if glow.visible:
		var tint=Color.WHITE
		tint.a=.35+.6*(1.-timer/dur)
		glow.modulate=tint
	var rim := lerpf(0.26, 0.55, clampf(1.0-timer/dur, 0.0, 1.0)) if heavy and mode=="wind" else 0.0
	sprite.material_override.set_shader_parameter("heavy_rim", rim)
	sprite.material_override.set_shader_parameter("hit_flash",hit/.15)
	var angle=.07*(1.-timer/dur) if mode=="wind" else .009*sin(clock*2.)
	sprite.transform=rest_pose
	sprite.rotate_z(angle)
	sprite.rotate_x(-hit)
	if mode=="stun": sprite.position.x+=sin(clock*40)*.055
