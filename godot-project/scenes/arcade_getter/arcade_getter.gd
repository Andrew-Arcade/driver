extends Control

@onready var http_request : HTTPRequest = %HTTPRequest
@onready var item_list : ItemList = %ItemList

func _ready() -> void:
	# Ensure the signal is connected only once
	http_request.request_completed.connect(self._http_request_completed)
	
	var error = http_request.request("https://raw.githubusercontent.com/Andrew-Arcade/driver/main/arcade.json")
	if error != OK:
		item_list.add_item("An error occurred in the HTTP request.")

func _http_request_completed(_result, response_code, _headers, body):
	if response_code != 200:
		item_list.add_item("Error: Server returned code " + str(response_code))
		return

	# Use the static parse_string for a cleaner Godot 4 approach
	var response = JSON.parse_string(body.get_string_from_utf8())
	
	if response == null:
		item_list.add_item("Error: Could not parse JSON.")
		return

	item_list.clear() # Clear "Loading..." messages

	# Logic to handle different JSON structures:
	if response is Array:
		for item in response:
			# If it's an array of strings, add it directly.
			# If it's an array of dicts, choose a key (e.g., item["name"])
			item_list.add_item(str(item))
			
	elif response is Dictionary:
		for key in response.keys():
			var val = response[key]
			item_list.add_item(str(key) + ": " + str(val))
