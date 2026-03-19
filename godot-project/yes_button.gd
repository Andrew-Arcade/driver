extends Button

func _ready() -> void:
	self.pressed.connect(_on_pressed)

func _on_pressed() -> void:
	CommandQueue.add("yes")
	CommandQueue.add("sudo /andrewarcade/driver/scripts/launch.sh")
	get_tree().quit()
