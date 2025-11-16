extends Resource
class_name FoodSpriteFrames

# This will store the converted SpriteFrames
@export var spritesheets: Array[SpriteFrames] = []

# -------------------------
# Public entry - conversion
# -------------------------
static func from_source(source: FoodSpritesheetsSource) -> FoodSpriteFrames:
	var result = FoodSpriteFrames.new()
	
	# Iterate textures directly (source.spritesheet_textures is expected to be Array[Texture2D])
	for texture in source.spritesheet_textures:
		if not texture:
			continue
		
		# Read user-specified defaults (0 for columns means "auto-detect")
		var columns: int = source.default_columns
		var anim_name: String = source.default_animation_name
		var anim_speed: float = source.default_animation_speed
		
		# Normalize fallbacks (leave columns = 0 to mean auto-detect)
		# anim_name and anim_speed will be handled later if empty/zero
		
		
		# Auto-detect frame dimensions if columns <= 0
		var frame_size = Vector2i(0, 0)
		if columns <= 0:
			frame_size = autodetect_frame_size(texture)
			if frame_size.x > 0 and frame_size.y > 0:
				columns = int(texture.get_width() / frame_size.x)
				if columns <= 0:
					columns = 1
			else:
				# autodetect failed -> fallback divisibility heuristics
				columns = guess_columns_by_divisibility(texture)
				frame_size = Vector2i(int(texture.get_width() / max(1, columns)), int(texture.get_height()))
		
		# If the caller provided columns > 0 but no frame_size resolved, compute frame width from columns
		if frame_size.x == 0 and columns > 0:
			frame_size.x = int(texture.get_width() / max(1, columns))
		
		# If frame height still zero, try to detect it by finding divisors of texture height
		if frame_size.y == 0 and frame_size.x > 0:
			frame_size.y = _detect_frame_height(texture.get_height(), frame_size.x)
		
		# Final fallback if still no frame size
		if frame_size.x == 0 or frame_size.y == 0:
			# Use simple fallback
			if columns <= 0:
				columns = 5  # Default to 5 columns
			frame_size.x = int(texture.get_width() / max(1, columns))
			frame_size.y = frame_size.x  # Assume square
		
		# Finalize animation name and speed (guesses if not provided)
		if anim_name == "" or anim_name.is_empty():
			anim_name = guess_animation_name_from_path(texture.resource_path)
		if anim_speed <= 0.0:
			anim_speed = guess_animation_speed_default(texture, columns, frame_size)
		
		
		# Create SpriteFrames
		var sprite_frames = _create_sprite_frames_from_texture(
			texture,
			columns,
			frame_size.x,
			frame_size.y,
			anim_name,
			anim_speed
		)
		
		if sprite_frames:
			result.spritesheets.append(sprite_frames)
	
	return result


# -------------------------
# Frame detection helpers
# -------------------------
# Returns Vector2i(frame_w, frame_h) or Vector2i(0,0) on failure
static func autodetect_frame_size(texture: Texture2D, alpha_threshold: float = 0.03, seam_transparency_ratio: float = 0.90, max_cols_test: int = 16) -> Vector2i:
	if not texture:
		return Vector2i(0, 0)
	
	# Get image from texture (works in the editor / import context)
	var img: Image = texture.get_image()
	if not img:
		return Vector2i(0, 0)
	
	img.lock()
	var w: int = img.get_width()
	var h: int = img.get_height()
	if w <= 0 or h <= 0:
		img.unlock()
		return Vector2i(0, 0)
	
	# Compute average alpha per column and per row (range 0..1)
	var col_alpha: PackedFloat32Array = []
	col_alpha.resize(w)
	for x in range(w):
		var sum: float = 0.0
		for y in range(h):
			sum += float(img.get_pixel(x, y).a)
		col_alpha[x] = sum / float(h)
	
	var row_alpha: PackedFloat32Array = []
	row_alpha.resize(h)
	for y in range(h):
		var sum: float = 0.0
		for x in range(w):
			sum += float(img.get_pixel(x, y).a)
		row_alpha[y] = sum / float(w)
	
	img.unlock()
	
	# Try candidate columns 1..max_cols_test and check seams at expected cut positions
	for cols in range(1, min(max_cols_test, w) + 1):
		var fw = float(w) / float(cols)
		if fw < 4.0:
			continue
		var ok = true
		for i in range(1, cols):
			var sx = int(round(fw * float(i)))
			if sx < 0 or sx >= w:
				ok = false
				break
			# Check small window around sx for transparent majority
			var transparent_count = 0
			var sample_count = 0
			for ox in range(max(0, sx - 1), min(w, sx + 2)):
				if ox >= 0 and ox < w and float(col_alpha[ox]) <= alpha_threshold:
					transparent_count += 1
				sample_count += 1
			if sample_count == 0:
				ok = false
				break
			if float(transparent_count) / float(sample_count) < seam_transparency_ratio:
				ok = false
				break
		if ok:
			# We found columns; now attempt to find rows similarly
			var frame_w = int(round(fw))
			for rows in range(1, min(max_cols_test, h) + 1):
				var fhf = float(h) / float(rows)
				if fhf < 4.0:
					continue
				var h_ok = true
				for j in range(1, rows):
					var sy = int(round(fhf * float(j)))
					if sy < 0 or sy >= h:
						h_ok = false
						break
					var transparent_count = 0
					var sample_count = 0
					for oy in range(max(0, sy - 1), min(h, sy + 2)):
						if oy >= 0 and oy < h and float(row_alpha[oy]) <= alpha_threshold:
							transparent_count += 1
						sample_count += 1
					if sample_count == 0:
						h_ok = false
						break
					if float(transparent_count) / float(sample_count) < seam_transparency_ratio:
						h_ok = false
						break
				if h_ok:
					var frame_h = int(round(fhf))
					return Vector2i(frame_w, frame_h)
			# If we couldn't find rows, return square guess using frame_w
			return Vector2i(frame_w, frame_w)
	
	# Fallback: try to detect square frames by divisibility
	for candidate_cols in range(1, min(32, w)):
		if w % candidate_cols == 0:
			var candidate_fw = int(float(w) / float(candidate_cols))
			if candidate_fw > 4 and h % candidate_fw == 0:
				return Vector2i(candidate_fw, candidate_fw)
	
	# Final fallback: failure
	return Vector2i(0, 0)


