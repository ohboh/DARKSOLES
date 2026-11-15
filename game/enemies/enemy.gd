@tool
extends Node3D

@export_group("Appearance")
@export var illustration: Texture2D:
	set(value):
		illustration = value
		if is_node_ready():
			apply_illustration()
@export_group("Health")
@export_range(1, 50) var base_health := 2
@export_range(1, 50) var minimum_health := 2
@export_group("Attack")
@export_range(0, 1, .01) var heavy_chance := .45
@export_range(.1, 5, .01) var light_windup := .9
@export_range(.1, 5, .01) var heavy_windup := 1.15
@export var light_damage := 1
@export var heavy_damage := 2
@export var first_attack_delay := .7
@export var recovery_range := Vector2(.7,1.3)
@export var stun_damage_multiplier := 2

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
	apply_illustration()
	start_encounter(0.)

func apply_illustration():
	if illustration:
		$Illustration.material_override.set_shader_parameter("illustration", illustration)

func start_encounter(depth: float):
	hp = maxi(minimum_health,base_health + mini(3,int(depth/30.)))
	timer = first_attack_delay

func take_hit(amount: int, stun: float):
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
			heavy = randf()<heavy_chance
			dur = (heavy_windup if heavy else light_windup)*(1.-minf(.3,depth/500.))
			timer=dur
			mode="wind"
		"wind":
			mode="idle"
			timer=randf_range(recovery_range.x,recovery_range.y)
			return true
		"stun":
			mode="idle"
			timer=.6
	return false

func animate(dt: float, clock: float):
	hit=maxf(0.,hit-dt)
	glow.visible=mode=="wind"
	if glow.visible:
		var tint=Color.RED if heavy else Color.WHITE
		tint.a=.35+.6*(1.-timer/dur)
		glow.modulate=tint
	sprite.material_override.set_shader_parameter("hit_flash",hit/.15)
	var angle=.07*(1.-timer/dur) if mode=="wind" else .009*sin(clock*2.)
	sprite.transform=rest_pose
	sprite.rotate_z(angle)
	sprite.rotate_x(-hit)
	if mode=="stun": sprite.position.x+=sin(clock*40)*.055
