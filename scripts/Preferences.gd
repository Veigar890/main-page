extends Node

# Preferences manager for saving and loading app settings and wardrobe selections

const PREFERENCES_PATH := "user://preferences.cfg"
const SETTINGS_SECTION := "settings"
const WARDROBE_SECTION := "wardrobe"
const LEVEL_SECTION := "level"
const FEED_COUNT_SECTION := "feed_counts"
const TASKS_SECTION := "tasks"

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

# --- SAVE FEED COUNTS ---
func save_feed_counts(feed_counts: Dictionary) -> void:
	var config = ConfigFile.new()
	
	# Load existing config if it exists
	if FileAccess.file_exists(PREFERENCES_PATH):
		var load_error = config.load(PREFERENCES_PATH)
		if load_error != OK:
			push_error("Failed to load preferences: %s" % error_string(load_error))
	
	# Save all feed counts
	for food_index in feed_counts.keys():
		config.set_value(FEED_COUNT_SECTION, str(food_index), feed_counts[food_index])
	
	# Save to file
	var save_error = config.save(PREFERENCES_PATH)
	if save_error != OK:
		push_error("Failed to save feed counts: %s" % error_string(save_error))

# --- LOAD FEED COUNTS ---
func load_feed_counts() -> Dictionary:
	var feed_counts: Dictionary = {}
	
	if not FileAccess.file_exists(PREFERENCES_PATH):
		return feed_counts
	
	var config = ConfigFile.new()
	var load_error = config.load(PREFERENCES_PATH)
	if load_error != OK:
		push_error("Failed to load preferences: %s" % error_string(load_error))
		return feed_counts
	
	# Load all feed counts from the section
	if config.has_section(FEED_COUNT_SECTION):
		var keys = config.get_section_keys(FEED_COUNT_SECTION)
		for key in keys:
			var food_index = int(key)
			var feed_count = config.get_value(FEED_COUNT_SECTION, key, 0)
			if feed_count is int and feed_count >= 0:
				feed_counts[food_index] = feed_count
	
	return feed_counts

# --- INCREMENT FEED COUNT ---
func increment_feed_count(food_index: int) -> void:
	var feed_counts = load_feed_counts()
	var current_count = feed_counts.get(food_index, 0)
	feed_counts[food_index] = current_count + 1
	save_feed_counts(feed_counts)

# --- SAVE TASKS ---
func save_tasks(academic_tasks: Array, household_tasks: Array, errands_tasks: Array, total_points: int) -> void:
	var config = ConfigFile.new()
	
	# Load existing config if it exists
	if FileAccess.file_exists(PREFERENCES_PATH):
		var load_error = config.load(PREFERENCES_PATH)
		if load_error != OK:
			push_error("Failed to load preferences: %s" % error_string(load_error))
	
	# Save tasks arrays (ConfigFile can save arrays and dictionaries)
	config.set_value(TASKS_SECTION, "academic_tasks", academic_tasks)
	config.set_value(TASKS_SECTION, "household_tasks", household_tasks)
	config.set_value(TASKS_SECTION, "errands_tasks", errands_tasks)
	config.set_value(TASKS_SECTION, "total_points", total_points)
	
	# Save to file
	var save_error = config.save(PREFERENCES_PATH)
	if save_error != OK:
		push_error("Failed to save tasks: %s" % error_string(save_error))

# --- LOAD TASKS ---
func load_tasks() -> Dictionary:
	var default_data = {
		"academic_tasks": [],
		"household_tasks": [],
		"errands_tasks": [],
		"total_points": 0
	}
	
	if not FileAccess.file_exists(PREFERENCES_PATH):
		return default_data
	
	var config = ConfigFile.new()
	var load_error = config.load(PREFERENCES_PATH)
	if load_error != OK:
		push_error("Failed to load preferences: %s" % error_string(load_error))
		return default_data
	
	# Load tasks with defaults
	var academic_tasks = config.get_value(TASKS_SECTION, "academic_tasks", [])
	var household_tasks = config.get_value(TASKS_SECTION, "household_tasks", [])
	var errands_tasks = config.get_value(TASKS_SECTION, "errands_tasks", [])
	var total_points = config.get_value(TASKS_SECTION, "total_points", 0)
	
	# Ensure arrays are valid
	if not academic_tasks is Array:
		academic_tasks = []
	if not household_tasks is Array:
		household_tasks = []
	if not errands_tasks is Array:
		errands_tasks = []
	if not total_points is int or total_points < 0:
		total_points = 0
	
	return {
		"academic_tasks": academic_tasks,
		"household_tasks": household_tasks,
		"errands_tasks": errands_tasks,
		"total_points": total_points
	}
