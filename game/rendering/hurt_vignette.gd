extends ColorRect

@export_group("Heartbeat")
@export_range(30, 120, 1) var wounded_bpm := 58.0
@export_range(60, 160, 1) var critical_bpm := 108.0
var phase := 0.0

func update_health(remaining: int, capacity: int, impact: float, delta: float):
	var injury := clampf(1.0 - float(remaining) / maxi(1, capacity), 0.0, 1.0)
	visible = injury > 0.0 or impact > 0.0
	if not visible:
		phase = 0.0
		return
	phase = fmod(phase + delta * lerpf(wounded_bpm, critical_bpm, injury) / 60.0, 1.0)
	var first := exp(-pow((phase - 0.15) / 0.105, 2.0))
	var second := 0.48 * exp(-pow((phase - 0.41) / 0.095, 2.0))
	material.set_shader_parameter("injury", injury)
	material.set_shader_parameter("impact", clampf(impact / 0.45, 0.0, 1.0))
	material.set_shader_parameter("beat", first + second)
