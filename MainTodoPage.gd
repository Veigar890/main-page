extends Node2D

var academic_tasks = []
var household_tasks = []
var errands_tasks = []
var total_points = 0

@onready var overall_progress_label = $OverallProgressLabel
@onready var overall_progress_bar = $OverallProgressBar
@onready var academic_progress = $AcademicButton/AcademicProgressBar
@onready var household_progress = $HouseholdButton/HouseholdProgressBar
@onready var errands_progress = $ErrandsButton/ErrandsProgressBar
@onready var academic_percent_label = $AcademicButton/AcademicProgressBar/AcademicPercentLabel
@onready var household_percent_label = $HouseholdButton/HouseholdProgressBar/HouseholdPercentLabel
@onready var errands_percent_label = $ErrandsButton/ErrandsProgressBar/ErrandsPercentLabel
@onready var points_label = $PointsLabel

func _ready():
	print("=== MainTodoPage Starting ===")
	$AcademicButton.connect("pressed", Callable(self, "_on_academic_pressed"))
	$HouseholdButton.connect("pressed", Callable(self, "_on_household_pressed"))
	$ErrandsButton.connect("pressed", Callable(self, "_on_errands_pressed"))
	$BackButton.connect("pressed", Callable(self, "_on_back_pressed"))
	
	# Load saved tasks
	_load_tasks()
	
	update_all_progress()
	update_points_display()
	print("=== MainTodoPage Ready ===")

func _on_academic_pressed():
	var scene = load("res://TaskDetailPage.tscn").instantiate()
	scene.category = "Academic Tasks"
	scene.tasks = academic_tasks
	scene.main_page = self
	get_tree().get_root().add_child(scene)
	visible = false

func _on_household_pressed():
	var scene = load("res://TaskDetailPage.tscn").instantiate()
	scene.category = "Household Chores"
	scene.tasks = household_tasks
	scene.main_page = self
	get_tree().get_root().add_child(scene)
	visible = false

func _on_errands_pressed():
	var scene = load("res://TaskDetailPage.tscn").instantiate()
	scene.category = "Errands"
	scene.tasks = errands_tasks
	scene.main_page = self
	get_tree().get_root().add_child(scene)
	visible = false

func _on_back_pressed():
	SceneTransition.transition_to_scene("res://scenes/node_2d.tscn")

func calculate_points(deadline_string):
	print("=== CALCULATING POINTS ===")
	print("Deadline string: ", deadline_string)
	
	var deadline = parse_deadline(deadline_string)
	if deadline == null:
		print("❌ Failed to parse deadline")
		return 0
	
	var current_time = Time.get_datetime_dict_from_system()
	print("Current time: ", current_time)
	print("Deadline: ", deadline)
	
	# FIXED: Use proper date difference calculation
	var days_until = days_between_dates(current_time, deadline)
	print("Days until deadline: ", days_until)
	
	var points = 0
	if days_until >= 365:
		points = 50
	elif days_until >= 60 and days_until <= 364:
		points = 40
	elif days_until >= 21 and days_until <= 59:
		points = 30
	elif days_until >= 7 and days_until <= 20:
		points = 20
	elif days_until == 6:
		points = 10
	elif days_until == 5:
		points = 8
	elif days_until == 4:
		points = 6
	elif days_until == 3:
		points = 4
	elif days_until == 2:
		points = 3
	elif days_until == 1:
		points = 2
	elif days_until == 0:
		points = 1
	else:
		points = 0
	
	print("✓ Points calculated: ", points)
	return points

func parse_deadline(datetime_string):
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

# FIXED: Correct date difference calculation
func days_between_dates(current, deadline):
	# Convert both dates to "days since epoch"
	var current_days = date_to_days(current.year, current.month, current.day)
	var deadline_days = date_to_days(deadline.year, deadline.month, deadline.day)
	
	print("Current total days: ", current_days)
	print("Deadline total days: ", deadline_days)
	
	return deadline_days - current_days

