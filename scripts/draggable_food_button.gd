extends Button

var fridge_ref: Node = null
var item_index: int = -1
var drag_start_pos: Vector2 = Vector2.ZERO
var drag_threshold: float = 10.0  # Minimum distance to start drag
var is_dragging: bool = false
var drag_preview: Control = null

func setup_drag(fridge: Node, index: int) -> void:
	fridge_ref = fridge
	item_index = index

func _gui_input(event: InputEvent) -> void:
	if not fridge_ref:
		return
	
	# Check if eating is in progress
	if fridge_ref and fridge_ref.is_eating:
		return
	
	# Check if item is locked (disabled)
	if disabled:
		return
	
	# Track mouse press for drag detection
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			drag_start_pos = get_global_mouse_position()
			is_dragging = false
		else:
			# Mouse released - check if we were dragging
			if is_dragging:
				# Check if dropped on pet
				_check_drop_on_pet()
			# Clean up
			if drag_preview:
				drag_preview.queue_free()
				drag_preview = null
			drag_start_pos = Vector2.ZERO
			is_dragging = false
	
	# Check if mouse moved enough to start drag
	if event is InputEventMouseMotion:
		if drag_start_pos != Vector2.ZERO and not is_dragging:
			var current_pos = get_global_mouse_position()
			var drag_distance = current_pos.distance_to(drag_start_pos)
			if drag_distance > drag_threshold:
				# Start dragging
				is_dragging = true
				_start_drag()
				# Cancel the button press to prevent click
				accept_event()
		
		# Update drag preview position
		if is_dragging and drag_preview:
			drag_preview.global_position = get_global_mouse_position() - Vector2(32, 32)

func _start_drag() -> void:
	var drag_data = _prepare_drag_data()
	if not drag_data:
		return
	
	# Create and show drag preview
	drag_preview = _create_drag_preview()
	if drag_preview:
		var viewport = get_viewport()
		if viewport:
			viewport.add_child(drag_preview)
			drag_preview.global_position = get_global_mouse_position() - Vector2(32, 32)
			drag_preview.z_index = 1000  # Make sure it's on top

func _check_drop_on_pet() -> void:
	if not fridge_ref or not is_dragging:
		return
	
	# Get mouse position in world space
	var mouse_pos = get_global_mouse_position()
	
	# Check if mouse is over pet drop zone
	var pet_node = fridge_ref.get_node_or_null("PET2")
	if not pet_node:
		return
	
	var drop_zone = pet_node.get_node_or_null("DropZone")
	if not drop_zone:
		return
	
	# Check if mouse is within drop zone bounds
	var drop_zone_global_pos = drop_zone.global_position
	var drop_zone_size = drop_zone.size
	var drop_rect = Rect2(drop_zone_global_pos, drop_zone_size)
	
	if drop_rect.has_point(mouse_pos):
		# Dropped on pet!
		var drag_data = _prepare_drag_data()
		if drag_data and drag_data is Dictionary and "food_index" in drag_data:
			if fridge_ref.has_method("_on_drop_on_pet"):
				fridge_ref._on_drop_on_pet(mouse_pos, drag_data)

func _prepare_drag_data() -> Variant:
	if not fridge_ref:
		return null
	
	# Check if eating is in progress
	if fridge_ref and fridge_ref.is_eating:
		return null
	
	# Check if item is locked (disabled)
	if disabled:
		return null
	
	# Get food index (directly access properties since we know they exist)
	var current_page = fridge_ref.current_page
	var items_per_page = fridge_ref.items_per_page
	var food_index: int = current_page * items_per_page + item_index
	
	# Get food arrays from fridge
	var all_foods = fridge_ref.all_foods
	var all_food_spritesheets = fridge_ref.all_food_spritesheets
	
	if food_index >= all_foods.size() or food_index >= all_food_spritesheets.size():
		return null
	
	# Return drag data
	return {
		"food_index": food_index,
		"source_button": self
	}

func _create_drag_preview() -> Control:
	if not fridge_ref:
		return null
	
	# Directly access properties since we know they exist
	var current_page = fridge_ref.current_page
	var items_per_page = fridge_ref.items_per_page
	var food_index: int = current_page * items_per_page + item_index
	var all_foods = fridge_ref.all_foods
	
	if food_index >= all_foods.size():
		return null
	
	var food_texture: Texture2D = all_foods[food_index]
	if not food_texture:
		return null
	
	# Create drag preview
	var preview = TextureRect.new()
	preview.texture = food_texture
	preview.custom_minimum_size = Vector2(64, 64)
	preview.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
	preview.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return preview

func get_drag_data(_pos: Vector2) -> Variant:
	# This is called by Godot's automatic drag system as fallback
	# But we handle drag manually, so return null to prevent conflicts
	return null
