extends Node2D

@onready var left_container = $MainBG/Wardrobe/Control/left
@onready var right_container = $MainBG/Wardrobe/Control/right
@onready var mid_container = $MainBG/Wardrobe/Control/middle
@onready var mid2_container = $MainBG/Wardrobe/Control/middle2
@onready var prev_btn = $MainBG/Control/prev
@onready var next_btn = $MainBG/Control/next

var current_page := 0
var items_per_page := 12 # 4+4+2+2
var all_images: Array = []

func _ready():
	_load_images()
	_update_page_buttons()
	_show_page(0)


# --- LOAD ALL PNG IMAGES FROM SELECTED ITEM TYPE (Globals.selected_item)
func _load_images():
	var base_path = "res://assets/wardrobe/%s/" % Globals.selected_item
	var dir = DirAccess.open(base_path)
	all_images.clear()

	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		while file_name != "":
			if not dir.current_is_dir():
				var lower_name = file_name.to_lower()
				if lower_name.ends_with(".png"):
					all_images.append(base_path + file_name)
			file_name = dir.get_next()
		dir.list_dir_end()
	else:
		push_error("Wardrobe folder not found: %s" % base_path)

# --- DISPLAY A SPECIFIC PAGE ---
func _show_page(page_index: int):
	_clear_all_containers()

	var start_index = page_index * items_per_page
	var end_index = min(start_index + items_per_page, all_images.size())
	var page_items = all_images.slice(start_index, end_index)

	# distribute images across views
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
			var tex_rect = cont.get_node("item1").duplicate()
			tex_rect.texture = load(page_items[img_index])
			tex_rect.visible = true
			cont.add_child(tex_rect)
			img_index += 1

	_update_page_buttons()


# --- CLEAR OLD IMAGES BEFORE SHOWING NEW ONES ---
func _clear_all_containers():
	for cont in [left_container, right_container, mid_container, mid2_container]:
		for child in cont.get_children():
			if child.name != "item1": # keep template
				child.queue_free()
		# Hide the template by default
		cont.get_node("item1").visible = false


# --- NEXT/PREV PAGE HANDLERS ---
func _on_prev_pressed() -> void:
	if current_page > 0:
		current_page -= 1
		_show_page(current_page)

func _on_next_pressed() -> void:
	var max_page = int(ceil(float(all_images.size()) / items_per_page)) - 1
	if current_page < max_page:
		current_page += 1
		_show_page(current_page)

func _update_page_buttons():
	var max_page = int(ceil(float(all_images.size()) / items_per_page)) - 1
	prev_btn.visible = current_page > 0
	next_btn.visible = current_page < max_page
	
func _on_back_pressed() -> void: get_tree().change_scene_to_file("res://scenes/wardrobe.tscn")
