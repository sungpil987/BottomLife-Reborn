extends SceneTree

# CI smoke test: load the real scene, switch every tab, and exercise save/load.
func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var scene: PackedScene = load("res://scenes/Main.tscn")
	if scene == null:
		push_error("Smoke test: main scene missing")
		quit(1)
		return
	var game: Control = scene.instantiate()
	root.add_child(game)
	await process_frame
	if game.get("content") == null or game.get("header") == null:
		push_error("Smoke test: HUD failed to initialize")
		quit(1)
		return
	for tab in range(5):
		game.call("change_tab", tab)
		await process_frame
		if game.get("current_tab") != tab:
			push_error("Smoke test: tab %d failed" % tab)
			quit(1)
			return
	game.call("change_tab", 0)
	await process_frame
	var before: float = float(game.get("money"))
	game.call("tap_money")
	if float(game.get("money")) <= before:
		push_error("Smoke test: tapping did not earn money")
		quit(1)
		return
	game.call("save_game")
	if not FileAccess.file_exists("user://bottomlife_v1.json"):
		push_error("Smoke test: save file missing")
		quit(1)
		return
	game.call("load_game")
	print("SMOKE TEST PASSED: scene, HUD, five tabs, tapping, save and load")
	game.queue_free()
	await process_frame
	quit(0)
