extends Node2D

@onready var dread_vanguard: Node2D = find_child("DreadVanguardBoss", true, false)
@onready var pyro_archon: Node2D = find_child("PyroArchonBoss", true, false)
@onready var veil_walker: Node2D = find_child("VeilWalkerBoss", true, false)

var _game_won_triggered := false

func _ready() -> void:
	# Ensure Level 2 background music is playing
	if has_node("/root/SfxManager"):
		var sfx = get_node("/root/SfxManager")
		if sfx.has_method("play_music"):
			sfx.play_music("level 2")

	# Connect death signals for Level 3 bosses
	if dread_vanguard and dread_vanguard.has_signal("died"):
		dread_vanguard.died.connect(_on_boss_died)
	if pyro_archon and pyro_archon.has_signal("died"):
		pyro_archon.died.connect(_on_boss_died)
	if veil_walker and veil_walker.has_signal("died"):
		veil_walker.died.connect(_on_boss_died)

func _on_boss_died() -> void:
	if _game_won_triggered:
		return
	
	# Check if final boss (DreadVanguardBoss or all bosses) is defeated
	var dread_vanguard_dead = (dread_vanguard == null or ("is_dead" in dread_vanguard and dread_vanguard.is_dead))
	if dread_vanguard_dead:
		_trigger_game_won()

func _trigger_game_won() -> void:
	if _game_won_triggered:
		return
	_game_won_triggered = true
	print("[Level 3] Final boss defeated! Transitioning to Game Won scene...")
	await get_tree().create_timer(2.0).timeout
	
	const WIN_SCENE := "res://Scenes/UI/GameCompleted.tscn"
	if has_node("/root/SceneTransition"):
		get_node("/root/SceneTransition").change_scene_to_file(WIN_SCENE)
	elif ResourceLoader.exists(WIN_SCENE):
		get_tree().change_scene_to_file(WIN_SCENE)
