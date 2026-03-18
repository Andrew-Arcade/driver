extends Button

func _ready() -> void:
	self.pressed.connect(_on_pressed)

func _on_pressed() -> void:
	print("Rebooting system...")

	var output = []
	var exit_code = OS.execute("/usr/bin/dbus-send", [
		"--system", "--print-reply",
		"--dest=org.freedesktop.login1",
		"/org/freedesktop/login1",
		"org.freedesktop.login1.Manager.Reboot",
		"boolean:false",
	], output)

	if exit_code == -1:
		print("Failed to execute reboot command.")
