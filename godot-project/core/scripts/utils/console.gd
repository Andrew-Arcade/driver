extends Control

func _ready() -> void:
	Log.message_logged.connect(_on_message_logged)
	Log.info("Console ready!")

func _on_message_logged(message: String, type: int):
	var color = "white"
	
	match type:
		1: color = "yellow"
		2: color = "red"
		3: color = "cyan"
	
	var formatted_msg = "[color=%s]%s[/color]\n" % [color, message]
	%Log.append_text(formatted_msg)
