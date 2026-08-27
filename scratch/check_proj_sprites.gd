@tool
extends SceneTree

func _init() -> void:
	print("--- CHECKING PROJECTILE SPRITES ---")
	var moving_path = "res://Assets/Spritesheets/Evil Wizard 3/Sprites/Projectile/Moving.png"
	var explode_path = "res://Assets/Spritesheets/Evil Wizard 3/Sprites/Projectile/Explode.png"
	
	var img1 = Image.load_from_file(moving_path)
	if img1:
		print("Moving.png size: ", img1.get_width(), "x", img1.get_height())
		
	var img2 = Image.load_from_file(explode_path)
	if img2:
		print("Explode.png size: ", img2.get_width(), "x", img2.get_height())
		
	quit()
