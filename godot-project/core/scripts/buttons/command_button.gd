extends BaseButton

@export var log_message: String
@export var dim_when_idle: bool = false
@export var hover_color: Color = Color(1.2, 1.2, 1.2, 1.0)

var _dim_color := Color(0.498, 0.498, 0.498, 1.0)
var _bright_color := Color(1.0, 1.0, 1.0, 1.0)

func _ready() -> void:
	pressed.connect(_on_pressed)
	if dim_when_idle:
		modulate = _dim_color
		mouse_entered.connect(func(): modulate = _bright_color)
		mouse_exited.connect(func(): modulate = _dim_color)
	else:
		mouse_entered.connect(func(): modulate = hover_color)
		mouse_exited.connect(func(): modulate = _bright_color)

func _on_pressed() -> void:
	if log_message:
		Log.info(log_message)
	if dim_when_idle:
		modulate = _dim_color
	_execute()

func _execute() -> void:
	pass
