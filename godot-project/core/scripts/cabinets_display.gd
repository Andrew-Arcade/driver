extends VBoxContainer

@export var cabinet_scene: PackedScene

var _cabinet_nodes: Dictionary = {}
var _loading_label: Label

func _ready() -> void:
	ArcadeManager.cabinets_updated.connect(_on_cabinets_updated)
	_loading_label = Label.new()
	_loading_label.text = "Loading cabinets..."
	_loading_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_loading_label.add_theme_font_size_override("font_size", 18)
	add_child(_loading_label)

func _on_cabinets_updated() -> void:
	_loading_label.visible = ArcadeManager.is_loading

	# Add new cabinets
	for cabinet_name in ArcadeManager.cabinets:
		if not _cabinet_nodes.has(cabinet_name):
			var new_cabinet = cabinet_scene.instantiate()
			new_cabinet.cabinet_name = cabinet_name
			add_child(new_cabinet)
			_cabinet_nodes[cabinet_name] = new_cabinet

	# Remove cabinets no longer in the list
	for cabinet_name in _cabinet_nodes.keys():
		if not ArcadeManager.cabinets.has(cabinet_name):
			_cabinet_nodes[cabinet_name].queue_free()
			_cabinet_nodes.erase(cabinet_name)

	# Move loading label to end
	move_child(_loading_label, get_child_count() - 1)
