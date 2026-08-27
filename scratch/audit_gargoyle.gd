@tool
extends SceneTree

func _init() -> void:
	print("--- AUDITING ALL GARGOYLE ANIMATION ASSETS ---")
	var files = [
		"res://Assets/Spritesheets/Gargoyle 2D Pixel Art v1.2/New Version/Sprites/outline/IDLE.png",
		"res://Assets/Spritesheets/Gargoyle 2D Pixel Art v1.2/New Version/Sprites/outline/MOVE.png",
		"res://Assets/Spritesheets/Gargoyle 2D Pixel Art v1.2/New Version/Sprites/outline/ATTACK 1.png",
		"res://Assets/Spritesheets/Gargoyle 2D Pixel Art v1.2/New Version/Sprites/outline/ATTACK 2.png",
		"res://Assets/Spritesheets/Gargoyle 2D Pixel Art v1.2/New Version/Sprites/outline/HURT.png",
		"res://Assets/Spritesheets/Gargoyle 2D Pixel Art v1.2/New Version/Sprites/outline/DEATH.png"
	]
	
	for path in files:
		var img = Image.load_from_file(path)
		if not img:
			print("Could not load ", path)
			continue
			
		var total_x = 0.0
		var count = 0
		for y in range(96):
			for x in range(144):
				if img.get_pixel(x, y).a > 0.1:
					total_x += x
					count += 1
		
		var file_name = path.get_file()
		if count > 0:
			var avg_x = total_x / count
			var side = "RIGHT-leaning (avg X = %.1f > 72)" % avg_x if avg_x > 72 else "LEFT-leaning (avg X = %.1f < 72)" % avg_x
			print("%-15s -> %s" % [file_name, side])
		else:
			print("%-15s -> Empty" % file_name)

	quit()
