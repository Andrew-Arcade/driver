extends Node

func is_connected() -> bool:
	var http = HTTPRequest.new()
	add_child(http)

	var error = http.request("https://raw.githubusercontent.com/", PackedStringArray(), HTTPClient.METHOD_HEAD)
	if error != OK:
		http.queue_free()
		return false

	var response = await http.request_completed
	http.queue_free()

	return response[1] >= 200 and response[1] < 400
