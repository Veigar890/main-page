extends CanvasLayer

@export var menu_visible: bool = false:
	set(value):
		menu_visible = value
		visible = value

@onready var music_checkbutton = $Control/CheckButton
@onready var audio_checkbutton = $Control/CheckButton2

func _ready():
	visible = menu_visible
	
	# Load saved preferences
	_load_preferences()
	AudioManager.ensure_music_state()
	
	# Connect checkbutton signals
	if music_checkbutton:
		music_checkbutton.toggled.connect(_on_music_toggled)
	if audio_checkbutton:
		audio_checkbutton.toggled.connect(_on_audio_toggled)

# --- LOAD PREFERENCES ---
func _load_preferences() -> void:
	if music_checkbutton:
		music_checkbutton.button_pressed = Globals.music_enabled
	if audio_checkbutton:
		audio_checkbutton.button_pressed = Globals.audio_enabled

# --- HANDLE SETTINGS TOGGLES ---
func _on_music_toggled(button_pressed: bool) -> void:
	AudioManager.play_click()
	Globals.music_enabled = button_pressed
	Globals.save_settings()
	AudioManager.ensure_music_state()

func _on_audio_toggled(button_pressed: bool) -> void:
	AudioManager.play_click()
	Globals.audio_enabled = button_pressed
	Globals.save_settings()

func _on_texture_button_pressed() -> void:
	AudioManager.play_click()
	menu_visible = false
