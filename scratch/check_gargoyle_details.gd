@tool
extends SceneTree

func _init() -> void:
	var img = Image.load_from_file("res://Assets/Spritesheets/Gargoyle 2D Pixel Art v1.2/New Version/Sprites/outline/IDLE.png")
	if img:
		# Check pixel alpha density on left half (x 0..71) vs right half (x 72..143)
		var left_pixels = 0
		var right_pixels = 0
		for y in range(96):
			for x in range(72):
				if img.get_pixel(x, y).a > 0.1: left_pixels += 1
			for x in range(72, 144):
				if img.get_pixel(x, y).a > 0.1: right_pixels += 1
		print("IDLE.png Frame 0 - Left side solid pixels: ", left_pixels, " | Right side solid pixels: ", right_pixels)

	var img_move = Image.load_from_file("res://Assets/Spritesheets/Gargoyle 2D Pixel Art v1.2/New Version/Sprites/outline/MOVE.png")
	if img_move:
		var left_pixels = 0
		var right_pixels = 0
		for y in range(96):
			for x in range(72):
				if img_move.get_pixel(x, y).a > 0.1: left_pixels += 1
			for x in range(72, 144):
				if img_move.get_pixel(x, y).a > 0.1: right_pixels += 1
		print("MOVE.png Frame 0 - Left side solid pixels: ", left_pixels, " | Right side solid pixels: ", right_pixels)

	quit()
