extends Node

# Preferences manager for saving and loading app settings and wardrobe selections

const PREFERENCES_PATH := "user://preferences.cfg"
const SETTINGS_SECTION := "settings"
const WARDROBE_SECTION := "wardrobe"
const LEVEL_SECTION := "level"

# --- SAVE SETTINGS ---
func save_settings(music_enabled: bool, audio_enabled: bool) -> void:
	var config = ConfigFile.new()
	
	# Load existing config if it exists
	if FileAccess.file_exists(PREFERENCES_PATH):
		var load_error = config.load(PREFERENCES_PATH)
		if load_error != OK:
			push_error("Failed to load preferences: %s" % error_string(load_error))
	
	# Save settings
	config.set_value(SETTINGS_SECTION, "music_enabled", music_enabled)
	config.set_value(SETTINGS_SECTION, "audio_enabled", audio_enabled)
	
	# Save to file
	var save_error = config.save(PREFERENCES_PATH)
	if save_error != OK:
		push_error("Failed to save preferences: %s" % error_string(save_error))

# --- LOAD SETTINGS ---
func load_settings() -> Dictionary:
	var settings = {
		"music_enabled": true,  # Default to enabled
		"audio_enabled": true   # Default to enabled
	}
	
	if not FileAccess.file_exists(PREFERENCES_PATH):
		return settings
	
	var config = ConfigFile.new()
	var load_error = config.load(PREFERENCES_PATH)
	if load_error != OK:
		push_error("Failed to load preferences: %s" % error_string(load_error))
		return settings
	
	# Load settings with defaults
	if config.has_section_key(SETTINGS_SECTION, "music_enabled"):
		settings["music_enabled"] = config.get_value(SETTINGS_SECTION, "music_enabled", true)
	if config.has_section_key(SETTINGS_SECTION, "audio_enabled"):
		settings["audio_enabled"] = config.get_value(SETTINGS_SECTION, "audio_enabled", true)
	
	return settings

# --- SAVE WARDROBE SELECTION ---
func save_wardrobe_selection(category: String, texture_path: String) -> void:
	var config = ConfigFile.new()
	
	# Load existing config if it exists
	if FileAccess.file_exists(PREFERENCES_PATH):
		var load_error = config.load(PREFERENCES_PATH)
		if load_error != OK:
			push_error("Failed to load preferences: %s" % error_string(load_error))
	
	# Save wardrobe selection
	config.set_value(WARDROBE_SECTION, category, texture_path)
	
	# Save to file
	var save_error = config.save(PREFERENCES_PATH)
	if save_error != OK:
		push_error("Failed to save wardrobe preferences: %s" % error_string(save_error))

# --- SAVE ALL WARDROBE SELECTIONS ---
func save_all_wardrobe_selections(wardrobe_selection: Dictionary) -> void:
	var config = ConfigFile.new()
	
	# Load existing config if it exists
	if FileAccess.file_exists(PREFERENCES_PATH):
		var load_error = config.load(PREFERENCES_PATH)
		if load_error != OK:
			push_error("Failed to load preferences: %s" % error_string(load_error))
	
	# Save all wardrobe selections
	for category in wardrobe_selection.keys():
		var texture = wardrobe_selection[category]
		if texture != null:
			# Get the resource path of the texture
			var texture_path = texture.resource_path if texture.resource_path else ""
			if not texture_path.is_empty():
				config.set_value(WARDROBE_SECTION, category, texture_path)
	
	# Save to file
	var save_error = config.save(PREFERENCES_PATH)
	if save_error != OK:
		push_error("Failed to save wardrobe preferences: %s" % error_string(save_error))

# --- LOAD WARDROBE SELECTIONS ---
func load_wardrobe_selections() -> Dictionary:
	var wardrobe = {
		"shirt": null,
		"skirt": null,
		"accessories": null,
		"shoes": null
	}
	
	if not FileAccess.file_exists(PREFERENCES_PATH):
		return wardrobe
	
	var config = ConfigFile.new()
	var load_error = config.load(PREFERENCES_PATH)
	if load_error != OK:
		push_error("Failed to load preferences: %s" % error_string(load_error))
		return wardrobe
	
	# Load wardrobe selections
	for category in wardrobe.keys():
		if config.has_section_key(WARDROBE_SECTION, category):
			var texture_path = config.get_value(WARDROBE_SECTION, category, "")
			if not texture_path.is_empty():
				var texture = load(texture_path) as Texture2D
				if texture:
					wardrobe[category] = texture
	
	return wardrobe

# --- SAVE LEVEL DATA ---
func save_level_data(level: int, exp_value: int) -> void:
	var config = ConfigFile.new()
	
	# Load existing config if it exists
	if FileAccess.file_exists(PREFERENCES_PATH):
		var load_error = config.load(PREFERENCES_PATH)
		if load_error != OK:
			push_error("Failed to load preferences: %s" % error_string(load_error))
	
	# Save level and EXP
	config.set_value(LEVEL_SECTION, "player_level", level)
	config.set_value(LEVEL_SECTION, "player_exp", exp_value)
	
	# Save to file
	var save_error = config.save(PREFERENCES_PATH)
	if save_error != OK:
		push_error("Failed to save level data: %s" % error_string(save_error))

# --- LOAD LEVEL DATA ---
func load_level_data() -> Dictionary:
	var default_data = {
		"level": 1,
		"exp": 0
	}
	
	if not FileAccess.file_exists(PREFERENCES_PATH):
		return default_data
	
	var config = ConfigFile.new()
	var load_error = config.load(PREFERENCES_PATH)
	if load_error != OK:
		push_error("Failed to load preferences: %s" % error_string(load_error))
		return default_data
	
	# Load level and EXP with defaults
	var level = 1
	var exp_value = 0
	
	if config.has_section_key(LEVEL_SECTION, "player_level"):
		level = config.get_value(LEVEL_SECTION, "player_level", 1)
		if level < 1:
			level = 1
	
	if config.has_section_key(LEVEL_SECTION, "player_exp"):
		exp_value = config.get_value(LEVEL_SECTION, "player_exp", 0)
		if exp_value < 0:
			exp_value = 0
	
	return {
		"level": level,
		"exp": exp_value
	}
