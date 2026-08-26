extends SceneTree

func _init() -> void:
	var mov_img = Image.load_from_file("res://Assets/Spritesheets/Evil Wizard 3/Sprites/Projectile/Moving.png")
	if mov_img:
		print("Moving.png format: ", mov_img.get_format(), " width: ", mov_img.get_width(), " height: ", mov_img.get_height())
		
	var atk_img = Image.load_from_file("res://Assets/Spritesheets/Evil Wizard 3/Sprites/Attack.png")
	if atk_img:
		print("Attack.png format: ", atk_img.get_format(), " width: ", atk_img.get_width(), " height: ", atk_img.get_height())

	quit(0)
