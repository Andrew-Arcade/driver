extends Node

func command(cmd: String) -> String:
	GlobalLogger.info("$ " + cmd)
	var output := PackedStringArray()
	var exit_code := OS.execute("/bin/sh", ["-c", cmd], output)

	var result := "\n".join(output)

	if result != "":
		GlobalLogger.info(result)
	if exit_code != 0:
		GlobalLogger.warn("Exit code: %d" % exit_code)

	return result
