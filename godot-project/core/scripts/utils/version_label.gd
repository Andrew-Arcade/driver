extends Label

func _ready() -> void:
	text = "driver-v" + ProjectSettings.get_setting("application/config/version")
