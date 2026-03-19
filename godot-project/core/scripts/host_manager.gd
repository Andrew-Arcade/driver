extends Node

func _shutdown() -> void:
	GlobalLogger.info("Shutting down system...")
	CommandQueue.add("sudo /usr/bin/systemctl poweroff")
	get_tree().quit()

func _reboot() -> void:
	GlobalLogger.info("Rebooting system...")
	CommandQueue.add("sudo /usr/bin/systemctl reboot")
	get_tree().quit()

func _update() -> void:
	GlobalLogger.info("Updating driver...")
	CommandQueue.add("cd /andrewarcade/driver && git pull origin main")
	CommandQueue.add("sudo /andrewarcade/driver/scripts/launch.sh")
	await get_tree().process_frame
	get_tree().quit()
