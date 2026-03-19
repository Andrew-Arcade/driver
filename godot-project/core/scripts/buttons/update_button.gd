extends "icon_button.gd"

func _execute() -> void:
	CommandQueue.add("cd /andrewarcade/driver && git fetch origin main && git reset --hard origin/main")
	CommandQueue.add("sudo /andrewarcade/driver/scripts/launch.sh")
	await get_tree().process_frame
	get_tree().quit()
