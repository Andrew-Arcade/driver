extends VBoxContainer

@export var cabinet_scene: PackedScene

func _ready() -> void:
	ArcadeManager.cabinets_updated.connect(_on_cabinets_updated)

func _on_cabinets_updated() -> void:
	for child in get_children():
		child.queue_free()
	for cabinet_name in ArcadeManager.cabinets:
		var new_cabinet = cabinet_scene.instantiate()
		new_cabinet.cabinet_name = cabinet_name
		add_child(new_cabinet)
