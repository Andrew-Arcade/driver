extends Control

# Configuration
@export var max_lines: int = 50
@export var font_size: int = 14

var log_display: RichTextLabel

func _ready() -> void:
	_setup_ui()
	
	# This is the magic part: hooking into the message logging system
	# Note: This captures print() and push_error() calls
	GlobalLogger.message_logged.connect(_on_message_logged)

func _setup_ui():
	# Create the RichTextLabel dynamically if it doesn't exist
	log_display = RichTextLabel.new()
	log_display.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	log_display.scroll_following = true # Auto-scroll to bottom
	log_display.bbcode_enabled = true
	log_display.add_theme_font_size_override("normal_font_size", font_size)
	
	# Make it look like a console (semi-transparent black)
	var bg = ColorRect.new()
	bg.color = Color(0, 0, 0, 0.5)
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	
	add_child(bg)
	add_child(log_display)

func _on_message_logged(message: String, type: int):
	var color = "white"
	
	# Match log types to colors
	match type:
		1: color = "yellow" # Warning
		2: color = "red"    # Error
		3: color = "cyan"   # Script error
	
	var formatted_msg = "[color=%s]%s[/color]\n" % [color, message]
	log_display.append_text(formatted_msg)
	
	# Optional: Keep the log from growing infinitely
	if log_display.get_line_count() > max_lines:
		# Simple way to trim: clear and keep recent (though append is faster)
		pass
