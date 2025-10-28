extends Node2D


func _on_settings_pressed() -> void:
	$Menu.is_visible = true


func _on_wardrobe_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/wardrobe.tscn")

func _on_fridge_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/fridge.tscn")