# Detect frame height by finding divisors of texture height
static func _detect_frame_height(texture_height: int, frame_width: int) -> int:
	if texture_height <= 0 or frame_width <= 0:
		return frame_width  # Fallback to square
	
	# Find all valid divisors (heights that divide texture_height evenly)
	var valid_heights: Array[int] = []
	
	# Try all possible row counts (1 to 20 rows max)
	for rows in range(1, min(21, texture_height + 1)):
		var candidate_height = int(texture_height / rows)
		if candidate_height <= 0:
			continue
		# Check if it divides evenly
		if texture_height % candidate_height == 0:
			var ratio = float(candidate_height) / float(frame_width)
			# Accept reasonable aspect ratios (0.2 to 5.0)
			if ratio >= 0.2 and ratio <= 5.0:
				valid_heights.append(candidate_height)
	
	if valid_heights.is_empty():
		# No valid divisors found, fallback to square
		return frame_width
	
	# Remove duplicates and sort
	valid_heights.sort()
	var unique_heights: Array[int] = []
	for h in valid_heights:
		if unique_heights.is_empty() or unique_heights[-1] != h:
			unique_heights.append(h)
	
	# Prefer square frames (1:1 ratio) - score: lower is better
	var best_height = unique_heights[0]
	var best_score = 999.0
	
	for height in unique_heights:
		var ratio = float(height) / float(frame_width)
		# Score based on how close to 1:1 (square)
		var score = abs(ratio - 1.0)
		
		if score < best_score:
			best_score = score
			best_height = height
	
	return best_height

# Try to guess a columns count by divisibility heuristics (1..16)
static func guess_columns_by_divisibility(texture: Texture2D) -> int:
	if not texture:
		return 1
	var w: int = texture.get_width()
	for c in range(1, 17):
		if w % c == 0:
			return c
	# No even divisor found, try rounding to nearest small divisor
	for c in range(1, 17):
		if int(round(float(w) / float(c))) >= 4:
			return c
	return 1


# Guess animation name from file path (basename w/o extension)
static func guess_animation_name_from_path(path: String) -> String:
	if path == "" or path == null:
		return "idle"
	var base = path.get_file().get_basename()
	if base == "":
		return "idle"
	return base.to_lower().replace(" ", "_")


# Guess animation speed default (fps)
static func guess_animation_speed_default(texture: Texture2D, columns: int, frame_size: Vector2i) -> float:
	var default_fps: float = 8.0
	if not texture:
		return default_fps
	if frame_size.x > 0 and frame_size.y > 0 and columns > 0:
		var rows = max(1, int(texture.get_height() / frame_size.y))
		var frame_count = max(1, columns * rows)
		# choose fps proportional to frame count but clamped
		var guessed = float(clamp(int(round(float(frame_count) / 4.0)), 4, 24))
		return guessed
	return default_fps


# -------------------------
# SpriteFrames creator
# -------------------------
static func _create_sprite_frames_from_texture(
	texture: Texture2D,
	columns: int,
	frame_width: int,
	frame_height: int,
	anim_name: String,
	anim_speed: float
) -> SpriteFrames:
	if not texture:
		return null
	
	var texture_width = texture.get_width()
	var texture_height = texture.get_height()
	var rows = int(max(1, texture_height / max(1, frame_height)))
	
	# Validate frame dimensions
	if frame_width <= 0 or frame_height <= 0:
		return null
	
	if rows <= 0:
		rows = max(1, int(texture_height / max(1, frame_height)))
	
	var sprite_frames = SpriteFrames.new()
	
	# Ensure animation name is valid
	if anim_name == "" or anim_name.is_empty():
		anim_name = "idle"
	
	# Remove default animation if it exists
	if sprite_frames.has_animation("default"):
		sprite_frames.remove_animation("default")
	
	# Add our animation
	sprite_frames.add_animation(anim_name)
	sprite_frames.set_animation_speed(anim_name, anim_speed)
	sprite_frames.set_animation_loop(anim_name, true)
	
	var frames_added = 0
	for row in range(rows):
		for col in range(columns):
			var x = col * frame_width
			var y = row * frame_height
			
			if x + frame_width > texture_width or y + frame_height > texture_height:
				continue
			
			var atlas_texture = AtlasTexture.new()
			atlas_texture.atlas = texture
			atlas_texture.region = Rect2(x, y, frame_width, frame_height)
			sprite_frames.add_frame(anim_name, atlas_texture)
			frames_added += 1
	
	if frames_added == 0:
		return null
	
	# Double-check our animation has frames
	if not sprite_frames.has_animation(anim_name):
		return null
	
	var final_frame_count = sprite_frames.get_frame_count(anim_name)
	if final_frame_count == 0:
		return null
	
	return sprite_frames
