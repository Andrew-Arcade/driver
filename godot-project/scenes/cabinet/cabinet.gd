extends Control

@export var cabinet_data : CabinetData 

@onready var icon_rect : TextureRect = %Icon
@onready var display_name_label : Label = %Title
@onready var developer_label : Label = %Developer
@onready var description_label : Label = %Description
@onready var install_button : TextureButton = %Install

func _ready():
	if cabinet_data:
		load_data(cabinet_data)
	install_button.pressed.connect(_on_install_pressed)

func _on_install_pressed():
	if not cabinet_data or cabinet_data.repo_url == "":
		Log.warn("No repo URL available for install.")
		return
	var repo_name = cabinet_data.repo_url.get_file()
	var install_path = "/andrewarcade/cabinets/" + repo_name
	Log.info("Installing " + cabinet_data.display_name + " to " + install_path)
	Shell.command("git clone " + cabinet_data.repo_url + " " + install_path)

func load_data(data: CabinetData):
	if display_name_label:
		display_name_label.text = data.display_name
	
	if developer_label:
		developer_label.text = "By: " + data.developer
		
	if description_label:
		description_label.text = data.description
	
	if icon_rect:
		if data.icon:
			icon_rect.texture = data.icon
		_apply_stretch(icon_rect, Vector2(128, 128))

func _apply_stretch(rect: TextureRect, _size: Vector2):
	rect.custom_minimum_size = _size
	rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	rect.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
