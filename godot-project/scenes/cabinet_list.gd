extends Control

const MASTER_LIST_URL = "https://raw.githubusercontent.com/Andrew-Arcade/driver/main/cabinets.json"

@export var cabinet_scene: PackedScene 

@onready var container_node = $VBoxContainer 

func _ready():
	var master_req = HTTPRequest.new()
	add_child(master_req)
	master_req.request_completed.connect(_on_master_list_received)
	master_req.request(MASTER_LIST_URL)

func _on_master_list_received(_result, response_code, _headers, body):
	if response_code != 200: 
		print("Failed to load master list: ", response_code)
		return
	
	var data = JSON.parse_string(body.get_string_from_utf8())
	if data and data.has("apps"):
		for app_repo_url in data["apps"]:
			var raw_base = app_repo_url.replace("github.com", "raw.githubusercontent.com") + "/main/"
			fetch_cabinet_details(raw_base)

func fetch_cabinet_details(base_url: String):
	var cab_req = HTTPRequest.new()
	add_child(cab_req)
	cab_req.request_completed.connect(
		func(res, code, head, body): _on_cabinet_received(res, code, head, body, base_url, cab_req)
	)
	cab_req.request(base_url + "cabinet.json")

func _on_cabinet_received(_res, response_code, _head, body, base_url, node):
	node.queue_free()
	if response_code != 200: return
	
	var cab_data = JSON.parse_string(body.get_string_from_utf8())
	
	if not cabinet_scene:
		print("ERROR: cabinet_scene is null! Drag cabinet.tscn into the Inspector.")
		return
		
	var new_card = cabinet_scene.instantiate()
	container_node.add_child(new_card)
	
	var temp_data = CabinetData.new()
	temp_data.display_name = cab_data.get("display_name", "Unknown App")
	temp_data.developer = cab_data.get("developer", "Unknown Dev")
	temp_data.description = cab_data.get("description", "No description provided.")
	
	new_card.load_data(temp_data)
	
	var icon_path = cab_data.get("icon", "")
	if icon_path != "":
		fetch_icon(base_url + icon_path, new_card)

func fetch_icon(icon_url: String, target_card: Control):
	var img_req = HTTPRequest.new()
	add_child(img_req)
	img_req.request_completed.connect(
		func(res, code, head, body): _on_icon_received(res, code, head, body, target_card, img_req)
	)
	img_req.request(icon_url)

func _on_icon_received(_res, response_code, _head, body, target_card, node):
	node.queue_free()
	if response_code != 200: return

	var image = Image.new()
	var error = image.load_png_from_buffer(body)
	if error != OK:
		error = image.load_jpg_from_buffer(body)
		
	if error == OK:
		var texture = ImageTexture.create_from_image(image)
		if target_card.has_method("update_icon"):
			target_card.update_icon(texture)
