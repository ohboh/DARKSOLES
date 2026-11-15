extends "res://game/enemies/enemy.gd"

@export_range(0.,.35,.01) var squash := .17
func animate(dt:float,clock:float):
	super.animate(dt,clock)
	var compression=squash*(1.-timer/dur) if mode=="wind" else .035*(.5+.5*sin(clock*3.))
	sprite.scale.x=rest_pose.basis.get_scale().x*(1.+compression)
	sprite.scale.y=rest_pose.basis.get_scale().y*(1.-compression)
	sprite.position.y=rest_pose.origin.y*(1.-compression)
