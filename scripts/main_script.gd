extends Node2D

# --- Node references ---
@onready var progress_bar: TextureProgressBar = $MainBG/Control/ProgressBar
@onready var level_label: Label = $MainBG/Control/ProgressBar/Level

func _ready() -> void:
	# Update level display when scene loads
	_update_level_display()

func _on_settings_pressed() -> void:
	$Menu.menu_visible = true

func _on_wardrobe_pressed() -> void:
	SceneTransition.transition_to_scene("res://scenes/wardrobe.tscn")

func _on_fridge_pressed() -> void:
	SceneTransition.transition_to_scene("res://scenes/fridge.tscn")

# --- UPDATE LEVEL DISPLAY ---
func _update_level_display() -> void:
	if not progress_bar or not level_label:
		return
	
	# Update level label
	level_label.text = "LEVEL %d" % Globals.player_level
	
	# Update progress bar (showing EXP progress)
	# TextureProgressBar uses value directly (0-100 range is default)
	var exp_progress = Globals.get_exp_progress()
	progress_bar.value = exp_progress * 100.0

# --- Called when node enters scene tree ---
func _enter_tree() -> void:
	# Update display when scene becomes active
	_update_level_display()
