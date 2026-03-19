extends Node

signal all_cabinets_loaded(cabinets: Array[CabinetData])

var cached_cabinets: Array[CabinetData] = []
var is_loading: bool = false

func _ready() -> void:
	ArcadeDataManager.data_loaded.connect(_on_arcade_data_received)

func _on_arcade_data_received(data: ArcadeData) -> void:
	if is_loading: return
	is_loading = true
	
	var cabinets: Array[CabinetData] = []
	
	for url in data.arcade:
		var raw_url = url.replace("github.com", "raw.githubusercontent.com") + "/main/cabinet.json"
		var result = await _fetch_cabinet(raw_url)
		if result:
			cabinets.append(result)
	
	cached_cabinets = cabinets
	is_loading = false
	all_cabinets_loaded.emit(cached_cabinets)
	Log.info("Cabinet data cached.")


func _fetch_cabinet(url: String) -> CabinetData:
	var http = HTTPRequest.new()
	add_child(http)
	
	var error = http.request(url)
	if error != OK:
		http.queue_free()
		return null
		
	var response = await http.request_completed
	http.queue_free()
	
	if response[1] == 200:
		var body = response[3]
		var json = JSON.parse_string(body.get_string_from_utf8())
		if json is Dictionary:
			var cab = CabinetData.new()
			cab.display_name = json.get("display_name", "Unknown")
			cab.developer = json.get("developer", "Unknown")
			cab.description = json.get("description", "")
			return cab
			
	return null
