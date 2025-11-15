extends Node2D

# --- Containers & buttons ---
@onready var row1 = $Wardrobe/row1
@onready var row2 = $Wardrobe/row2
@onready var row3 = $Wardrobe/row3
@onready var row4 = $Wardrobe/row4
@onready var prev_btn = $MainBG/prev
@onready var next_btn = $MainBG/next
@onready var back_btn = $MainBG/back
@onready var vbox_shirt_btn = $Wardrobe/VBoxContainer/Shirt
@onready var vbox_skirt_btn = $Wardrobe/VBoxContainer/Skirt
@onready var vbox_accessories_btn = $Wardrobe/VBoxContainer/Accessories
@onready var vbox_shoes_btn = $Wardrobe/VBoxContainer/Shoes
@onready var vbox2_shirt_btn = $Wardrobe/VBoxContainer2/Shirt
@onready var vbox2_skirt_btn = $Wardrobe/VBoxContainer2/Skirt
@onready var vbox2_accessories_btn = $Wardrobe/VBoxContainer2/Accessories
@onready var vbox2_shoes_btn = $Wardrobe/VBoxContainer2/Shoes

# --- Variables ---
var selected_category: String = ""
var current_page := 0
var items_per_page := 4  # 4 items per row (single row pagination)
var all_images: Array = []
var category_to_row: Dictionary = {}
var category_images: Dictionary = {}  # Store images per category
var category_pages: Dictionary = {}  # Store current page per category

func _ready():
	# Initialize category to row mapping
	category_to_row = {
		"shirt": row1,
		"skirt": row2,
		"accessories": row3,
		"shoes": row4
	}
	
	# Initialize pages for each category
	category_pages = {
		"shirt": 0,
		"skirt": 0,
		"accessories": 0,
		"shoes": 0
	}
	
	# Load all categories' items into their respective rows
	_load_all_categories()
	
	# Initialize with no category selected - all rows at very low opacity and disabled
	_set_row_enabled(row1, false, 0.2)
	_set_row_enabled(row2, false, 0.2)
	_set_row_enabled(row3, false, 0.2)
	_set_row_enabled(row4, false, 0.2)
	
	# Initialize VBoxContainer buttons to very low opacity (no category selected yet)
	if vbox_shirt_btn:
		vbox_shirt_btn.modulate = Color(1, 1, 1, 0.2)
	if vbox_skirt_btn:
		vbox_skirt_btn.modulate = Color(1, 1, 1, 0.2)
	if vbox_accessories_btn:
		vbox_accessories_btn.modulate = Color(1, 1, 1, 0.2)
	if vbox_shoes_btn:
		vbox_shoes_btn.modulate = Color(1, 1, 1, 0.2)
	
	# Connect VBoxContainer category buttons (white noise backgrounds - radio buttons)
	if vbox_shirt_btn:
		vbox_shirt_btn.pressed.connect(_on_category_shirt_pressed)
	if vbox_skirt_btn:
		vbox_skirt_btn.pressed.connect(_on_category_skirt_pressed)
	if vbox_accessories_btn:
		vbox_accessories_btn.pressed.connect(_on_category_accessories_pressed)
	if vbox_shoes_btn:
		vbox_shoes_btn.pressed.connect(_on_category_shoes_pressed)
	
	# Connect VBoxContainer2 buttons (clickable to select category)
	if vbox2_shirt_btn:
		vbox2_shirt_btn.pressed.connect(_on_category_shirt_pressed)
	if vbox2_skirt_btn:
		vbox2_skirt_btn.pressed.connect(_on_category_skirt_pressed)
	if vbox2_accessories_btn:
		vbox2_accessories_btn.pressed.connect(_on_category_accessories_pressed)
	if vbox2_shoes_btn:
		vbox2_shoes_btn.pressed.connect(_on_category_shoes_pressed)
	
	# Update VBoxContainer2 with saved selections
	_update_vbox2_selections()
	
	# Pre-select category if coming from wardrobe scene
	if not Globals.selected_item.is_empty():
		_select_category(Globals.selected_item)
		Globals.selected_item = ""  # Clear after using
	else:
		# Disable next/prev buttons until category is selected
		prev_btn.visible = false
		next_btn.visible = false


# --- LOAD ALL CATEGORIES ---
func _load_all_categories() -> void:
	var categories = ["shirt", "skirt", "accessories", "shoes"]
	
	for category in categories:
		_load_category_images(category)
		_populate_category_row(category, 0)  # Load first page of each category

# --- LOAD TEXTURES FROM .tres FILE FOR A CATEGORY ---
func _load_category_images(category: String) -> void:
	# Load textures for the specified category
	var path = "res://assets/wardrobe/%s/%s.tres" % [category, category]
	var resource = load(path)

	# Note: In Godot 4, you might need to use 'resource.get("textures")' for dynamic properties
	if resource and "textures" in resource: # check manually if the property exists
		# Assuming resource.textures is an Array of Texture2D
		category_images[category] = resource.textures.duplicate()
	else:
		push_error("Could not load wardrobe resource or missing 'textures' array: %s" % path)
		category_images[category] = []

