extends Node2D

# --- Icon nodes ---
@onready var shirt_icon = $MainBG/Control/VBoxContainer2/Shirt
@onready var skirt_icon = $MainBG/Control/VBoxContainer2/Skirt
@onready var accessories_icon = $MainBG/Control/VBoxContainer2/Accessories
@onready var shoes_icon = $MainBG/Control/VBoxContainer2/Shoes

# --- Optional: default textures ---
@export var default_shirt: Texture2D
@export var default_skirt: Texture2D
@export var default_accessories: Texture2D
@export var default_shoes: Texture2D

func _ready():
	_update_icons()

# --- Update icons based on Globals ---
func _update_icons():
	shirt_icon.icon = Globals.wardrobe_selection.get("shirt", default_shirt)
	skirt_icon.icon = Globals.wardrobe_selection.get("skirt", default_skirt)
	accessories_icon.icon = Globals.wardrobe_selection.get("accessories", default_accessories)
	shoes_icon.icon = Globals.wardrobe_selection.get("shoes", default_shoes)

# --- Open picker scenes ---
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


func _on_back_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/node_2d.tscn")
