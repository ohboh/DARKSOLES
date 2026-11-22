extends Node3D

## Probability that opening this chest reveals a hostile slime.
@export_range(0.0, 1.0, 0.01) var slime_ambush_chance := 0.12

@export var weapon_pool: Array[String] = ["sword", "shield"]
