extends Node3D
## Static copies of one mesh and material. Keep the source nodes editable in the scene.
@export var batch_sources: Array[NodePath] = []

func _ready() -> void:
	var sources: Array[MeshInstance3D] = []
	for path in batch_sources:
		var source := get_node_or_null(path) as MeshInstance3D
		if not source or not source.mesh or not source.visible:
			return
		if not sources.is_empty() and (source.mesh != sources[0].mesh or source.material_override != sources[0].material_override):
			return
		sources.append(source)
	if sources.size() < 2:
		return

	var instances := MultiMesh.new()
	instances.transform_format = MultiMesh.TRANSFORM_3D
	instances.mesh = sources[0].mesh
	instances.instance_count = sources.size()
	for i in sources.size():
		var relative := sources[i].transform
		var ancestor := sources[i].get_parent() as Node3D
		while ancestor != self:
			relative = ancestor.transform * relative
			ancestor = ancestor.get_parent() as Node3D
		instances.set_instance_transform(i, relative)

	var batch := MultiMeshInstance3D.new()
	batch.name = "StaticInstances"
	batch.multimesh = instances
	batch.material_override = sources[0].material_override
	add_child(batch)
	for source in sources:
		source.hide()
