extends Control

@export var cabinet_data : CabinetData 

@onready var icon_rect : TextureRect = %Icon
@onready var display_name_label : Label = %Title
@onready var developer_label : Label = %Developer
@onready var description_label : Label = %Description
@onready var install_button : TextureButton = %Install
@onready var remove_button : TextureButton = %Remove
@onready var update_button : TextureButton = %Update

func _ready():
	if cabinet_data:
		load_data(cabinet_data)
	install_button.pressed.connect(_on_install_pressed)
	remove_button.pressed.connect(_on_remove_pressed)
	update_button.pressed.connect(_on_update_pressed)

func _on_install_pressed():
	if not cabinet_data or cabinet_data.repo_url == "":
		Log.warn("No repo URL available for install.")
		return
	var install_path = _get_install_path()
	Log.info("Installing " + cabinet_data.display_name + " to " + install_path)
	Shell.command("git clone " + cabinet_data.repo_url + " " + install_path)
	_update_buttons()

func _on_update_pressed():
	var path = _get_install_path()
	Log.info("Updating " + cabinet_data.display_name)
	Shell.command("git -C " + path + " pull")
	_update_buttons()

func _on_remove_pressed():
	if not cabinet_data:
		return
	var install_path = _get_install_path()
	Log.info("Removing " + cabinet_data.display_name + " from " + install_path)
	Shell.command("rm -rf " + install_path)
	_update_buttons()

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

	_update_buttons()

func _get_install_path() -> String:
	var repo_name = cabinet_data.repo_url.get_file()
	return "/andrewarcade/cabinets/" + repo_name

func _has_update() -> bool:
	var path = _get_install_path()
	if not DirAccess.dir_exists_absolute(path):
		return false
	Shell.command("git -C " + path + " fetch")
	var local = Shell.command("git -C " + path + " rev-parse HEAD").strip_edges()
	var remote = Shell.command("git -C " + path + " rev-parse @{u}").strip_edges()
	return local != remote

func _update_buttons():
	if cabinet_data:
		var installed = DirAccess.dir_exists_absolute(_get_install_path())
		if install_button:
			install_button.visible = not installed
		if remove_button:
			remove_button.visible = installed
		if update_button:
			update_button.visible = installed and _has_update()

func _apply_stretch(rect: TextureRect, _size: Vector2):
	rect.custom_minimum_size = _size
	rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	rect.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
