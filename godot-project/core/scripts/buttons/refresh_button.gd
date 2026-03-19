extends Button

func _ready() -> void:
	pressed.connect(_on_pressed)

func _on_pressed() -> void:
	text = "Refreshing..."
	disabled = true
	await ArcadeManager.refresh()
	text = "Refresh"
	disabled = false
