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

# Scene to return to when closing task list
var task_return_scene_path: String = "res://scenes/node_2d.tscn"

# Player level (starts at 1)
var player_level: int = 1
var player_exp: int = 0  # Current EXP
var exp_per_level: int = 50  # EXP needed per level (can be adjusted)

# Feed counts per food item (food_index -> feed_count)
var food_feed_counts: Dictionary = {}

func _ready():
	# Ensure pet status is IDLE on startup
	pet_status = Pet.PetStatus.IDLE
	task_return_scene_path = "res://scenes/node_2d.tscn"
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

# --- CHECK FOR OVERDUE TASKS AND UPDATE PET STATUS ---
func check_tasks_and_update_pet_status() -> void:
	# Only check if pet is not eating (don't interrupt eating animation)
	if pet_status == Pet.PetStatus.EATING:
		return
	
	var has_overdue_or_missed = _check_for_overdue_tasks()
	
	if has_overdue_or_missed:
		# Set pet to angry if there are overdue/missed tasks
		if pet_status != Pet.PetStatus.ANGRY:
			pet_status = Pet.PetStatus.ANGRY
			# Update pet node if it exists in the current scene
			_update_pet_node_status()
	else:
		# Set pet to idle if no overdue/missed tasks
		if pet_status == Pet.PetStatus.ANGRY:
			pet_status = Pet.PetStatus.IDLE
			_update_pet_node_status()

# --- CHECK FOR OVERDUE TASKS ---
func _check_for_overdue_tasks() -> bool:
	# Load tasks from preferences
	var tasks_data = Preferences.load_tasks()
	var academic_tasks = tasks_data.get("academic_tasks", [])
	var household_tasks = tasks_data.get("household_tasks", [])
	var errands_tasks = tasks_data.get("errands_tasks", [])
	
	var current_time = Time.get_datetime_dict_from_system()
	
	# Check all task categories
	var all_tasks = academic_tasks + household_tasks + errands_tasks
	
	for task in all_tasks:
		# Check if task is not completed
		if task.status != "completed":
			var deadline = _parse_datetime(task.deadline)
			if deadline == null:
				continue
			
			if not _is_same_day(current_time, deadline):
				continue
			
			# Check if task is missed
			if task.status == "missed":
				return true
			
			# Check if task is overdue (not completed and past deadline)
			if _is_overdue(current_time, deadline):
				return true
	
	return false

# --- PARSE DATETIME STRING ---
func _parse_datetime(datetime_string: String):
	var parts = datetime_string.split(" ")
	if parts.size() < 3:
		return null
	
	var date_parts = parts[0].split("-")
	var time_parts = parts[1].split(":")
	
	if date_parts.size() != 3 or time_parts.size() != 2:
		return null
	
	var hour = int(time_parts[0])
	var period = parts[2].to_upper()
	
	if period == "PM" and hour != 12:
		hour += 12
	elif period == "AM" and hour == 12:
		hour = 0
	
	return {
		"year": int(date_parts[0]),
		"month": int(date_parts[1]),
		"day": int(date_parts[2]),
		"hour": hour,
		"minute": int(time_parts[1])
	}

# --- CHECK IF TASK IS OVERDUE ---
func _is_overdue(current: Dictionary, deadline) -> bool:
	if deadline == null:
		return false
	
	if current.year > deadline.year:
		return true
	elif current.year < deadline.year:
		return false
	if current.month > deadline.month:
		return true
	elif current.month < deadline.month:
		return false
	if current.day > deadline.day:
		return true
	elif current.day < deadline.day:
		return false
	if current.hour > deadline.hour:
		return true
	elif current.hour < deadline.hour:
		return false
	if current.minute > deadline.minute:
		return true
	return false

# --- CHECK IF TWO DATES SHARE THE SAME CALENDAR DAY ---
func _is_same_day(first: Dictionary, second: Dictionary) -> bool:
	return first.year == second.year and first.month == second.month and first.day == second.day

# --- UPDATE PET NODE STATUS IN CURRENT SCENE ---
func _update_pet_node_status() -> void:
	# Try to find pet node in the current scene tree
	var scene_tree = Engine.get_main_loop()
	if not scene_tree:
		return
	
	var root = scene_tree.current_scene
	if not root:
		return
	
	# Look for pet node (could be named "PET" or "PET2")
	var pet_node = root.get_node_or_null("PET")
	if not pet_node:
		pet_node = root.get_node_or_null("PET2")
	
	if pet_node and pet_node is Pet:
		pet_node.set_status(pet_status)
