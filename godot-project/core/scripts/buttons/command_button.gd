extends BaseButton

@export var log_message: String
@export var outline_color := Color(0.0, 0.0, 0.0, 1.0)
@export var hover_outline_color := Color(0.25, 0.25, 0.25, 1.0)
@export var pressed_outline_color := Color(0.5, 0.5, 0.5, 1.0)

func _ready() -> void:
	pressed.connect(_on_pressed)
	mouse_entered.connect(func(): _set_outline_color(hover_outline_color))
	mouse_exited.connect(func(): _set_outline_color(outline_color))

func _on_pressed() -> void:
	if log_message:
		Log.info(log_message)
	_set_outline_color(pressed_outline_color)
	_execute()

func _set_outline_color(color: Color) -> void:
	if material is ShaderMaterial:
		material.set_shader_parameter("outline_color", color)

func _execute() -> void:
	pass
