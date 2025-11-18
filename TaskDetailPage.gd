extends Node2D

var category = ""
var tasks = []
var main_page = null
var task_item_scene = preload("res://TaskItem.tscn")

@onready var category_label = $CategoryLabel
@onready var category_progress = $CategoryProgressBar
@onready var category_percent_label = $CategoryProgressBar/CategoryPercentLabel
@onready var task_list = $TaskScrollContainer/TaskList
@onready var popup = $TaskInputPopup
@onready var task_name_input = $TaskInputPopup/PopupContent/TaskNameInput
@onready var due_date_input = $TaskInputPopup/PopupContent/DateTimeRow/DueDateInput
@onready var ampm_selector = $TaskInputPopup/PopupContent/DateTimeRow/AMPMSelector
@onready var cancel_button = $TaskInputPopup/PopupContent/PopupButtons/CancelButton
@onready var add_button = $TaskInputPopup/PopupContent/PopupButtons/ConfirmAddButton
@onready var congrats_popup = $CongratsPopup
@onready var points_earned_label = $CongratsPopup/PopupContent/PointsEarnedLabel

func _ready():
	print("=== TaskDetailPage Starting ===")
	
	if category == "Academic Tasks":
		category_label.texture = load("res://words/schoolwork.png")
	elif category == "Household Chores":
		category_label.texture = load("res://words/chores 1024 x 120.png")
	elif category == "Errands":
		category_label.texture = load("res://words/errands 1024 x 120.png")
	
	ampm_selector.clear()
	ampm_selector.add_item("AM")
	ampm_selector.add_item("PM")
	ampm_selector.selected = 0
	
	$AddButton.connect("pressed", Callable(self, "_on_add_pressed"))
	$BackButton.connect("pressed", Callable(self, "_on_back_pressed"))
	cancel_button.connect("pressed", Callable(self, "_on_cancel_pressed"))
	add_button.connect("pressed", Callable(self, "_on_confirm_add_pressed"))
	
	due_date_input.connect("text_changed", Callable(self, "_on_due_date_text_changed"))
	
	# Limit task name to 30 characters
	task_name_input.max_length = 30
	
	popup.visible = false
	congrats_popup.visible = false
	
	refresh_task_list()
	update_category_progress()
	set_process(true)
	
	print("=== TaskDetailPage Ready ===")

func _input(event):
	if congrats_popup.visible and event is InputEventMouseButton and event.pressed:
		print("✓ User tapped screen - closing popup immediately")
		hide_congrats_popup_instant()

func _on_due_date_text_changed(new_text):
	var filtered = ""
	for i in range(new_text.length()):
		var c = new_text[i]
		if c in "0123456789-: ":
			filtered += c
	
	if filtered != new_text:
		due_date_input.text = filtered
		due_date_input.caret_column = filtered.length()

func _process(delta):
	check_overdue_tasks()

func check_overdue_tasks():
	var current_time = Time.get_datetime_dict_from_system()
	var changed = false
	
	for task in tasks:
		if task.status != "completed" and task.status != "missed":
			var deadline = parse_datetime(task.deadline)
			if deadline != null and is_overdue(current_time, deadline):
				task.status = "missed"
				changed = true
	
	if changed:
		refresh_task_list()
		update_category_progress()
		# Check for overdue tasks and update pet status
		if main_page:
			Globals.check_tasks_and_update_pet_status()

func parse_datetime(datetime_string):
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

func is_overdue(current, deadline):
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

func _on_add_pressed():
	AudioManager.play_click()
	print("Opening add task popup...")
	popup.visible = true
	task_name_input.text = ""
	due_date_input.text = ""
	ampm_selector.selected = 0
	await get_tree().process_frame
	task_name_input.grab_focus()

func _on_cancel_pressed():
	AudioManager.play_click()
	print("=== CANCEL PRESSED ===")
	popup.visible = false

