extends Node2D


func _on_back_pressed() -> void:
	SceneTransition.transition_to_scene("res://scenes/node_2d.tscn")
