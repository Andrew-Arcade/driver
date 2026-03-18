extends Node

signal data_loaded(data: ArcadeData)

@export var url : String = "https://raw.githubusercontent.com/Andrew-Arcade/driver/main/arcade.json"

func _ready() -> void:
	_fetch_arcade()

func _fetch_arcade() -> void:
	var http_request = HTTPRequest.new()
	add_child(http_request)
	http_request.request_completed.connect(
		func(res, code, head, body): _http_request_completed(res, code, head, body, http_request)
	)
	http_request.request(url)

func _http_request_completed(_result, _response_code, _headers, body, request_node: HTTPRequest) -> void:
	request_node.queue_free()
	
	var response = JSON.parse_string(body.get_string_from_utf8())
	
	var arcade_data : ArcadeData = ArcadeData.new()
	arcade_data.arcade.assign(response)
	
	data_loaded.emit(arcade_data)
