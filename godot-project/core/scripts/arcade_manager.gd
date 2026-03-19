extends Node

signal cabinets_updated

enum CabinetStatus { INSTALLED, UPDATE_AVAILABLE, NOT_INSTALLED }

const CABINETS_DIR := "/andrewarcade/cabinets"
const CACHE_DIR := "/andrewarcade/cache"
const CACHE_FILE := "/andrewarcade/cache/arcade.json"
const ICONS_DIR := "/andrewarcade/cache/icons"
const ARCADE_JSON_URL := "https://raw.githubusercontent.com/Andrew-Arcade/driver/main/arcade.json"

var cabinets: Dictionary = {}
var is_busy: bool = false
var is_loading: bool = false

func _ready() -> void:
	await _initialize()

func _initialize() -> void:
	is_loading = true
	DirAccess.make_dir_recursive_absolute(CABINETS_DIR)
	DirAccess.make_dir_recursive_absolute(ICONS_DIR)
	_scan_installed()
	cabinets_updated.emit()
	_load_cache()
	cabinets_updated.emit()
	if await Network.is_connected():
		await _fetch_remote()
	is_loading = false
	cabinets_updated.emit()
	Log.info("Arcade manager initialized.")

func refresh() -> void:
	if is_busy:
		return
	is_busy = true
	is_loading = true
	Log.info("Refreshing...")
	_scan_installed()
	cabinets_updated.emit()
	if await Network.is_connected():
		await _fetch_remote()
	else:
		_load_cache()
		cabinets_updated.emit()
		Log.warn("Offline — showing cached data.")
	is_loading = false
	cabinets_updated.emit()
	is_busy = false

func _scan_installed() -> void:
	var dir = DirAccess.open(CABINETS_DIR)
	if dir == null:
		return
	dir.list_dir_begin()
	var folder = dir.get_next()
	while folder != "":
		if dir.current_is_dir() and not folder.begins_with("."):
			if not cabinets.has(folder):
				cabinets[folder] = _empty_entry(folder)
			cabinets[folder]["status"] = CabinetStatus.INSTALLED
		folder = dir.get_next()
	dir.list_dir_end()

func _load_cache() -> void:
	if not FileAccess.file_exists(CACHE_FILE):
		return
	var file = FileAccess.open(CACHE_FILE, FileAccess.READ)
	if file == null:
		return
	var json = JSON.parse_string(file.get_as_text())
	file.close()
	if json is not Dictionary:
		return
	for folder_name in json:
		var cached: Dictionary = json[folder_name]
		if not cabinets.has(folder_name):
			cabinets[folder_name] = _empty_entry(folder_name)
			cabinets[folder_name]["status"] = CabinetStatus.NOT_INSTALLED
		var entry: Dictionary = cabinets[folder_name]
		for key in cached:
			if key != "status" and key != "icon":
				entry[key] = cached[key]
		# Load cached icon from disk
		var icon_file = ICONS_DIR + "/" + folder_name + ".png"
		if FileAccess.file_exists(icon_file):
			var image = Image.new()
			if image.load(icon_file) == OK:
				entry["icon"] = ImageTexture.create_from_image(image)

func _save_cache() -> void:
	var cache_data: Dictionary = {}
	for folder_name in cabinets:
		var entry: Dictionary = cabinets[folder_name]
		var serializable: Dictionary = {}
		for key in entry:
			if key != "icon" and key != "status":
				serializable[key] = entry[key]
		cache_data[folder_name] = serializable
	var file = FileAccess.open(CACHE_FILE, FileAccess.WRITE)
	if file == null:
		return
	file.store_string(JSON.stringify(cache_data, "\t"))
	file.close()

func _fetch_remote() -> void:
	var urls = await _fetch_remote_arcade()
	if urls.is_empty():
		return
	# Mark cabinets not in remote list (but keep installed ones)
	var remote_folders: Array[String] = []
	for url in urls:
		remote_folders.append(url.get_file())
	# Remove NOT_INSTALLED entries that are no longer in remote
	for folder_name in cabinets.keys():
		if cabinets[folder_name]["status"] == CabinetStatus.NOT_INSTALLED and folder_name not in remote_folders:
			cabinets.erase(folder_name)
	cabinets_updated.emit()
	# Fetch cabinet.json for each repo
	for url in urls:
		var folder_name: String = url.get_file()
		if not cabinets.has(folder_name):
			cabinets[folder_name] = _empty_entry(folder_name)
			cabinets[folder_name]["status"] = CabinetStatus.NOT_INSTALLED
		cabinets[folder_name]["repo_url"] = url
		await _fetch_cabinet_json(folder_name, url)
		cabinets_updated.emit()
	await _check_updates()
	_save_cache()
	cabinets_updated.emit()

func _fetch_remote_arcade() -> Array:
	var http = HTTPRequest.new()
	add_child(http)
	var cache_bust = "?t=" + str(int(Time.get_unix_time_from_system()))
	var error = http.request(ARCADE_JSON_URL + cache_bust)
	if error != OK:
		http.queue_free()
		return []
	var response = await http.request_completed
	http.queue_free()
	if response[1] != 200:
		Log.warn("Failed to fetch arcade.json (HTTP %d)" % response[1])
		return []
	var json = JSON.parse_string(response[3].get_string_from_utf8())
	if json is Array:
		Log.info("Fetched arcade.json (%d repos)" % json.size())
		return json
	return []

