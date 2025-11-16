extends Node2D

# --- Node references ---
@onready var item1: Button = $Fridge/item1
@onready var item2: Button = $Fridge/item2
@onready var item3: Button = $Fridge/item3
@onready var item4: Button = $Fridge/item4
@onready var prev_btn: TextureButton = $MainBG/prev
@onready var next_btn: TextureButton = $MainBG/next
@onready var unlock_label: Label = $Fridge/lock_label

# --- Variables ---
var all_foods: Array[Texture2D] = []  # Store first frame textures from spritesheets
var all_food_spritesheets: Array[SpriteFrames] = []  # Store full SpriteFrames for eating
var current_page: int = 0
var items_per_page: int = 4
var is_eating: bool = false  # Prevent multiple eating actions

func _ready() -> void:
	# Ensure food sprite doesn't try to play empty animation
	var food_sprite = get_node_or_null("PET2/food")
	if food_sprite and food_sprite is AnimatedSprite2D:
		food_sprite.stop()
		food_sprite.visible = false
	
	_load_foods()
	_show_page(0)
	_update_page_buttons()
	
	# Connect prev/next buttons
	if prev_btn:
		prev_btn.pressed.connect(_on_prev_pressed)
	if next_btn:
		next_btn.pressed.connect(_on_next_pressed)
	
	# Store original properties and connect hover signals for all items
	_setup_item_hover_effects()
	
	# Connect item button presses
	_connect_item_buttons()
	
	# Setup drop zone on pet
	_setup_pet_drop_zone()

# --- Load foods from spritesheets .tres file ---
func _load_foods() -> void:
	var path: String = "res://assets/foods_drinks/spritesheets.tres"
	var source_resource = load(path) as FoodSpritesheetsSource
	
	if not source_resource:
		push_error("Could not load foods spritesheets resource: %s" % path)
		all_foods = []
		return
	
	# Check if source has textures
	if not source_resource.spritesheet_textures or source_resource.spritesheet_textures.is_empty():
		push_error("spritesheets.tres is empty! Please add spritesheet textures to the 'spritesheet_textures' array in the resource.")
		all_foods = []
		return
	
	# Convert spritesheets to SpriteFrames
	var food_spritesheets = FoodSpriteFrames.from_source(source_resource)
	
	if food_spritesheets.spritesheets.is_empty():
		push_error("No SpriteFrames were created from spritesheets. Check that textures are valid and columns setting is correct.")
		all_foods = []
		return
	
	# Extract first frame from each SpriteFrames as Texture2D, and store SpriteFrames
	all_foods.clear()
	all_food_spritesheets.clear()
	for i in range(food_spritesheets.spritesheets.size()):
		var sprite_frames = food_spritesheets.spritesheets[i]
		if not sprite_frames:
			push_warning("SpriteFrames at index ", i, " is null")
			continue
		
		# Get the first animation name
		var anim_names = sprite_frames.get_animation_names()
		if anim_names.is_empty():
			push_warning("SpriteFrames at index ", i, " has no animations")
			continue
		
		var anim_name = anim_names[0]
		
		# Get the first frame from the animation
		var frame_count = sprite_frames.get_frame_count(anim_name)
		if frame_count == 0:
			push_warning("Animation '", anim_name, "' in SpriteFrames at index ", i, " has no frames")
			continue
		
		var first_frame = sprite_frames.get_frame_texture(anim_name, 0)
		if first_frame:
			all_foods.append(first_frame)
			all_food_spritesheets.append(sprite_frames)  # Store the full SpriteFrames
		else:
			push_warning("Failed to get first frame texture from SpriteFrames at index ", i)
	
	if all_foods.is_empty():
		push_error("No food frames were extracted from spritesheets. Check the conversion process above.")

# --- Setup hover effects for items ---
func _setup_item_hover_effects() -> void:
	var items: Array[Button] = [item1, item2, item3, item4]
	
	for item in items:
		# Store original scale and offset for hover effect
		item.set_meta("original_scale", item.scale)
		item.set_meta("original_offset_top", item.offset_top)
		
		# Connect hover signals
		item.mouse_entered.connect(_on_item_mouse_entered.bind(item))
		item.mouse_exited.connect(_on_item_mouse_exited.bind(item))

# --- Display a page of foods ---
func _show_page(page_index: int) -> void:
	if all_foods.is_empty():
		return
	
	var start_index: int = page_index * items_per_page
	var end_index: int = min(start_index + items_per_page, all_foods.size())
	
	# Update each item button
	var items: Array[Button] = [item1, item2, item3, item4]
	
	for i in range(items.size()):
		var item: Button = items[i]
		var food_index: int = start_index + i
		
		if food_index < end_index:
			item.icon = all_foods[food_index]
			item.visible = true
		else:
			item.visible = false
	
	current_page = page_index
	
	# Apply level-based unlocking after showing page
	_apply_level_unlocking()