func _on_confirm_add_pressed():
	AudioManager.play_click()
	print("=== ADD BUTTON PRESSED ===")
	
	var task_name = task_name_input.text.strip_edges()
	var due_date_raw = due_date_input.text.strip_edges()
	var ampm = ampm_selector.get_item_text(ampm_selector.selected)
	
	var parts = due_date_raw.split(" ")
	if parts.size() != 2:
		print("❌ ERROR: Format must be YYYY-MM-DD H:MM")
		return
	
	var date_str = parts[0]
	var time_str = parts[1]
	
	if task_name == "":
		print("❌ ERROR: Task name required")
		return
	
	var date_parts = date_str.split("-")
	if date_parts.size() != 3:
		print("❌ ERROR: Date must be YYYY-MM-DD")
		return
	
	var year = date_parts[0]
	var month = date_parts[1]
	var day = date_parts[2]
	
	var time_parts = time_str.split(":")
	if time_parts.size() != 2:
		print("❌ ERROR: Time must be H:MM or HH:MM")
		return
	
	var hour = time_parts[0]
	var minute = time_parts[1]
	
	if hour.length() == 1:
		hour = "0" + hour
	if minute.length() == 1:
		minute = "0" + minute
	
	if not year.is_valid_int() or not month.is_valid_int() or not day.is_valid_int() or not hour.is_valid_int() or not minute.is_valid_int():
		print("❌ ERROR: All parts must be numbers")
		return
	
	var year_int = int(year)
	var month_int = int(month)
	var day_int = int(day)
	var hour_int = int(hour)
	var minute_int = int(minute)
	
	if year_int < 2025 or year_int > 2100:
		print("❌ ERROR: Year must be 2025-2100")
		return
	if month_int < 1 or month_int > 12:
		print("❌ ERROR: Month must be 1-12")
		return
	if day_int < 1 or day_int > 31:
		print("❌ ERROR: Day must be 1-31")
		return
	if hour_int < 1 or hour_int > 12:
		print("❌ ERROR: Hour must be 1-12")
		return
	if minute_int < 0 or minute_int > 59:
		print("❌ ERROR: Minute must be 0-59")
		return
	
	# Create the full datetime string WITH AM/PM
	var formatted_date = year + "-" + month + "-" + day + " " + hour + ":" + minute
	var full_datetime = formatted_date + " " + ampm
	
	print("Full datetime with AM/PM: ", full_datetime)
	
	var new_task = {
		"name": task_name,
		"deadline": full_datetime,
		"status": "untouched"
	}
	
	tasks.append(new_task)
	print("✓ Task added! Total tasks: ", tasks.size())
	print("✓ Task deadline stored: ", new_task.deadline)
	
	# Save tasks after adding
	if main_page:
		main_page._save_tasks()
	
	popup.visible = false
	refresh_task_list()
	update_category_progress()
	
	print("🎉 SUCCESS! Task created: ", task_name)

func _on_back_pressed():
	AudioManager.play_click()
	if main_page:
		main_page.update_all_progress()
		main_page.visible = true
	queue_free()

func refresh_task_list():
	for child in task_list.get_children():
		child.queue_free()
	
	for i in range(tasks.size()):
		var task_item = task_item_scene.instantiate()
		task_item.task_data = tasks[i]
		task_item.task_index = i
		task_item.detail_page = self
		task_list.add_child(task_item)

func update_task_status(index, new_status):
	print("=== UPDATE TASK STATUS CALLED ===")
	print("Index: ", index, " | New status: ", new_status)
	
	if index >= 0 and index < tasks.size():
		var old_status = tasks[index].status
		tasks[index].status = new_status
		
		print("Old status: ", old_status, " → New status: ", new_status)
		
		if new_status == "completed" and old_status != "completed":
			print("✓ Task completed! Calculating points...")
			if main_page:
				var points = main_page.calculate_points(tasks[index].deadline)
				print("✓ Points calculated: ", points)
				
				if points > 0:
					main_page.total_points += points
					main_page.update_points_display()
					print("✓ Total points updated: ", main_page.total_points)
					
					# Add points as EXP to the pet
					Globals.add_exp(points)
					print("✓ Added %d EXP to pet (total EXP: %d)" % [points, Globals.player_exp])
					
					show_congrats_popup(points)
				else:
					print("❌ WARNING: 0 points calculated - check date calculation!")
			else:
				print("❌ ERROR: main_page is null!")
		
		refresh_task_list()
		update_category_progress()
		if main_page:
			main_page.update_all_progress()
			# Save tasks after status update
			main_page._save_tasks()
			# Check for overdue tasks and update pet status
			Globals.check_tasks_and_update_pet_status()
	else:
		print("❌ ERROR: Invalid task index: ", index)

func show_congrats_popup(points):
	print("=== SHOW CONGRATS POPUP ===")
	
	if not congrats_popup:
		print("❌ ERROR: CongratsPopup not found!")
		return
	
	# Grammar fix
	if points == 1:
		points_earned_label.text = "You earned 1 point!"
	else:
		points_earned_label.text = "You earned %d points!" % points
	
	# Try moving it FURTHER LEFT to compensate
	var x_position = 90.0  # Much more left than 190
	var y_center = 760.0
	
	congrats_popup.size = Vector2(700, 400)
	congrats_popup.position = Vector2(x_position, 2020)
	congrats_popup.visible = true
	
	print("Popup starting at: x=%.1f, y=2020" % x_position)
	
	# Tween to center
	var tween = create_tween()
	tween.tween_property(congrats_popup, "position", Vector2(x_position, y_center), 0.5).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	
	print("Tweening to: x=%.1f, y=%.1f" % [x_position, y_center])

func hide_congrats_popup_instant():
	if not congrats_popup:
		return
	
	congrats_popup.visible = false
	print("✓ Popup dismissed instantly")

func delete_task(index):
	if index >= 0 and index < tasks.size():
		tasks.remove(index)
		refresh_task_list()
		update_category_progress()
		if main_page:
			main_page.update_all_progress()
			# Save tasks after deletion
			main_page._save_tasks()

func update_category_progress():
	if tasks.size() == 0:
		category_progress.value = 0
		category_percent_label.text = "0%"
		apply_progress_color(0)
		return
	
	var completed = 0
	for task in tasks:
		if task.status == "completed":
			completed += 1
	
	var percent = float(completed) / float(tasks.size()) * 100.0
	category_progress.value = percent
	category_percent_label.text = "%d%%" % int(percent)
	apply_progress_color(percent)

func apply_progress_color(percent):
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
	
	category_progress.tint_progress = tint_color
