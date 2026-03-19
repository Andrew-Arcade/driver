extends BaseButton

func _ready() -> void:
	self.pressed.connect(_on_pressed)

func _on_pressed() -> void:
	Log.info("Quitting...")
	get_tree().quit()
