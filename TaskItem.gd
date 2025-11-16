extends Control

var task_data = {}
var task_index = -1
var detail_page = null
var swipe_start_x = 0
var is_swiping = false

@onready var task_name_label = $TaskPanel/TaskContent/TaskInfo/TaskNameLabel
@onready var deadline_label = $TaskPanel/TaskContent/TaskInfo/DeadlineLabel
@onready var action_button = $TaskPanel/TaskContent/ActionButton
@onready var button_label = $TaskPanel/TaskContent/ActionButton/ButtonLabel
@onready var task_panel = $TaskPanel

var red_normal = preload("res://buttons/red button normal.png")
var red_hover = preload("res://buttons/red button hover.png")
var red_pressed = preload("res://buttons/red button pressed.png")
var green_normal = preload("res://buttons/green button normal.png")
var green_hover = preload("res://buttons/green button hover.png")
var green_pressed = preload("res://buttons/green button pressed.png")

func _ready():
	mouse_filter = Control.MOUSE_FILTER_PASS
	task_panel.mouse_filter = Control.MOUSE_FILTER_PASS
	update_display()

func _gui_input(event):
	if task_data.status != "completed":
		return
	
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				swipe_start_x = event.position.x
				is_swiping = true
			else:
				is_swiping = false
				if position.x < -100:
					if detail_page:
						detail_page.delete_task(task_index)
				else:
					position.x = 0
	
	elif event is InputEventMouseMotion and is_swiping:
		var delta_x = event.position.x - swipe_start_x
		position.x = clamp(delta_x, -200, 0)

func update_display():
	task_name_label.text = task_data.name
	deadline_label.text = "Deadline: " + task_data.deadline
	
	task_name_label.custom_minimum_size = Vector2(0, 40)
	deadline_label.custom_minimum_size = Vector2(0, 30)
	
	var panel_style = StyleBoxFlat.new()
	panel_style.corner_radius_top_left = 20
	panel_style.corner_radius_top_right = 20
	panel_style.corner_radius_bottom_left = 20
	panel_style.corner_radius_bottom_right = 20
	
	match task_data.status:
		"untouched":
			panel_style.bg_color = Color(1.0, 0.7, 0.4, 1.0)
			button_label.text = "DO NOW"
			action_button.texture_normal = red_normal
			action_button.texture_hover = red_hover
			action_button.texture_pressed = red_pressed
			action_button.visible = true
		
		"in_progress":
			panel_style.bg_color = Color(1.0, 1.0, 0.5, 1.0)
			button_label.text = "DONE"
			action_button.texture_normal = green_normal
			action_button.texture_hover = green_hover
			action_button.texture_pressed = green_pressed
			action_button.visible = true
		
		"completed":
			panel_style.bg_color = Color(0.5, 1.0, 0.5, 1.0)
			action_button.visible = false
		
		"missed":
			panel_style.bg_color = Color(1.0, 0.5, 0.5, 1.0)
			action_button.visible = false
	
	task_panel.add_theme_stylebox_override("panel", panel_style)
	
	if action_button.visible:
		if not action_button.is_connected("pressed", Callable(self, "_on_action_button_pressed")):
			action_button.connect("pressed", Callable(self, "_on_action_button_pressed"))
	
	print("Task displayed: ", task_data.name, " | Status: ", task_data.status)

func _on_action_button_pressed():
	print("=== ACTION BUTTON PRESSED ===")
	print("Current status: ", task_data.status)
	
	if task_data.status == "untouched":
		print("→ Changing to in_progress")
		if detail_page:
			detail_page.update_task_status(task_index, "in_progress")
	elif task_data.status == "in_progress":
		print("→ Changing to completed")
		if detail_page:
			detail_page.update_task_status(task_index, "completed")
