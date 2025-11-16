extends Control

var fridge_ref: Node = null

func set_fridge_ref(fridge: Node) -> void:
	fridge_ref = fridge

func _can_drop_data(_pos: Vector2, data: Variant) -> bool:
	if not fridge_ref:
		return false
	
	if fridge_ref.has_method("_can_drop_on_pet"):
		return fridge_ref._can_drop_on_pet(_pos, data)
	return false

func _drop_data(_pos: Vector2, data: Variant) -> void:
	if not fridge_ref:
		return
	
	if fridge_ref.has_method("_on_drop_on_pet"):
		fridge_ref._on_drop_on_pet(_pos, data)
