extends Node

func _shutdown() -> void:
	GlobalLogger.info("Shutting down system...")
	
	var output = []
	var exit_code = OS.execute("/usr/bin/sudo", ["/usr/bin/systemctl", "poweroff"], output)
	
	if exit_code == -1: GlobalLogger.error("Failed to execute shutdown command.")

func _reboot() -> void:
	GlobalLogger.info("Rebooting system...")
	
	var output = []
	var exit_code = OS.execute("/usr/bin/sudo", ["/usr/bin/systemctl", "reboot"], output)

	if exit_code == -1: GlobalLogger.error("Failed to execute reboot command.")

func _update() -> void:
	GlobalLogger.info("Updating driver...")
	Shell.command("cd /andrewarcade/driver && git pull origin main 2>&1")
	GlobalLogger.info("Relaunching driver...")
	await get_tree().process_frame
	OS.create_process("/usr/bin/setsid", ["bash", "-c", "sleep 3 && /andrewarcade/driver/scripts/launch.sh"])
	get_tree().quit()
