extends CanvasLayer

@export var is_visible: bool = false:
	set(value):
		is_visible = value
		visible = value

func _ready():
	visible = is_visible


func _on_texture_button_pressed() -> void:
	is_visible = false
