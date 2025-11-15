extends Node2D

# --- Node references ---
@onready var vbox2_shirt_btn = $MainBG/Control/VBoxContainer2/Shirt
@onready var vbox2_skirt_btn = $MainBG/Control/VBoxContainer2/Skirt
@onready var vbox2_accessories_btn = $MainBG/Control/VBoxContainer2/Accessories
@onready var vbox2_shoes_btn = $MainBG/Control/VBoxContainer2/Shoes

func _ready():
	# Load and display saved selections from Globals
	_load_saved_selections()

# --- LOAD SAVED SELECTIONS ---
func _load_saved_selections() -> void:
	if Globals.wardrobe_selection.has("shirt") and Globals.wardrobe_selection["shirt"] != null:
		vbox2_shirt_btn.icon = Globals.wardrobe_selection["shirt"]
	if Globals.wardrobe_selection.has("skirt") and Globals.wardrobe_selection["skirt"] != null:
		vbox2_skirt_btn.icon = Globals.wardrobe_selection["skirt"]
	if Globals.wardrobe_selection.has("accessories") and Globals.wardrobe_selection["accessories"] != null:
		vbox2_accessories_btn.icon = Globals.wardrobe_selection["accessories"]
	if Globals.wardrobe_selection.has("shoes") and Globals.wardrobe_selection["shoes"] != null:
		vbox2_shoes_btn.icon = Globals.wardrobe_selection["shoes"]

# --- Open picker scenes ---
func _on_shirt_pressed() -> void:
	Globals.selected_item = "shirt"
	SceneTransition.transition_to_scene("res://scenes/wardrobe_picker.tscn")

func _on_skirt_pressed() -> void:
	Globals.selected_item = "skirt"
	SceneTransition.transition_to_scene("res://scenes/wardrobe_picker.tscn")

func _on_accessories_pressed() -> void:
	Globals.selected_item = "accessories"
	SceneTransition.transition_to_scene("res://scenes/wardrobe_picker.tscn")

func _on_shoes_pressed() -> void:
	Globals.selected_item = "shoes"
	SceneTransition.transition_to_scene("res://scenes/wardrobe_picker.tscn")


func _on_back_pressed() -> void:
	SceneTransition.transition_to_scene("res://scenes/node_2d.tscn")
