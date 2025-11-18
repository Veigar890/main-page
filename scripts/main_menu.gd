extends Control

@onready var play_button: Button = $Play
@onready var settings_button: Button = $Settings
@onready var stats_button: Button = $Stats
@onready var exit_button: Button = $Exit
@onready var settings_menu: CanvasLayer = $Menu

func _ready() -> void:
	AudioManager.ensure_music_state()
	if play_button:
		play_button.pressed.connect(_on_play_pressed)
	if settings_button:
		settings_button.pressed.connect(_on_settings_pressed)
	if stats_button:
		stats_button.pressed.connect(_on_stats_pressed)
	if exit_button:
		exit_button.pressed.connect(_on_exit_pressed)

func _on_play_pressed() -> void:
	AudioManager.play_click()
	SceneTransition.transition_to_scene("res://scenes/node_2d.tscn")

func _on_settings_pressed() -> void:
	AudioManager.play_click()
	if settings_menu:
		settings_menu.menu_visible = true

func _on_stats_pressed() -> void:
	AudioManager.play_click()
	Globals.task_return_scene_path = "res://MainMenu.tscn"
	SceneTransition.transition_to_scene("res://MainTodoPage.tscn")

func _on_exit_pressed() -> void:
	AudioManager.play_click()
	get_tree().quit()
