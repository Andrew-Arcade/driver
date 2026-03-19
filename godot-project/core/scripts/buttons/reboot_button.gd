extends Button

func _ready() -> void:
	self.pressed.connect(_on_pressed)

func _on_pressed() -> void:
	Log.info("Rebooting system...")
	CommandQueue.add("sudo /usr/bin/systemctl reboot")
	get_tree().quit()
