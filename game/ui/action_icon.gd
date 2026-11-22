extends Control

var action := "Sword":
	set(value):
		if action!=value:
			action=value
			queue_redraw()

func _draw():
	draw_set_transform(size*.5,0,Vector2.ONE)
	var col=Color.WHITE
	match action:
		"Slash","Sword","Sword Parry","Parry":
			for d in ([-1,1] if action in ["Parry","Sword Parry"] else [1]):
				draw_line(Vector2(-10*d,13),Vector2(11*d,-16),col,3)
				draw_line(Vector2(-13*d,2),Vector2(0,11),col,3)
		"Shield","Shield Bash","Shield Parry":
			draw_polyline(PackedVector2Array([Vector2(-13,-12),Vector2(13,-12),Vector2(11,4),Vector2(0,16),Vector2(-11,4),Vector2(-13,-12)]),col,3)
		"Fireball":
			draw_colored_polygon(PackedVector2Array([Vector2(-9,4),Vector2(4,-17),Vector2(10,3),Vector2(0,12)]),col)
		_:
			draw_polyline(PackedVector2Array([Vector2(0,-15),Vector2(11,0),Vector2(0,15),Vector2(-11,0),Vector2(0,-15)]),col,3)
