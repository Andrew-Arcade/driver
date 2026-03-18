extends Node

func command(cmd: String) -> String:
	var output := PackedStringArray()
	var exit_code := OS.execute("/bin/sh", ["-c", cmd], output)
	
	var result := "\n".join(output)
	
	if exit_code != 0:
		GlobalLogger.warn("Command failed (%d): %s\n%s" % [exit_code, cmd, result])
	
	return result
