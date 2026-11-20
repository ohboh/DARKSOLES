extends Node

@export_range(-40, 0, 1) var volume_db := -3.0
@export_range(0.0, 0.15, 0.01) var pitch_variation := 0.05
@export_range(0.0, 0.3, 0.01) var door_pitch_variation := 0.12
@export var event_levels := {"step": -21, "draw": -9, "swing": -12, "impact": -9, "block": -12, "parry": -8, "bash": -12, "hurt": -12, "death": -12, "door": -14, "chest": -13, "relic": -15, "heal": -16, "cast": -14, "fire_hit": -18, "choice": -20, "break": -12}
const SOUNDS = {
	"step": preload("res://addons/soundza_game_sfx_starter/footsteps/leather_boots_step_2.wav"),
	"draw": preload("res://addons/soundza_game_sfx_starter/swords_melee/sword_unsheathe_2.wav"),
	"swing": preload("res://addons/soundza_game_sfx_starter/whooshes_swings/quick_air_whoosh.wav"),
	"impact": preload("res://addons/soundza_game_sfx_starter/swords_melee/sword_hits_body.wav"),
	"block": preload("res://addons/soundza_game_sfx_starter/swords_melee/metal_armor_clank.wav"),
	"parry": preload("res://addons/soundza_game_sfx_starter/swords_melee/sword_clash_1.wav"),
	"bash": preload("res://addons/soundza_game_sfx_starter/swords_melee/weapon_swing_1.wav"),
	"hurt": preload("res://addons/soundza_game_sfx_starter/hits_impacts/deep_punch_thud.wav"),
	"death": preload("res://addons/soundza_game_sfx_starter/ui_menu/ominous_stinger.wav"),
	"door": preload("res://addons/soundza_game_sfx_starter/doors_switches/creaky_door_open.wav"),
	"chest": preload("res://addons/soundza_game_sfx_starter/doors_switches/key_lock_and_door_23.wav"),
	"relic": preload("res://addons/soundza_game_sfx_starter/pickups_powerups/coins_1.wav"),
	"heal": preload("res://addons/soundza_game_sfx_starter/magic/magical_heal_chime.wav"),
	"cast": preload("res://addons/soundza_game_sfx_starter/magic/fire_magic_fireball.wav"),
	"fire_hit": preload("res://addons/soundza_game_sfx_starter/explosions/fireball_explosion.wav"),
	"choice": preload("res://addons/soundza_game_sfx_starter/ui_menu/button_tick.wav"),
	"break": preload("res://addons/soundza_game_sfx_starter/doors_switches/break_crack_door.wav"),
}
@export var impact_sounds: Dictionary[String, AudioStream] = {
	"flesh": SOUNDS["impact"],
	"bone": preload("res://addons/soundza_game_sfx_starter/doors_switches/wood_door_knock.wav"),
	"slime": preload("res://addons/soundza_game_sfx_starter/hits_impacts/wet_impact_flesh_hit.wav"),
	"wood": preload("res://addons/soundza_game_sfx_starter/hits_impacts/woody_baseball_bonk.wav"),
	"metal": preload("res://addons/soundza_game_sfx_starter/swords_melee/short_metallic_impact_hit.wav"),
	"shield": preload("res://addons/soundza_game_sfx_starter/swords_melee/metal_armor_clank.wav"),
	"spectral": preload("res://addons/soundza_game_sfx_starter/magic/puff_of_smoke.wav"),
}
var voices: Array[AudioStreamPlayer] = []
var random := RandomNumberGenerator.new()
var cursor := 0
var previous_distance := 0.0
var step_distance := 0.0

func _ready():
	add_to_group("game_audio")
	random.randomize()
	for i in 8:
		var voice := AudioStreamPlayer.new()
		add_child(voice)
		voices.append(voice)

func play_impact(enemy):
	var sound: AudioStream = enemy.impact_sound
	if sound == null:
		sound = impact_sounds.get(enemy.impact_material, SOUNDS["impact"])
	play("impact", sound)

func play(event: String, override_sound: AudioStream = null):
	if not SOUNDS.has(event): return
	var voice := voices[cursor]
	for available in voices:
		if not available.playing:
			voice = available
			break
	cursor = (cursor + 1) % voices.size()
	voice.stream = override_sound if override_sound != null else SOUNDS[event]
	voice.volume_db = volume_db + float(event_levels.get(event, -12))
	var variation := door_pitch_variation if event == "door" else pitch_variation
	voice.pitch_scale = random.randf_range(1.0-variation, 1.0+variation)
	voice.play()

func reset():
	for voice in voices: voice.stop()
	previous_distance = 0.0
	step_distance = 0.0

func update_steps(distance: float, walking: bool, steps_per_tile: float):
	var travelled := maxf(0.0, distance-previous_distance)
	previous_distance = distance
	if not walking: return
	step_distance += travelled
	if step_distance >= 1.0 / steps_per_tile:
		step_distance = fmod(step_distance, 1.0 / steps_per_tile)
		play("step")
