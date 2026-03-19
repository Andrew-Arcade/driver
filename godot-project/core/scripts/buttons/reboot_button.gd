extends "icon_button.gd"

func _execute() -> void:
	CommandQueue.add("sudo /usr/bin/systemctl reboot")
	get_tree().quit()
