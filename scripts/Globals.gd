extends Node

var selected_item: String = ""

# Dictionary to store selected items per category
var wardrobe_selection = {
	"shirt": null,
	"skirt": null,
	"accessories": null,
	"shoes": null
}

# Settings preferences
var music_enabled: bool = true
var audio_enabled: bool = true

# Pet status (can be accessed from any scene)
var pet_status: Pet.PetStatus = Pet.PetStatus.IDLE

func _ready():
	# Ensure pet status is IDLE on startup
	pet_status = Pet.PetStatus.IDLE
	# Load saved preferences
	_load_preferences()

# --- LOAD PREFERENCES ---
func _load_preferences() -> void:
	# Load settings
	var settings = Preferences.load_settings()
	music_enabled = settings.get("music_enabled", true)
	audio_enabled = settings.get("audio_enabled", true)
	
	# Load wardrobe selections
	wardrobe_selection = Preferences.load_wardrobe_selections()

# --- SAVE WARDROBE SELECTION ---
func save_wardrobe_selection(category: String, texture: Texture2D) -> void:
	wardrobe_selection[category] = texture
	Preferences.save_wardrobe_selection(category, texture.resource_path if texture else "")

# --- SAVE ALL WARDROBE SELECTIONS ---
func save_all_wardrobe_selections() -> void:
	Preferences.save_all_wardrobe_selections(wardrobe_selection)

# --- SAVE SETTINGS ---
func save_settings() -> void:
	Preferences.save_settings(music_enabled, audio_enabled)
