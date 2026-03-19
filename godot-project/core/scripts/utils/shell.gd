extends Node

func command(cmd: String) -> String:
	Log.info("$ " + cmd)
	var output := PackedStringArray()
	var exit_code := OS.execute("/bin/sh", ["-c", cmd], output)

	var result := "\n".join(output)

	if result != "":
		Log.info(result)
	if exit_code != 0:
		Log.warn("Exit code: %d" % exit_code)

	return result
