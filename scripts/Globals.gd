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

# Player level (starts at 1)
var player_level: int = 1
var player_exp: int = 0  # Current EXP
var exp_per_level: int = 100  # EXP needed per level (can be adjusted)

# Feed counts per food item (food_index -> feed_count)
var food_feed_counts: Dictionary = {}

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
	
	# Load player level and EXP
	var level_data = Preferences.load_level_data()
	player_level = level_data.get("level", 1)
	player_exp = level_data.get("exp", 0)
	
	# Load feed counts
	food_feed_counts = Preferences.load_feed_counts()

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

# --- SAVE LEVEL DATA ---
func save_level_data() -> void:
	Preferences.save_level_data(player_level, player_exp)

# --- SET LEVEL (for manual testing) ---
func set_level(level: int) -> void:
	if level < 1:
		level = 1
	player_level = level
	player_exp = 0  # Reset EXP when manually setting level
	save_level_data()

# --- ADD EXP ---
func add_exp(amount: int) -> void:
	if amount <= 0:
		return
	
	player_exp += amount
	
	# Check for level ups and handle excess EXP
	while player_exp >= exp_per_level:
		# Calculate excess EXP
		var excess_exp = player_exp - exp_per_level
		# Level up
		player_level += 1
		# Set EXP to the excess (carry over to new level)
		player_exp = excess_exp
	
	save_level_data()

# --- GET EXP PROGRESS (0.0 to 1.0) ---
func get_exp_progress() -> float:
	return float(player_exp) / float(exp_per_level)

# --- GET FEED COUNT FOR FOOD ITEM ---
func get_feed_count(food_index: int) -> int:
	return food_feed_counts.get(food_index, 0)

# --- INCREMENT FEED COUNT FOR FOOD ITEM ---
func increment_feed_count(food_index: int) -> void:
	var current_count = food_feed_counts.get(food_index, 0)
	food_feed_counts[food_index] = current_count + 1
	Preferences.increment_feed_count(food_index)

# --- CHECK IF FOOD ITEM CAN BE FED (max 3 feeds) ---
func can_feed_food(food_index: int) -> bool:
	return get_feed_count(food_index) < 3
