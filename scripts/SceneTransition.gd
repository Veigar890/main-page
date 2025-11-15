extends CanvasLayer

# Scene transition singleton for smooth fade in/out effects

var transition_color := Color(1, 0.96, 0.86, 1)  # Cream white background
var transition_duration := 0.5  # Duration in seconds (increased for smoother transition)

var color_rect: ColorRect
var loading_label: Label
var is_transitioning := false  # Flag to prevent multiple transitions
var minecraft_font: FontFile

func _ready():
	# Create ColorRect for transition overlay
	color_rect = ColorRect.new()
	color_rect.color = transition_color
	color_rect.mouse_filter = Control.MOUSE_FILTER_STOP  # Block all input during transition
	add_child(color_rect)
	
	# Set up ColorRect to cover entire screen
	color_rect.anchors_preset = Control.PRESET_FULL_RECT
	color_rect.anchor_left = 0.0
	color_rect.anchor_top = 0.0
	color_rect.anchor_right = 1.0
	color_rect.anchor_bottom = 1.0
	color_rect.offset_left = 0
	color_rect.offset_top = 0
	color_rect.offset_right = 0
	color_rect.offset_bottom = 0
	
	# Start with transparent (no overlay visible)
	color_rect.modulate.a = 0.0
	color_rect.visible = false
	
	# Load Minecraft font
	minecraft_font = load("res://assets/font/Minecraft.ttf") as FontFile
	
	# Create loading label
	loading_label = Label.new()
	loading_label.text = "Loading..."
	loading_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	loading_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	loading_label.add_theme_color_override("font_color", Color(0.2, 0.2, 0.2, 1))  # Dark text for cream background
	loading_label.add_theme_font_size_override("font_size", 32)
	if minecraft_font:
		loading_label.add_theme_font_override("font", minecraft_font)
	loading_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(loading_label)
	
	# Center the loading label
	loading_label.anchors_preset = Control.PRESET_CENTER
	loading_label.anchor_left = 0.5
	loading_label.anchor_top = 0.5
	loading_label.anchor_right = 0.5
	loading_label.anchor_bottom = 0.5
	loading_label.offset_left = -100
	loading_label.offset_top = -20
	loading_label.offset_right = 100
	loading_label.offset_bottom = 20
	
	# Start with invisible
	loading_label.modulate.a = 0.0
	loading_label.visible = false

# --- TRANSITION TO SCENE WITH FADE ---
func transition_to_scene(scene_path: String) -> void:
	# Prevent multiple transitions
	if is_transitioning:
		return
	
	# Set flag and block input immediately
	is_transitioning = true
	
	# Show overlay and loading text immediately (overlay blocks input)
	color_rect.mouse_filter = Control.MOUSE_FILTER_STOP  # Block input first
	color_rect.visible = true
	loading_label.visible = true
	
	# Fade out current scene
	var tween = create_tween()
	tween.set_parallel(true)
	
	# Fade to cream white with smooth easing
	tween.tween_property(color_rect, "modulate:a", 1.0, transition_duration).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)
	
	# Fade in loading text
	tween.tween_property(loading_label, "modulate:a", 1.0, transition_duration * 0.5).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_SINE)
	
	# Wait for fade out, then change scene
	await tween.finished
	_change_scene(scene_path)
	
	# Small delay to ensure scene is loaded
	await get_tree().process_frame
	await get_tree().process_frame
	
	# Fade in new scene
	var fade_in_tween = create_tween()
	fade_in_tween.set_parallel(true)
	
	# Fade out overlay with smooth easing
	fade_in_tween.tween_property(color_rect, "modulate:a", 0.0, transition_duration).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)
	
	# Fade out loading text
	fade_in_tween.tween_property(loading_label, "modulate:a", 0.0, transition_duration * 0.5).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_SINE)
	
	# Hide after fade
	await fade_in_tween.finished
	color_rect.visible = false
	color_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE  # Re-enable input
	loading_label.visible = false
	
	# Re-enable transitions
	is_transitioning = false

# --- CHANGE SCENE (called during fade) ---
func _change_scene(scene_path: String) -> void:
	get_tree().change_scene_to_file(scene_path)

# --- SET TRANSITION COLOR ---
func set_transition_color(color: Color) -> void:
	transition_color = color
	if color_rect:
		color_rect.color = transition_color

# --- SET TRANSITION DURATION ---
func set_transition_duration(duration: float) -> void:
	transition_duration = duration
