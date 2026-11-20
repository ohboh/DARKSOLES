extends Node3D

# Unused exit assemblies are removed once, when the streaming system places this tile.
@export var door_variants: Array[PackedScene] = [preload("res://game/world/modules/doorway_2.tscn"), preload("res://game/world/modules/doorway_3.tscn")]
@export var door_scene:PackedScene=preload("res://game/world/modules/doorway.tscn")
@export var stairs_scene:PackedScene=preload("res://game/world/modules/descending_flight.tscn")
@export var omen_scene:PackedScene=preload("res://game/world/modules/route_omen.tscn")
var hinge:Node3D
var door_sounded := false

func configure(index:int, exits:Dictionary,terrain:String="hall",drop:float=1.05):
	for side in [-1,1]:
		var suffix="Left" if side<0 else "Right"
		var opening=exits.has(side)
		discard("Wall"+suffix if opening else "Exit"+suffix)
		if opening:
			get_node("Exit"+suffix).show()
			if exits[side]=="foe":
				# The unlit doorway still has a frame to navigate by.
				discard("Exit"+suffix+"/Sconce")
			get_node("Passage%d"%side).show()
		else: discard("Passage%d"%side)
	if exits.is_empty() or exits.has(0): discard("EndWall")
	else: $EndWall.show()
	if terrain!="hall" or not exits.is_empty() or index%3!=1: discard("Arch")
	if not exits.is_empty() or index%3!=0:
		discard("SconceLeft")
		discard("SconceRight")
	else:
		discard("SconceLeft" if index%2 else "SconceRight")

	for direction in exits:
		var axis=Vector3(direction,0,0) if direction!=0 else Vector3.FORWARD
		var hint=omen_scene.instantiate()
		add_child(hint)
		hint.position=axis*1.0+Vector3.UP*.018
		hint.rotation.y=-direction*PI*.5
		var kind=exits[direction]
		hint.material_override.set_shader_parameter("omen",2 if kind=="foe" else (1 if kind=="shrine" else 0))
	if terrain=="door":
		var candidates: Array[PackedScene] = [door_scene]
		candidates.append_array(door_variants)
		var doorway=candidates.pick_random().instantiate()
		add_child(doorway)
		hinge=doorway.get_node("Hinge")
	elif terrain=="stairs":
		discard("Deck/Flagstones")
		var flight=stairs_scene.instantiate()
		add_child(flight)
		flight.scale.y=drop
		$WallLeft.position.y-=drop
		$WallRight.position.y-=drop

func update_door(local_progress:float):
	var opening := smoothstep(-.65,.22,local_progress)
	hinge.rotation.y = -PI * .51 * opening
	if not door_sounded and opening > .01:
		door_sounded = true
		get_tree().call_group("game_audio", "play", "door")

func discard(child_name:String):
	var child=get_node(child_name)
	child.get_parent().remove_child(child)
	child.queue_free()

func append_lights(lights:Array[Vector3]):
	for marker in find_children("*","Marker3D",true,false):
		if marker.is_in_group("torch_sources"): lights.append(marker.global_position)
