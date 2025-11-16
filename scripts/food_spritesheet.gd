extends Resource
class_name FoodSpritesheetsSource

# Store spritesheet textures (simplified - just textures)
@export var spritesheet_textures: Array[Texture2D] = []

# Default values (used for all textures)
@export var default_columns: int = 5
@export var default_animation_name: String = "idle"
@export var default_animation_speed: float = 8.0

# Helper function to add a spritesheet (optional, for easier setup)
func add_spritesheet(texture: Texture2D) -> void:
	if texture:
		spritesheet_textures.append(texture)
