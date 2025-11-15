extends Node2D


func _on_settings_pressed() -> void:
	$Menu.is_visible = true


func _on_wardrobe_pressed() -> void:
	SceneTransition.transition_to_scene("res://scenes/wardrobe.tscn")

func _on_fridge_pressed() -> void:
	SceneTransition.transition_to_scene("res://scenes/fridge.tscn")
