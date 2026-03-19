extends Button

func _ready() -> void:
	self.pressed.connect(_on_pressed)

func _on_pressed() -> void:
	Log.info("Shutting down system...")
	CommandQueue.add("sudo /usr/bin/systemctl poweroff")
	get_tree().quit()
