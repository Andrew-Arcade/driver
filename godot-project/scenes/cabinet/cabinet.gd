extends Control

var cabinet_name: String

@onready var icon_rect: TextureRect = %Icon
@onready var display_name_label: Label = %Title
@onready var developer_label: Label = %Developer
@onready var description_label: Label = %Description
@onready var install_button: Button = %Install
@onready var remove_button: Button = %Remove
@onready var update_button: Button = %Update
@onready var launch_button: Button = %Launch

func _ready():
	install_button.pressed.connect(_on_install_pressed)
	remove_button.pressed.connect(_on_remove_pressed)
	update_button.pressed.connect(_on_update_pressed)
	launch_button.pressed.connect(_on_launch_pressed)
	ArcadeManager.cabinets_updated.connect(_refresh_display)
	_refresh_display()

func _refresh_display() -> void:
	if cabinet_name == "" or not ArcadeManager.cabinets.has(cabinet_name):
		return
	var entry: Dictionary = ArcadeManager.cabinets[cabinet_name]
	if display_name_label:
		display_name_label.text = entry.get("display_name", cabinet_name)
	if developer_label:
		developer_label.text = "By: " + entry.get("developer", "Unknown")
	if description_label:
		description_label.text = entry.get("description", "")
	if icon_rect:
		if entry.get("icon") != null:
			icon_rect.texture = entry["icon"]
		_apply_stretch(icon_rect, Vector2(128, 128))
	_update_buttons(entry)

func _update_buttons(entry: Dictionary) -> void:
	var status: int = entry.get("status", ArcadeManager.CabinetStatus.NOT_INSTALLED)
	var installed = status != ArcadeManager.CabinetStatus.NOT_INSTALLED
	if install_button:
		install_button.visible = not installed
		install_button.disabled = false
		install_button.text = "Install"
	if remove_button:
		remove_button.visible = installed
		remove_button.disabled = false
		remove_button.text = "Remove"
	if update_button:
		update_button.visible = status == ArcadeManager.CabinetStatus.UPDATE_AVAILABLE
		update_button.disabled = false
		update_button.text = "Update"
	if launch_button:
		launch_button.visible = installed

func _on_install_pressed():
	install_button.text = "Installing..."
	install_button.disabled = true
	await ArcadeManager.install_cabinet(cabinet_name)

func _on_remove_pressed():
	remove_button.text = "Removing..."
	remove_button.disabled = true
	await ArcadeManager.remove_cabinet(cabinet_name)

func _on_update_pressed():
	update_button.text = "Updating..."
	update_button.disabled = true
	await ArcadeManager.update_cabinet(cabinet_name)

func _on_launch_pressed():
	ArcadeManager.launch_cabinet(cabinet_name)

func _apply_stretch(rect: TextureRect, _size: Vector2):
	rect.custom_minimum_size = _size
	rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	rect.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
