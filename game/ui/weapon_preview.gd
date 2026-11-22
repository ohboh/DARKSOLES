extends SubViewportContainer
var current_kind := ""
var pivot: Node3D

func _ready():
	mouse_filter=Control.MOUSE_FILTER_IGNORE
	var viewport := SubViewport.new()
	viewport.size=Vector2i(300,400)
	viewport.transparent_bg=true
	viewport.gui_disable_input=true
	viewport.own_world_3d=true
	viewport.render_target_update_mode=SubViewport.UPDATE_WHEN_VISIBLE
	add_child(viewport)
	pivot=Node3D.new()
	viewport.add_child(pivot)
	var camera:=Camera3D.new()
	camera.position=Vector3(0,0,1)
	camera.projection=Camera3D.PROJECTION_ORTHOGONAL
	camera.size=.55
	viewport.add_child(camera)

func show_weapon(kind: String):
	if kind==current_kind: return
	current_kind=kind
	pivot.rotation.y=PI/2 if kind=="shield" else 0.
	for child in pivot.get_children():
		pivot.remove_child(child)
		child.queue_free()
	var source=preload("res://art/models/weapons_runtime.glb").instantiate()
	var mesh_name="Sword" if kind=="sword" else "Shield"
	for mesh in source.find_children("*","MeshInstance3D"):
		if mesh.name!=mesh_name: continue
		var model:=MeshInstance3D.new()
		model.mesh=mesh.mesh
		model.position=-mesh.get_aabb().get_center()
		var mat:=ShaderMaterial.new()
		mat.shader=preload("res://game/rendering/shaders/preview.gdshader")
		mat.set_shader_parameter("atlas",mesh.get_active_material(0).albedo_texture)
		var outline:=ShaderMaterial.new()
		outline.shader=preload("res://game/rendering/shaders/contour.gdshader")
		mat.next_pass=outline
		model.material_override=mat
		pivot.add_child(model)
	source.free()

func _process(delta):
	if visible and pivot: pivot.rotation.y+=delta*.65