func _fetch_cabinet_json(folder_name: String, repo_url: String) -> void:
	var base_raw_url = repo_url.replace("github.com", "raw.githubusercontent.com") + "/main/"
	var cache_bust = "?t=" + str(int(Time.get_unix_time_from_system()))
	var http = HTTPRequest.new()
	add_child(http)
	var error = http.request(base_raw_url + "cabinet.json" + cache_bust)
	if error != OK:
		http.queue_free()
		return
	var response = await http.request_completed
	http.queue_free()
	if response[1] != 200:
		return
	var json = JSON.parse_string(response[3].get_string_from_utf8())
	if json is not Dictionary:
		return
	var entry: Dictionary = cabinets[folder_name]
	entry["display_name"] = json.get("display_name", folder_name)
	entry["developer"] = json.get("developer", "Unknown")
	entry["description"] = json.get("description", "")
	entry["icon_path"] = json.get("icon", "")
	entry["command"] = json.get("command", "")
	entry["arch"] = json.get("arch", "")
	if entry["icon_path"] != "":
		await _fetch_and_cache_icon(folder_name, base_raw_url, entry["icon_path"])

func _fetch_and_cache_icon(folder_name: String, base_raw_url: String, icon_path: String) -> void:
	var encoded_path = "/".join(Array(icon_path.split("/")).map(func(s): return s.uri_encode()))
	var cache_bust = "?t=" + str(int(Time.get_unix_time_from_system()))
	var http = HTTPRequest.new()
	add_child(http)
	var error = http.request(base_raw_url + encoded_path + cache_bust)
	if error != OK:
		http.queue_free()
		return
	var response = await http.request_completed
	http.queue_free()
	if response[1] != 200:
		return
	var body: PackedByteArray = response[3]
	var image = Image.new()
	var url_clean = icon_path.split("?")[0]
	if url_clean.ends_with(".png"):
		error = image.load_png_from_buffer(body)
	elif url_clean.ends_with(".jpg") or url_clean.ends_with(".jpeg"):
		error = image.load_jpg_from_buffer(body)
	elif url_clean.ends_with(".webp"):
		error = image.load_webp_from_buffer(body)
	elif url_clean.ends_with(".svg"):
		error = image.load_svg_from_buffer(body)
	else:
		error = image.load_png_from_buffer(body)
	if error != OK:
		return
	# Save to cache
	image.save_png(ICONS_DIR + "/" + folder_name + ".png")
	cabinets[folder_name]["icon"] = ImageTexture.create_from_image(image)

func _check_updates() -> void:
	for folder_name in cabinets:
		var entry: Dictionary = cabinets[folder_name]
		if entry["status"] != CabinetStatus.INSTALLED:
			continue
		var path = CABINETS_DIR + "/" + folder_name
		await get_tree().process_frame
		Shell.command("git -C " + path + " fetch")
		var local = Shell.command("git -C " + path + " rev-parse HEAD").strip_edges()
		var remote = Shell.command("git -C " + path + " rev-parse @{u}").strip_edges()
		if local != remote and remote != "":
			entry["status"] = CabinetStatus.UPDATE_AVAILABLE

func install_cabinet(cabinet_name: String) -> void:
	var entry: Dictionary = cabinets[cabinet_name]
	var repo_url: String = entry["repo_url"]
	if repo_url == "":
		Log.warn("No repo URL for " + cabinet_name)
		return
	var install_path = CABINETS_DIR + "/" + cabinet_name
	Log.info("Installing " + cabinet_name + "...")
	await get_tree().process_frame
	Shell.command("git clone " + repo_url + " " + install_path)
	entry["status"] = CabinetStatus.INSTALLED
	cabinets_updated.emit()

func remove_cabinet(cabinet_name: String) -> void:
	var install_path = CABINETS_DIR + "/" + cabinet_name
	Log.info("Removing " + cabinet_name + "...")
	await get_tree().process_frame
	Shell.command("rm -rf " + install_path)
	cabinets[cabinet_name]["status"] = CabinetStatus.NOT_INSTALLED
	cabinets_updated.emit()

func update_cabinet(cabinet_name: String) -> void:
	var install_path = CABINETS_DIR + "/" + cabinet_name
	Log.info("Updating " + cabinet_name + "...")
	await get_tree().process_frame
	Shell.command("git -C " + install_path + " pull")
	cabinets[cabinet_name]["status"] = CabinetStatus.INSTALLED
	cabinets_updated.emit()

func launch_cabinet(cabinet_name: String) -> void:
	var entry: Dictionary = cabinets[cabinet_name]
	var command: String = entry.get("command", "")
	if command == "":
		Log.warn("No launch command for " + cabinet_name)
		return
	var install_path = CABINETS_DIR + "/" + cabinet_name
	var arch: String = entry.get("arch", "")
	var launch_cmd = command
	if arch == "x86_64":
		launch_cmd = "box64 " + launch_cmd
	CommandQueue.add("cd " + install_path + " && " + launch_cmd)
	CommandQueue.add("sudo /andrewarcade/driver/scripts/launch.sh")
	Log.info("Launching " + cabinet_name)
	await get_tree().process_frame
	get_tree().quit()

func _empty_entry(folder_name: String) -> Dictionary:
	return {
		"name": folder_name,
		"status": CabinetStatus.NOT_INSTALLED,
		"repo_url": "",
		"display_name": folder_name,
		"developer": "Unknown",
		"description": "",
		"icon_path": "",
		"command": "",
		"arch": "",
		"icon": null,
	}
