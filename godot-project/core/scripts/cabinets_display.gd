extends VBoxContainer

@export var cabinet_scene: PackedScene

func _ready() -> void:
	%CabinetDataLoader.data_loaded.connect(_on_cabinet_data_loaded)

func _on_cabinet_data_loaded(data: Array[CabinetData]) -> void:
	for cabinet in data:
		create_cabinet(cabinet)

func create_cabinet(data : CabinetData):
	var new_cabinet = cabinet_scene.instantiate()
	new_cabinet.cabinet_data = data
	
	add_child(new_cabinet)