# --- POPULATE A CATEGORY'S ROW WITH ITEMS ---
func _populate_category_row(category: String, page_index: int) -> void:
	if not category_images.has(category):
		return
	
	var row = category_to_row[category]
	if not row:
		return
	
	# Clear the row
	_clear_row(row)
	
	var images = category_images[category]
	var start_index = page_index * items_per_page
	var end_index = min(start_index + items_per_page, images.size())
	var page_items = images.slice(start_index, end_index)
	
	var template_node = row.get_node("item1")
	
	for i in range(page_items.size()):
		# Duplicate template and configure as a Button item
		var item_node = template_node.duplicate()
		if item_node is Button:
			item_node.icon = page_items[i]
			item_node.expand_icon = true
			item_node.flat = true
			item_node.focus_mode = Control.FOCUS_NONE
			item_node.visible = true
			item_node.disabled = false  # Ensure button is enabled
			item_node.mouse_filter = Control.MOUSE_FILTER_STOP  # Ensure mouse interaction works
			
			# Store original scale and offset for hover effect
			item_node.set_meta("original_scale", item_node.scale)
			item_node.set_meta("original_offset_top", item_node.offset_top)
			
			row.add_child(item_node)
			# Bind for pressed when using Button
			item_node.connect("pressed", Callable(self, "_on_item_button_pressed").bind(item_node, category))
			# Connect hover signals for float effect
			item_node.mouse_entered.connect(_on_item_mouse_entered.bind(item_node))
			item_node.mouse_exited.connect(_on_item_mouse_exited.bind(item_node))
		else:
			push_error("'item1' must be a Button in row: %s" % [row.name])


# --- DISPLAY A PAGE OF TEXTURES FOR SELECTED CATEGORY ---
func _show_page(page_index: int):
	if selected_category.is_empty():
		return
	
	# Update the page for this category
	category_pages[selected_category] = page_index
	
	# Populate the selected category's row
	_populate_category_row(selected_category, page_index)
	
	# Update all_images for pagination calculations
	all_images = category_images[selected_category] if category_images.has(selected_category) else []
	current_page = page_index
	
	_update_page_buttons()


# --- CLEAR A SPECIFIC ROW ---
func _clear_row(row: HBoxContainer):
	for child in row.get_children():
		# Check for the template node name to keep it
		if child.name != "item1":
			child.queue_free()
	# Hide the template node itself
	row.get_node("item1").visible = false

# --- SET ROW OPACITY ---
func _set_row_opacity(row: HBoxContainer, opacity: float):
	for child in row.get_children():
		if child is Control:
			# Set modulate color with proper alpha (like #ffffffaa)
			var current_color = child.modulate
			child.modulate = Color(current_color.r, current_color.g, current_color.b, opacity)

# --- SET ROW ENABLED/DISABLED AND OPACITY ---
func _set_row_enabled(row: HBoxContainer, enabled: bool, opacity: float):
	for child in row.get_children():
		if child is Control:
			# Set modulate color with proper alpha
			var current_color = child.modulate
			child.modulate = Color(current_color.r, current_color.g, current_color.b, opacity)
			
			# Enable/disable mouse interaction
			if child is Button:
				child.disabled = not enabled
				child.mouse_filter = Control.MOUSE_FILTER_STOP if enabled else Control.MOUSE_FILTER_IGNORE




# --- HOVER EFFECT HANDLERS ---
func _on_item_mouse_entered(item: Button) -> void:
	if item.disabled:
		return
	
	var original_scale = item.get_meta("original_scale", Vector2.ONE)
	var original_offset = item.get_meta("original_offset_top", 0.0)
	
	# Create float effect: scale up and move up slightly using offset
	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(item, "scale", original_scale * 1.15, 0.2).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	# Use offset_top to create upward float effect
	tween.tween_property(item, "offset_top", original_offset - 8.0, 0.2).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)

func _on_item_mouse_exited(item: Button) -> void:
	if item.disabled:
		return
	
	var original_scale = item.get_meta("original_scale", Vector2.ONE)
	var original_offset = item.get_meta("original_offset_top", 0.0)
	
	# Return to original scale and position
	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(item, "scale", original_scale, 0.2).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_BACK)
	# Reset offset_top to original position
	tween.tween_property(item, "offset_top", original_offset, 0.2).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_BACK)

# --- HANDLE BUTTON PRESSED (Button-based items) ---
func _on_item_button_pressed(btn: Button, category: String) -> void:
	var texture := btn.icon
	_on_item_clicked(texture, category)


