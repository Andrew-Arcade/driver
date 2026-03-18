extends Node

signal data_loaded(data: ArcadeData)

var cached_data: ArcadeData = null
var is_loading: bool = false

@export var url : String = "https://raw.githubusercontent.com/Andrew-Arcade/driver/main/arcade.json"

func _ready() -> void:
	fetch_arcade()

func fetch_arcade() -> void:
	if is_loading: return
	is_loading = true
	
	var http_request = HTTPRequest.new()
	add_child(http_request)
	http_request.request_completed.connect(
		func(res, code, head, body): _http_request_completed(res, code, head, body, http_request)
	)
	http_request.request(url)

func _http_request_completed(_result, _response_code, _headers, body, request_node: HTTPRequest) -> void:
	request_node.queue_free()
	
	var response = JSON.parse_string(body.get_string_from_utf8())
	
	cached_data = ArcadeData.new()
	cached_data.arcade.assign(response)
	
	is_loading = false
	data_loaded.emit(cached_data)
	GlobalLogger.info("Arcade Data Globally Loaded!")
