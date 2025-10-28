extends Node2D


func _on_settings_pressed() -> void:
	$Menu.is_visible = true


func _on_wardrobe_pressed() -> void:
	var wardrobe = load("res://scenes/wardrobe.tscn").instantiate()
	add_child(wardrobe)


func _on_fridge_pressed() -> void:
	var fridge = load("res://scenes/fridge.tscn").instantiate()
	add_child(fridge)
