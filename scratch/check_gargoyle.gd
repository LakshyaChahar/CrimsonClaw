@tool
extends SceneTree

func _init() -> void:
	var img = Image.load_from_file("res://Assets/Spritesheets/Gargoyle 2D Pixel Art v1.2/New Version/Sprites/outline/IDLE.png")
	if img:
		print("IDLE.png size: ", img.get_width(), "x", img.get_height())
		# Find bounding box of non-transparent pixels in frame 1 (first 144x96 region)
		var min_x = 144
		var max_x = 0
		for y in range(96):
			for x in range(144):
				if img.get_pixel(x, y).a > 0.1:
					if x < min_x: min_x = x
					if x > max_x: max_x = x
		print("Frame 0 content X range: ", min_x, " to ", max_x, " (center of frame: 72)")
	quit()
