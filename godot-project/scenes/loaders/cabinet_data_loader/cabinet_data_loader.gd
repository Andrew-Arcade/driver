extends Node

signal data_loaded(data: Array[CabinetData])

func _ready() -> void:
	%ArcadeDataLoader.data_loaded.connect(_on_arcade_data_received)

func _on_arcade_data_received(data: ArcadeData) -> void:
	var cabinets: Array[CabinetData] = []
	
	for url in data.arcade:
		var raw_url = url.replace("github.com", "raw.githubusercontent.com") + "/main/cabinet.json"
		var result = await _fetch_cabinet(raw_url)
		if result:
			cabinets.append(result)
			
	data_loaded.emit(cabinets)

func _fetch_cabinet(url: String) -> CabinetData:
	var http = HTTPRequest.new()
	add_child(http)
	http.request(url)
	
	var response = await http.request_completed
	http.queue_free()
	
	if response[1] == 200:
		var json = JSON.parse_string(response[3].get_string_from_utf8())
		if json is Dictionary:
			var cab = CabinetData.new()
			cab.display_name = json.get("display_name", "Unknown")
			cab.developer = json.get("developer", "Unknown")
			cab.description = json.get("description", "")
			return cab
	return null