# --- Update prev/next button visibility ---
func _update_page_buttons() -> void:
	if all_foods.is_empty():
		if prev_btn:
			prev_btn.visible = false
		if next_btn:
			next_btn.visible = false
		return
	
	var max_page: int = int(ceil(float(all_foods.size()) / items_per_page)) - 1
	
	if prev_btn:
		prev_btn.visible = current_page > 0
	if next_btn:
		next_btn.visible = current_page < max_page

# --- Navigation handlers ---
func _on_prev_pressed() -> void:
	if current_page > 0:
		current_page -= 1
		_show_page(current_page)
		_update_page_buttons()

func _on_next_pressed() -> void:
	if all_foods.is_empty():
		return
	
	var max_page: int = int(ceil(float(all_foods.size()) / items_per_page)) - 1
	if current_page < max_page:
		current_page += 1
		_show_page(current_page)
		_update_page_buttons()

# --- Hover effect handlers ---
func _on_item_mouse_entered(item: Button) -> void:
	if item.disabled or not item.visible:
		return
	
	var original_scale: Vector2 = item.get_meta("original_scale", Vector2.ONE)
	var original_offset: float = item.get_meta("original_offset_top", 0.0)
	
	# Create float effect: scale up and move up slightly using offset
	var tween: Tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(item, "scale", original_scale * 1.05, 0.2).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	# Use offset_top to create upward float effect
	tween.tween_property(item, "offset_top", original_offset - 4.0, 0.2).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)

func _on_item_mouse_exited(item: Button) -> void:
	if item.disabled or not item.visible:
		return
	
	var original_scale: Vector2 = item.get_meta("original_scale", Vector2.ONE)
	var original_offset: float = item.get_meta("original_offset_top", 0.0)
	
	# Return to original scale and position
	var tween: Tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(item, "scale", original_scale, 0.2).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_BACK)
	# Reset offset_top to original position
	tween.tween_property(item, "offset_top", original_offset, 0.2).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_BACK)

func _on_back_pressed() -> void:
	SceneTransition.transition_to_scene("res://scenes/node_2d.tscn")

# --- Connect item button presses ---
func _connect_item_buttons() -> void:
	var items: Array[Button] = [item1, item2, item3, item4]
	for i in range(items.size()):
		if items[i]:
			# Connect click
			items[i].pressed.connect(_on_item_pressed.bind(i))
			# Setup drag and drop
			_setup_item_drag(items[i], i)

# --- Setup item drag functionality ---
func _setup_item_drag(button: Button, item_index: int) -> void:
	# Store item index in metadata
	button.set_meta("item_index", item_index)
	# Attach a script to handle drag
	button.set_script(load("res://scripts/draggable_food_button.gd"))
	if button.has_method("setup_drag"):
		button.setup_drag(self, item_index)

# --- Handle item GUI input (for drag and drop) ---
func _on_item_gui_input(_event: InputEvent, _item_index: int, _button: Button) -> void:
	# This is now handled by the draggable button script
	pass

# --- Handle item click (fallback) ---
func _on_item_pressed(item_index: int) -> void:
	if is_eating:
		return  # Prevent eating during eating animation
	
	# Check if the clicked item is disabled (locked)
	var items: Array[Button] = [item1, item2, item3, item4]
	if item_index >= items.size():
		return
	
	var clicked_item = items[item_index]
	if clicked_item and clicked_item.disabled:
		return  # Item is locked, don't allow use
	
	var food_index: int = current_page * items_per_page + item_index
	if food_index >= all_foods.size() or food_index >= all_food_spritesheets.size():
		return
	
	# Get the selected food's SpriteFrames
	var selected_food_frames: SpriteFrames = all_food_spritesheets[food_index]
	if not selected_food_frames:
		return
	
	# Start eating sequence
	_start_eating_sequence(selected_food_frames)