func date_to_days(year, month, day):
	# Days in each month (non-leap year)
	var days_in_month = [31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31]
	
	# Count total days
	var total = 0
	
	# Add days for all complete years since year 0
	total += year * 365
	
	# Add leap year days for years before this one
	total += int(year / 4) - int(year / 100) + int(year / 400)
	
	# Check if current year is leap year
	var is_leap = (year % 4 == 0 and year % 100 != 0) or (year % 400 == 0)
	if is_leap:
		days_in_month[1] = 29
	
	# Add days for complete months in current year
	for m in range(month - 1):
		total += days_in_month[m]
	
	# Add days in current month
	total += day
	
	return total

func update_points_display():
	if points_label:
		points_label.text = "Total Points: " + str(total_points)
		print("✓ Points display updated: ", total_points)
	else:
		print("❌ WARNING: PointsLabel not found!")

func update_all_progress():
	update_category_progress(academic_tasks, academic_progress, academic_percent_label)
	update_category_progress(household_tasks, household_progress, household_percent_label)
	update_category_progress(errands_tasks, errands_progress, errands_percent_label)
	update_overall_progress()

func update_category_progress(tasks, progress_bar, percent_label):
	if tasks.size() == 0:
		progress_bar.value = 0
		percent_label.text = "0%"
		apply_progress_color(progress_bar, 0)
		return
	
	var completed = 0
	for task in tasks:
		if task.status == "completed":
			completed += 1
	
	var percent = float(completed) / float(tasks.size()) * 100.0
	progress_bar.value = percent
	percent_label.text = "%d%%" % int(percent)
	apply_progress_color(progress_bar, percent)

func update_overall_progress():
	var total_tasks = academic_tasks.size() + household_tasks.size() + errands_tasks.size()
	
	if total_tasks == 0:
		overall_progress_bar.value = 0
		overall_progress_label.text = "Overall Progress: 0%"
		apply_progress_color(overall_progress_bar, 0)
		return
	
	var completed = 0
	for task in academic_tasks:
		if task.status == "completed":
			completed += 1
	for task in household_tasks:
		if task.status == "completed":
			completed += 1
	for task in errands_tasks:
		if task.status == "completed":
			completed += 1
	
	var percent = float(completed) / float(total_tasks) * 100.0
	overall_progress_bar.value = percent
	overall_progress_label.text = "Overall Progress: %d%%" % int(percent)
	apply_progress_color(overall_progress_bar, percent)

func apply_progress_color(progress_bar, percent):
	var tint_color = Color(1, 1, 1)
	
	if percent == 0:
		tint_color = Color(1.0, 0.2, 0.2)
	elif percent <= 20:
		tint_color = Color(1.0, 0.6, 0.0)
	elif percent <= 40:
		var t = (percent - 20) / 20.0
		tint_color = Color(1.0, 0.6 + (0.4 * t), 0.0)
	elif percent <= 60:
		tint_color = Color(1.0, 1.0, 0.0)
	elif percent <= 80:
		var t = (percent - 60) / 20.0
		tint_color = Color(1.0 - (0.4 * t), 1.0, 0.0)
	else:
		tint_color = Color(0.0, 1.0, 0.0)
	
	progress_bar.tint_progress = tint_color

# --- LOAD TASKS ---
func _load_tasks() -> void:
	var tasks_data = Preferences.load_tasks()
	academic_tasks = tasks_data.get("academic_tasks", [])
	household_tasks = tasks_data.get("household_tasks", [])
	errands_tasks = tasks_data.get("errands_tasks", [])
	total_points = tasks_data.get("total_points", 0)
	print("✓ Loaded tasks: Academic=%d, Household=%d, Errands=%d, Points=%d" % [academic_tasks.size(), household_tasks.size(), errands_tasks.size(), total_points])
	
	# Check for overdue tasks and update pet status
	Globals.check_tasks_and_update_pet_status()

# --- SAVE TASKS ---
func _save_tasks() -> void:
	Preferences.save_tasks(academic_tasks, household_tasks, errands_tasks, total_points)
	print("✓ Saved tasks: Academic=%d, Household=%d, Errands=%d, Points=%d" % [academic_tasks.size(), household_tasks.size(), errands_tasks.size(), total_points])
	
	# Check for overdue tasks and update pet status after saving
	Globals.check_tasks_and_update_pet_status()
