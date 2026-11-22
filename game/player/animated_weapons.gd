extends Node3D
signal strike(action: StringName, hand: int)
@export var steps_per_tile := 1.6
@onready var rigs = [$Right, $Left]
var equipped := ["sword", "shield"]
var active_hand := 0
var intro_stage: int:
	get: return maxi($Right.intro_stage, $Left.intro_stage)

func _ready():
	for hand in 2:
		rigs[hand].strike.connect(func(action): strike.emit(action, hand))
	configure(equipped)

func configure(kinds: Array):
	equipped = kinds.duplicate()
	for hand in 2:
		rigs[hand].weapon_kind = equipped[hand]
		var mirrored: bool = (hand == 1 and equipped[hand] == "sword") or (hand == 0 and equipped[hand] == "shield")
		rigs[hand].scale.x = -1 if mirrored else 1
		rigs[hand].rest_transform = rigs[hand].transform
		rigs[hand].reset_playback()

func cue(action: StringName, has_left: bool):
	if active_hand == 1 and not has_left: return
	rigs[active_hand].cue(action, true)

func start_run():
	for rig in rigs: rig.start_run()

func reset_playback():
	for rig in rigs: rig.reset_playback()

func set_playback_speed(speed: float):
	for rig in rigs: rig.set_playback_speed(speed)

func animate(run, dt):
	for hand in 2:
		rigs[hand].visible = hand == 0 or run.arm
		rigs[hand].steps_per_tile = steps_per_tile
		rigs[hand].animate(run, dt)
