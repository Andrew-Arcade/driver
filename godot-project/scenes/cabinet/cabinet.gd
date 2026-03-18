extends Control

@export var item_data : CabinetData 

@onready var icon_rect : TextureRect = %Icon
@onready var display_name_label : Label = %Title
@onready var developer_label : Label = %Developer
@onready var description_label : Label = %Description

func _ready():
	if item_data:
		load_data(item_data)

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
