extends Button

func _ready() -> void:
	self.pressed.connect(_on_pressed)

func _on_pressed() -> void:
	print("Shutting down system...")

	var output = []
	var exit_code = OS.execute("/usr/bin/sudo", ["/usr/bin/systemctl", "poweroff"], output)

	if exit_code == -1:
		print("Failed to execute shutdown command.")
