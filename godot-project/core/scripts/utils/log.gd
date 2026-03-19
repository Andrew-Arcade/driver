extends Node

signal message_logged(message: String, type: int)

const INFO = 0
const WARNING = 1
const ERROR = 2

func info(msg: String) -> void:
	print(msg)
	message_logged.emit(msg, INFO)

func warn(msg: String) -> void:
	push_warning(msg)
	message_logged.emit(msg, WARNING)

func error(msg: String) -> void:
	push_error(msg)
	message_logged.emit(msg, ERROR)
