extends TextureRect

func _ready():
	expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	stretch_mode = TextureRect.STRETCH_SCALE

func _process(_delta):
	if size.x != size.y:
		size.x = size.y
