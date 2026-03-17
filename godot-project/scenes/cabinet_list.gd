extends Control

const MASTER_LIST_URL = "https://raw.githubusercontent.com/Andrew-Arcade/driver/main/cabinets.json"

@onready var list_node = $ItemList

func _ready():
	# Use a one-off request for the master list
	var master_req = HTTPRequest.new()
	add_child(master_req)
	master_req.request_completed.connect(_on_master_list_received)
	master_req.request(MASTER_LIST_URL)

func _on_master_list_received(_result, response_code, _headers, body):
	if response_code != 200: return
	
	var data = JSON.parse_string(body.get_string_from_utf8())
	if data and data.has("apps"):
		for app_repo_url in data["apps"]:
			# Build the URL for the cabinet.json
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
	var display_name = cab_data.get("display_name", "App")
	var icon_path = cab_data.get("icon", "")
	
	# Create a temporary index for the item so we can update it with an image later
	var item_index = list_node.add_item(display_name)
	
	# If there is an icon path, go get the image
	if icon_path != "":
		fetch_icon(base_url + icon_path, item_index)

func fetch_icon(icon_url: String, index: int):
	var img_req = HTTPRequest.new()
	add_child(img_req)
	img_req.request_completed.connect(
		func(res, code, head, body): _on_icon_received(res, code, head, body, index, img_req)
	)
	img_req.request(icon_url)

func _on_icon_received(_res, response_code, _head, body, index, node):
	node.queue_free()
	if response_code != 200: return

	# Turn the raw bytes into an Image
	var image = Image.new()
	var error = image.load_png_from_buffer(body) # Assuming PNG based on your JSON
	if error != OK:
		# If PNG fails, try JPG just in case
		error = image.load_jpg_from_buffer(body)
		
	if error == OK:
		# Convert Image to Texture so the UI can show it
		var texture = ImageTexture.create_from_image(image)
		list_node.set_item_icon(index, texture)