# --- Start eating sequence ---
func _start_eating_sequence(food_frames: SpriteFrames) -> void:
	is_eating = true
	
	# Disable all item buttons during eating
	var items: Array[Button] = [item1, item2, item3, item4]
	for item in items:
		if item:
			item.disabled = true
	
	# Get pet and food nodes
	var pet_node = get_node_or_null("PET2")
	if not pet_node:
		_enable_items()
		is_eating = false
		return
	
	var food_sprite = pet_node.get_node_or_null("food")
	if not food_sprite:
		_enable_items()
		is_eating = false
		return
	
	# Get pet script
	var pet: Pet = pet_node as Pet
	if not pet:
		_enable_items()
		is_eating = false
		return
	
	# Set food sprite frames and make visible
	food_sprite.sprite_frames = food_frames
	food_sprite.visible = true
	
	# Get animation name (use first animation from food frames)
	var anim_names = food_frames.get_animation_names()
	if anim_names.is_empty():
		_enable_items()
		is_eating = false
		return
	
	var food_anim_name = anim_names[0]
	
	# Ensure animation doesn't loop
	if food_frames.has_animation(food_anim_name):
		food_frames.set_animation_loop(food_anim_name, false)
	
	# Play food animation (non-looping)
	food_sprite.play(food_anim_name)
	food_sprite.frame = 0
	
	# Set pet to eating
	pet.set_eating()
	
	# Wait for food animation to finish, then return to idle
	var food_anim_frames = food_frames.get_frame_count(food_anim_name)
	var food_anim_speed = food_frames.get_animation_speed(food_anim_name)
	var food_anim_duration = float(food_anim_frames) / food_anim_speed
	
	# Wait for food animation to complete
	await get_tree().create_timer(food_anim_duration).timeout
	
	# Return pet to idle
	pet.set_idle()
	
	# Hide and clear food sprite
	food_sprite.visible = false
	food_sprite.sprite_frames = null
	
	# Re-enable item buttons
	_enable_items()
	
	is_eating = false

# --- Enable item buttons ---
func _enable_items() -> void:
	var items: Array[Button] = [item1, item2, item3, item4]
	for item in items:
		if item:
			item.disabled = false

# --- APPLY LEVEL-BASED UNLOCKING ---
func _apply_level_unlocking() -> void:
	if all_foods.is_empty():
		if unlock_label:
			unlock_label.visible = false
		return
	
	# Calculate unlock threshold: level 1 unlocks items 0-3, level 2 unlocks 4-7, etc.
	var unlocked_count: int = Globals.player_level * 4
	
	var items: Array[Button] = [item1, item2, item3, item4]
	var start_index: int = current_page * items_per_page
	var has_locked_items: bool = false
	var unlock_level: int = 0
	
	for i in range(items.size()):
		var item: Button = items[i]
		if not item or not item.visible:
			continue
		
		var food_index: int = start_index + i
		
		# Check if item is unlocked: food_index < unlocked_count
		var is_unlocked = food_index < unlocked_count
		
		# Set opacity and disable state: 50% opacity and disabled if locked, 100% opacity and enabled if unlocked
		if is_unlocked:
			item.modulate = Color(1, 1, 1, 1.0)
			item.disabled = false
		else:
			item.modulate = Color(1, 1, 1, 0.5)
			item.disabled = true
			has_locked_items = true
			# Calculate which level unlocks this item: (food_index / 4) + 1
			var required_level = (food_index / items_per_page) + 1
			if unlock_level == 0 or required_level < unlock_level:
				unlock_level = required_level
	
	# Update unlock label
	if unlock_label:
		if has_locked_items and unlock_level > 0:
			unlock_label.text = "Unlocks at Level %d" % unlock_level
			unlock_label.visible = true
		else:
			unlock_label.visible = false

# --- Setup pet drop zone ---
func _setup_pet_drop_zone() -> void:
	var pet_node = get_node_or_null("PET2")
	if not pet_node:
		return
	
	# Add a Control node as drop zone (if not exists)
	var drop_zone = pet_node.get_node_or_null("DropZone")
	if not drop_zone:
		drop_zone = Control.new()
		drop_zone.name = "DropZone"
		drop_zone.mouse_filter = Control.MOUSE_FILTER_STOP
		# Make it cover the pet area (adjust size as needed)
		drop_zone.custom_minimum_size = Vector2(200, 200)
		drop_zone.position = Vector2(-100, -100)
		pet_node.add_child(drop_zone)
	
	# Attach script to handle drop
	drop_zone.set_script(load("res://scripts/pet_drop_zone.gd"))
	if drop_zone.has_method("set_fridge_ref"):
		drop_zone.set_fridge_ref(self)

# --- Check if data can be dropped on pet ---
func _can_drop_on_pet(_position: Vector2, data: Variant) -> bool:
	if is_eating:
		return false
	
	if data is Dictionary and data.has("food_index"):
		return true
	return false

# --- Handle drop on pet ---
func _on_drop_on_pet(_position: Vector2, data: Variant) -> void:
	if is_eating:
		return
	
	if not (data is Dictionary and data.has("food_index")):
		return
	
	var food_index: int = data["food_index"]
	if food_index >= all_food_spritesheets.size():
		return
	
	var selected_food_frames: SpriteFrames = all_food_spritesheets[food_index]
	if not selected_food_frames:
		return
	
	# Start eating sequence
	_start_eating_sequence(selected_food_frames)
