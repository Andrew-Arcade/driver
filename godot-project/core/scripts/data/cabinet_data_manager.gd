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
		var base_raw_url = url.replace("github.com", "raw.githubusercontent.com") + "/main/"
		var cache_bust = "?t=" + str(int(Time.get_unix_time_from_system()))
		var result = await _fetch_cabinet(base_raw_url + "cabinet.json" + cache_bust)
		if result:
			if result.icon_path != "":
				var encoded_path = "/".join(Array(result.icon_path.split("/")).map(func(s): return s.uri_encode()))
				result.icon = await _fetch_icon(base_raw_url + encoded_path + cache_bust)
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
			cab.icon_path = json.get("icon", "")
			return cab

	return null


func _fetch_icon(url: String) -> Texture2D:
	var http = HTTPRequest.new()
	add_child(http)

	var error = http.request(url)
	if error != OK:
		http.queue_free()
		return null

	var response = await http.request_completed
	http.queue_free()

	if response[1] != 200:
		return null

	var body: PackedByteArray = response[3]
	var image = Image.new()

	var base_url = url.split("?")[0]
	if base_url.ends_with(".png"):
		error = image.load_png_from_buffer(body)
	elif base_url.ends_with(".jpg") or base_url.ends_with(".jpeg"):
		error = image.load_jpg_from_buffer(body)
	elif base_url.ends_with(".webp"):
		error = image.load_webp_from_buffer(body)
	elif base_url.ends_with(".svg"):
		error = image.load_svg_from_buffer(body)
	else:
		error = image.load_png_from_buffer(body)

	if error != OK:
		return null

	return ImageTexture.create_from_image(image)
