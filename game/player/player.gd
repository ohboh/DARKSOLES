extends Camera3D
@export_range(0.,20.,.5) var stair_look_down := 9.0
@export_range(.1,5,.1) var walking_speed := 1.6
@export_group("Combat feel")
@export_range(0.0, 0.15, 0.005) var hit_stop_duration := 0.045
@export_group("Player")
@export_range(1,50) var starting_health := 5
@export var guard_window := .7
@export var parry_window := .22
@export_range(1,20) var sword_damage := 1
@export_range(0,20) var bash_max_damage := 1
@export_range(.05,5,.05) var bash_stun := 1.3
@export_range(.05,5,.05) var parry_stun := 1.8
@export_range(1,20) var fireball_damage := 2
@export_range(.05,2,.01) var flight_duration := .28
@export_range(1,20) var flask_healing := 1
@export var cooldowns := {"Slash":.7,"Shield":1.3,"Sword Parry":1.2,"Shield Parry":1.2,"Shield Bash":2.0,"Fireball":4.5,"Mend":7.}
@export_range(0,20) var arm_loss_health := 2
@export_enum("Slash","Shield","Sword Parry","Shield Parry","Shield Bash","Mend","Fireball") var first_action := "Slash"
@export_enum("Slash","Shield","Sword Parry","Shield Parry","Shield Bash","Mend","Fireball") var second_action := "Shield"
@export_enum("Slash","Shield","Sword Parry","Shield Parry","Shield Bash","Mend","Fireball") var third_action := "Sword Parry"

func action_name(action: String) -> String:
	return {"Sword":"Slash", "Parry":"Sword Parry"}.get(action, action)

func action_cooldown(action: String) -> float:
	var legacy: String = {"Slash":"Sword", "Sword Parry":"Parry", "Shield Parry":"Parry"}.get(action, action)
	return float(cooldowns.get(action, cooldowns.get(legacy, 1.2)))
