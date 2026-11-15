extends Node3D
signal geometry_changed
@export_group("Encounters")
## Distance in corridor tiles at which the player stops and combat begins. One tile is 3 world units.
@export_range(0.25, 3.0, 0.05) var enemy_encounter_range := 1.0
@export var skeleton_scene: PackedScene = preload("res://game/enemies/skeleton.tscn")
@export var slime_scene: PackedScene = preload("res://game/enemies/slime.tscn")
@export_range(0,1,.01) var slime_chance := .22
@export var wraith_scene: PackedScene = preload("res://game/enemies/wraith.tscn")
@export var treasure_scene: PackedScene = preload("res://game/encounters/treasure_chest.tscn")
@export var shrine_scene: PackedScene = preload("res://game/encounters/shrine.tscn")
@export_range(0,1,.01) var skeleton_chance := .45
@export_group("Dungeon")
@export var corridor_scene: PackedScene = preload("res://game/world/corridor.tscn")
@export_range(0,1,.01) var roaming_enemy_chance := .17
@export_range(4,40) var first_junction := 9
@export_range(5,40) var lookahead := 12
@export var junction_spacing := Vector2i(8,12)
@export_group("Transitions")
@export var transition_spacing := Vector2i(6,11)
@export_range(.45,1.5,.05) var stair_drop := 1.05
var initial_transition := 5
## Number of consecutive three-metre sections in one descending staircase.
@export_range(2,8) var stair_sections := 3
@export_range(12,100) var minimum_stair_spacing := 27
@export_range(0,1,.01) var stairs_behind_door_chance := .28
@export_range(0,1,.01) var standalone_stairs_chance := .08
var tiles={}
var tail=0
var next_j=9
var last_foe=-9
var plan=[]
func reset():
	for tile in tiles.values(): tile.node.queue_free()
	tiles.clear()
	tail=0
	last_foe=-9
	next_j=first_junction
	initial_transition=randi_range(5,8)
	plan=[]

func branch(junction:int,kind:String,outgoing:Dictionary):
	for index in tiles.keys():
		if index>junction:
			outgoing[index]=tiles[index]
			tiles.erase(index)
	plan=reward(kind)
	tail=junction+1
	last_foe=-9

func reward(kind):
	return ["","","foe"] if kind=="foe" else ["",kind]
func generate(p:float,heading:float,position_at:Callable):
	while tail<=p+lookahead:
		if tiles.has(tail-1):
			var prev=tiles[tail-1]
			if not prev.done and prev.paths.size() and not prev.paths.has(0): break
		var n=tail
		tail+=1
		geometry_changed.emit()
		var node=corridor_scene.instantiate()
		add_child(node)
		node.position=position_at.call(n+.5)
		node.rotation.y=heading
		var previous=tiles.get(n-1,{})
		if not previous.is_empty():
			node.position.y=previous.exit_height
		var due=previous.get("next_transition",initial_transition)
		var remaining:int=previous.get("stairs_remaining",0)
		var stair_due:int=previous.get("stair_due",12)
		var t={"terrain":"hall","exit_height":node.position.y,"next_transition":due,"stairs_remaining":0,"stair_due":stair_due,"node":node,"paths":{},"done":false,"kind":"","dead":false}
		tiles[n]=t
		if remaining>0:
			t.terrain="stairs"
			t.stairs_remaining=remaining-1
		elif plan.size(): t.kind=plan.pop_front()
		elif n>=next_j:
			var r=randf()
			var dirs=[-1,1] if r<.4 else ([-1,0] if r<.58 else ([0,1] if r<.76 else ([-1,0,1] if r<.88 else [[-1,1].pick_random()])))
			var pool=["foe","shrine","relic"]
			pool.shuffle()
			for d in dirs:
				var roll=randf()
				t.paths[d]=pool.pop_back() if dirs.size()>1 else ("foe" if roll<.45 else ("shrine" if roll<.70 else "relic"))
			if t.paths.has(0): plan=reward(t.paths[0])
			next_j=n+randi_range(junction_spacing.x,junction_spacing.y)
		elif n>=due:
			var eligible=n>=stair_due
			var standalone=eligible and randf()<standalone_stairs_chance
			t.terrain="stairs" if standalone else "door"
			if standalone or (eligible and randf()<stairs_behind_door_chance):
				t.stairs_remaining=stair_sections-1 if standalone else stair_sections
				t.stair_due=n+t.stairs_remaining+1+minimum_stair_spacing
			t.next_transition=n+t.stairs_remaining+randi_range(maxi(4,transition_spacing.x),maxi(4,maxi(transition_spacing.x,transition_spacing.y)))
		elif previous.get("terrain","hall")!="stairs" and n>3 and n>last_foe+4 and randf()<roaming_enemy_chance: t.kind="foe"
		if t.terrain=="stairs": t.exit_height-=stair_drop
		node.configure(n,t.paths,t.terrain,stair_drop)
		match t.kind:
			"foe":
				last_foe=n
				var roll=randf()
				var scene=slime_scene if roll<slime_chance else (skeleton_scene if roll<slime_chance+(1.-slime_chance)*skeleton_chance else wraith_scene)
				t.obj=scene.instantiate()
				node.add_child(t.obj)
				t.obj.start_encounter(p)
			"shrine","relic":
				var scene=shrine_scene if t.kind=="shrine" else treasure_scene
				t.obj=scene.instantiate()
				node.add_child(t.obj)


func walking_height(distance:float) -> float:
	var index=floori(distance)
	var tile=tiles[index]
	return lerpf(tile.node.position.y,tile.exit_height,clampf(distance-index,0.,1.))

func update_doors(distance:float):
	for index in range(floori(distance)-1,floori(distance)+2):
		var tile=tiles.get(index)
		if tile and tile.terrain=="door":
			tile.node.update_door(distance-index)
