extends Node

func _shutdown() -> void:
	GlobalLogger.info("Shutting down system...")
	
	var output = []
	var exit_code = OS.execute("/usr/bin/sudo", ["/usr/bin/systemctl", "poweroff"], output)
	
	if exit_code == -1: GlobalLogger.error("Failed to execute shutdown command.")

func _reboot() -> void:
	GlobalLogger.info("Rebooting system...")
	
	Shell.command("/usr/bin/sudo /usr/bin")

	var output = []
	var exit_code = OS.execute("/usr/bin/sudo", ["/usr/bin/systemctl", "reboot"], output)

	if exit_code == -1: GlobalLogger.error("Failed to execute reboot command.")

func _update() -> void:
	GlobalLogger.info("Updating driver...")
	OS.create_process("/bin/bash", ["-c", "sleep 3 && /andrewarcade/driver/scripts/launch.sh"])
	get_tree().quit()
