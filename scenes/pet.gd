extends AnimatedSprite2D
class_name Pet

# --- Pet Status Enum ---
enum PetStatus {
	IDLE,
	EATING,
	ANGRY
}

# --- Variables ---
var current_status: PetStatus = PetStatus.IDLE

# --- Status to animation name mapping ---
var status_to_animation: Dictionary = {
	PetStatus.IDLE: "idle",
	PetStatus.EATING: "eating",
	PetStatus.ANGRY: "angry"
}

func _ready() -> void:
	# Since this script is on the AnimatedSprite2D itself, we can use 'self'
	# Set initial status from Globals (defaults to IDLE)
	set_status(Globals.pet_status)
	
	# Ensure the animation is playing and looping
	if not is_playing():
		play()

# --- Set pet status ---
func set_status(status: PetStatus) -> void:
	if status == current_status:
		return
	
	current_status = status
	
	# Sync with Globals
	Globals.pet_status = status
	
	var animation_name: String = status_to_animation[status]
	
	if sprite_frames:
		if sprite_frames.has_animation(animation_name):
			play(animation_name)
		else:
			push_warning("Animation '%s' not found in sprite frames" % animation_name)

# --- Get current status ---
func get_status() -> PetStatus:
	return current_status

# --- Convenience methods ---
func set_idle() -> void:
	set_status(PetStatus.IDLE)

func set_eating() -> void:
	set_status(PetStatus.EATING)

func set_angry() -> void:
	set_status(PetStatus.ANGRY)
