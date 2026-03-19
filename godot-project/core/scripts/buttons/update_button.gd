extends Button

func _ready() -> void:
	self.pressed.connect(_on_pressed)

func _on_pressed() -> void:
	Log.info("Updating driver...")
	CommandQueue.add("cd /andrewarcade/driver && git pull origin main")
	CommandQueue.add("sudo /andrewarcade/driver/scripts/launch.sh")
	await get_tree().process_frame
	get_tree().quit()
