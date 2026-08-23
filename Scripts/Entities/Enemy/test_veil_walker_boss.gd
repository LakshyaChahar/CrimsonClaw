extends Node

func _ready() -> void:
	print("--- Starting VeilWalkerBoss Unit Tests ---")
	
	var scene_path = "res://Scenes/Entities/Enemy/veil_walker_boss.tscn"
	var boss_scene = load(scene_path)
	if not boss_scene:
		print("FAILED: Could not load veil_walker_boss.tscn")
		return
	print("SUCCESS: Loaded veil_walker_boss.tscn")
	
	var boss = boss_scene.instantiate() as VeilWalkerBoss
	if not boss:
		print("FAILED: Could not instantiate VeilWalkerBoss")
		return
	print("SUCCESS: Instantiated VeilWalkerBoss")
	
	add_child(boss)
	await get_tree().process_frame
	
	if boss.max_health != 300.0:
		print("FAILED: Expected max_health to be 300.0, got: ", boss.max_health)
		return
	print("SUCCESS: Verified sub-boss max_health = 300.0")
	
	var sm = boss.state_machine
	if not sm or not sm.has_node("PhaseStrike"):
		print("FAILED: PhaseStrike state node not found on VeilWalkerBoss state machine")
		return
	print("SUCCESS: PhaseStrike state node verified on state machine")
	
	var laser = boss.find_child("TargetLaser") as Line2D
	if not laser:
		print("FAILED: TargetLaser Line2D node not found on VeilWalkerBoss")
		return
	print("SUCCESS: TargetLaser Line2D node verified on VeilWalkerBoss")
	
	print("--- All VeilWalkerBoss Tests Passed Successfully! ---")
