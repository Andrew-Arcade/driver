extends Node

const QUEUE_PATH := "/tmp/andrewarcade-queue"

func add(cmd: String) -> void:
	var file := FileAccess.open(QUEUE_PATH, FileAccess.READ_WRITE)
	if file == null:
		file = FileAccess.open(QUEUE_PATH, FileAccess.WRITE)
	else:
		file.seek_end()
	file.store_line(cmd)
	file.close()
	Log.info("Queued: " + cmd)
