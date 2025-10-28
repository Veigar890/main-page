extends Node2D

# --- Containers & buttons ---
@onready var left_container = $MainBG/Wardrobe/Control/left
@onready var right_container = $MainBG/Wardrobe/Control/right
@onready var mid_container = $MainBG/Wardrobe/Control/middle
@onready var mid2_container = $MainBG/Wardrobe/Control/middle2
@onready var prev_btn = $MainBG/Control/prev
@onready var next_btn = $MainBG/Control/next
@onready var back_btn = $MainBG/Control/back

# --- Variables ---
var current_page := 0
var items_per_page := 12
var all_images: Array = []

func _ready():
	# It's better practice to use the signals defined in the editor,
	# but connecting in code like this is fine if you prefer it.
	if prev_btn:
		prev_btn.connect("pressed", Callable(self, "_on_prev_pressed"))
	if next_btn:
		next_btn.connect("pressed", Callable(self, "_on_next_pressed"))
	if back_btn:
		back_btn.connect("pressed", Callable(self, "_on_back_pressed"))

	_load_images()
	_update_page_buttons()
	_show_page(0)


# --- LOAD TEXTURES FROM .tres FILE ---
func _load_images():
	all_images.clear()
	current_page = 0

	# Assuming 'Globals' is a globally accessible singleton (AutoLoad)
	var path = "res://assets/wardrobe/%s/%s.tres" % [Globals.selected_item, Globals.selected_item]
	var resource = load(path)

	# Note: In Godot 4, you might need to use 'resource.get("textures")' for dynamic properties
	if resource and "textures" in resource: # check manually if the property exists
		# Assuming resource.textures is an Array of Texture2D
		all_images = resource.textures.duplicate()
	else:
		push_error("Could not load wardrobe resource or missing 'textures' array: %s" % path)


# --- DISPLAY A PAGE OF TEXTURES ---
func _show_page(page_index: int):
	_clear_all_containers()

	var start_index = page_index * items_per_page
	var end_index = min(start_index + items_per_page, all_images.size())
	# slice() with 2 arguments is exclusive for the end index in Godot 4
	var page_items = all_images.slice(start_index, end_index - 1) 

	var slots = [
		{"container": left_container, "max": 4},
		{"container": right_container, "max": 4},
		{"container": mid_container, "max": 2},
		{"container": mid2_container, "max": 2},
	]

	var img_index = 0
	for slot in slots:
		var cont = slot["container"]
		var max_items = slot["max"]

		for i in range(max_items):
			if img_index >= page_items.size():
				break

			# Assuming 'item1' is your TextureRect template
			var tex_rect = cont.get_node("item1").duplicate()
			tex_rect.texture = page_items[img_index]
			tex_rect.visible = true
			# This is correct and crucial for clicks
			tex_rect.mouse_filter = Control.MOUSE_FILTER_STOP
			cont.add_child(tex_rect)

			# Connect click event for TextureRect
			# We bind the tex_rect so we know which node was clicked
			tex_rect.connect("gui_input", Callable(self, "_on_texrect_gui_input").bind(tex_rect))

			img_index += 1

	_update_page_buttons()


# --- CLEAR OLD TEXTURES ---
func _clear_all_containers():
	for cont in [left_container, right_container, mid_container, mid2_container]:
		for child in cont.get_children():
			# Check for the template node name to keep it
			if child.name != "item1":
				child.queue_free()
		# Hide the template node itself
		cont.get_node("item1").visible = false


# --- HANDLE CLICK EVENTS ON TEXTURERECTS ---
# FIX APPLIED: Added the 'is_echo' parameter to correct the signature
func _on_texrect_gui_input(tex_rect: TextureRect, event: InputEvent, is_echo: bool) -> void:
	# Ignore repeated input events
	if is_echo:
		return

	# Handle Mouse Clicks
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		get_viewport().set_input_as_handled() # Prevents click propagation
		_on_item_clicked(tex_rect.texture)
	
	# Handle Touch Input (for mobile)
	elif event is InputEventScreenTouch and event.pressed:
		get_viewport().set_input_as_handled() # Prevents touch propagation
		_on_item_clicked(tex_rect.texture)


# --- SAVE SELECTION AND RETURN TO MAIN WARDROBE ---
func _on_item_clicked(texture: Texture2D) -> void:
	if texture == null:
		push_warning("Clicked item has no texture.")
		return

	# Assuming 'Globals' and 'wardrobe_selection' are available
	Globals.wardrobe_selection[Globals.selected_item] = texture
	# Assuming this scene path is correct
	get_tree().change_scene_to_file("res://scenes/wardrobe.tscn")


# --- NEXT/PREV PAGE HANDLERS ---
func _on_prev_pressed() -> void:
	if current_page > 0:
		current_page -= 1
		_show_page(current_page)

func _on_next_pressed() -> void:
	# Check if there are any images to prevent division by zero if all_images is empty
	if all_images.size() == 0:
		return
		
	# Using 'ceil' to ensure correct max page calculation (e.g., 13 items / 12 = 1.08 -> 2 pages)
	var max_page = int(ceil(float(all_images.size()) / items_per_page)) - 1
	if current_page < max_page:
		current_page += 1
		_show_page(current_page)


# --- UPDATE BUTTON VISIBILITY ---
func _update_page_buttons():
	# Check if there are any images to prevent division by zero
	if all_images.size() == 0:
		prev_btn.visible = false
		next_btn.visible = false
		return
		
	var max_page = int(ceil(float(all_images.size()) / items_per_page)) - 1
	prev_btn.visible = current_page > 0
	next_btn.visible = current_page < max_page


# --- BACK BUTTON HANDLER ---
func _on_back_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/wardrobe.tscn")
