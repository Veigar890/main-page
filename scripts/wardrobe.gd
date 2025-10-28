extends Node2D

func _on_back_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/node_2d.tscn")

func _on_shirt_pressed() -> void:
	Globals.selected_item = "shirt"
	get_tree().change_scene_to_file("res://scenes/wardrobe_picker.tscn")

func _on_skirt_pressed() -> void:
	Globals.selected_item = "skirt"
	get_tree().change_scene_to_file("res://scenes/wardrobe_picker.tscn")

func _on_accessories_pressed() -> void:
	Globals.selected_item = "accessories"
	get_tree().change_scene_to_file("res://scenes/wardrobe_picker.tscn")

func _on_shoes_pressed() -> void:
	Globals.selected_item = "shoes"
	get_tree().change_scene_to_file("res://scenes/wardrobe_picker.tscn")