# --- SAVE SELECTION AND UPDATE VBOX2 ---
func _on_item_clicked(texture: Texture2D, category: String) -> void:
	if texture == null:
		push_warning("Clicked item has no texture.")
		return
	
	if category.is_empty():
		return

	# Save to Globals and persist to preferences
	Globals.wardrobe_selection[category] = texture
	Globals.save_wardrobe_selection(category, texture)
	
	# Update VBoxContainer2 button icon
	_update_vbox2_button(category, texture)


# --- NEXT/PREV PAGE HANDLERS ---
func _on_prev_pressed() -> void:
	if selected_category.is_empty():
		return
	if current_page > 0:
		current_page -= 1
		_show_page(current_page)

func _on_next_pressed() -> void:
	if selected_category.is_empty():
		return
	# Check if there are any images to prevent division by zero if all_images is empty
	if all_images.size() == 0:
		return
		
	# Using 'ceil' to ensure correct max page calculation
	var max_page = int(ceil(float(all_images.size()) / items_per_page)) - 1
	if current_page < max_page:
		current_page += 1
		_show_page(current_page)


# --- UPDATE BUTTON VISIBILITY ---
func _update_page_buttons():
	if selected_category.is_empty():
		prev_btn.visible = false
		next_btn.visible = false
		return
		
	# Check if there are any images to prevent division by zero
	if all_images.size() == 0:
		prev_btn.visible = false
		next_btn.visible = false
		return
		
	var max_page = int(ceil(float(all_images.size()) / items_per_page)) - 1
	prev_btn.visible = current_page > 0
	next_btn.visible = current_page < max_page


# --- CATEGORY SELECTION HANDLERS ---
func _on_category_shirt_pressed() -> void:
	_select_category("shirt")

func _on_category_skirt_pressed() -> void:
	_select_category("skirt")

func _on_category_accessories_pressed() -> void:
	_select_category("accessories")

func _on_category_shoes_pressed() -> void:
	_select_category("shoes")

# --- SELECT CATEGORY AND UPDATE UI ---
func _select_category(category: String) -> void:
	selected_category = category
	
	# Update row enabled/disabled and opacity: selected = enabled with 1.0 opacity, others = disabled with 0.2 opacity
	_set_row_enabled(row1, category == "shirt", 1.0 if category == "shirt" else 0.2)
	_set_row_enabled(row2, category == "skirt", 1.0 if category == "skirt" else 0.2)
	_set_row_enabled(row3, category == "accessories", 1.0 if category == "accessories" else 0.2)
	_set_row_enabled(row4, category == "shoes", 1.0 if category == "shoes" else 0.2)
	
	# Update VBoxContainer button opacity (white noise backgrounds)
	# Selected = ffffffaa (0.666 opacity), Not selected = very low opacity (0.2)
	# ffffffaa: aa in hex = 170 decimal = 170/255 = 0.666
	if vbox_shirt_btn:
		vbox_shirt_btn.modulate = Color(1, 1, 1, 0.666 if category == "shirt" else 0.2)
	if vbox_skirt_btn:
		vbox_skirt_btn.modulate = Color(1, 1, 1, 0.666 if category == "skirt" else 0.2)
	if vbox_accessories_btn:
		vbox_accessories_btn.modulate = Color(1, 1, 1, 0.666 if category == "accessories" else 0.2)
	if vbox_shoes_btn:
		vbox_shoes_btn.modulate = Color(1, 1, 1, 0.666 if category == "shoes" else 0.2)
	
	# Show the current page for this category (items already loaded)
	current_page = category_pages[category]
	_show_page(current_page)

# --- UPDATE VBOX2 BUTTON ICON ---
func _update_vbox2_button(category: String, texture: Texture2D) -> void:
	match category:
		"shirt":
			vbox2_shirt_btn.icon = texture
		"skirt":
			vbox2_skirt_btn.icon = texture
		"accessories":
			vbox2_accessories_btn.icon = texture
		"shoes":
			vbox2_shoes_btn.icon = texture

# --- UPDATE ALL VBOX2 SELECTIONS FROM GLOBALS ---
func _update_vbox2_selections() -> void:
	if Globals.wardrobe_selection.has("shirt") and Globals.wardrobe_selection["shirt"] != null:
		vbox2_shirt_btn.icon = Globals.wardrobe_selection["shirt"]
	if Globals.wardrobe_selection.has("skirt") and Globals.wardrobe_selection["skirt"] != null:
		vbox2_skirt_btn.icon = Globals.wardrobe_selection["skirt"]
	if Globals.wardrobe_selection.has("accessories") and Globals.wardrobe_selection["accessories"] != null:
		vbox2_accessories_btn.icon = Globals.wardrobe_selection["accessories"]
	if Globals.wardrobe_selection.has("shoes") and Globals.wardrobe_selection["shoes"] != null:
		vbox2_shoes_btn.icon = Globals.wardrobe_selection["shoes"]

# --- BACK BUTTON HANDLER ---
func _on_back_pressed() -> void:
	SceneTransition.transition_to_scene("res://scenes/wardrobe.tscn")
