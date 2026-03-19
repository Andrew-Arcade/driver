extends "command_button.gd"

func _execute() -> void:
	CommandQueue.add("sudo /usr/bin/systemctl poweroff")
	get_tree().quit()
