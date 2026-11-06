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
	# Each scrollable tab must register its own ScrollContainer.
	game.call("change_tab", 1)
	await process_frame
	if not is_instance_valid(game.get("detail_scroll")):
		push_error("Smoke test: business scroll container missing")
		quit(1)
		return
	game.call("change_tab", 3)
	await process_frame
	if not is_instance_valid(game.get("detail_scroll")):
		push_error("Smoke test: growth scroll container missing")
		quit(1)
		return
	game.call("change_tab", 2)
	await process_frame
	if not is_instance_valid(game.get("detail_scroll")):
		push_error("Smoke test: mine scroll container missing")
		quit(1)
		return
	# Check that a real scroll offset is captured when leaving the tab.
	var mine_scroll: ScrollContainer = game.get("detail_scroll")
	mine_scroll.scroll_vertical = 24
	await process_frame
	var expected_offset: int = mine_scroll.scroll_vertical
	game.call("change_tab", 0)
	await process_frame
	var remembered: int = int(game.get("tab_scroll_positions")[2])
	if remembered != expected_offset:
		push_error("Smoke test: mine scroll offset was not remembered")
		quit(1)
		return
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
	# Verify persisted data through a fresh game instance, not just the same object.
	var saved_money: float = float(game.get("money"))
	var saved_taps: int = int(game.get("street_taps"))
	var saved_json = JSON.parse_string(FileAccess.get_file_as_string("user://bottomlife_v1.json"))
	if not (saved_json is Dictionary) or not saved_json.has("saved_at"):
		push_error("Smoke test: save file JSON invalid")
		quit(1)
		return
	game.queue_free()
	await process_frame
	game = scene.instantiate()
	root.add_child(game)
	await process_frame
	if absf(float(game.get("money")) - saved_money) > 100.0 or int(game.get("street_taps")) != saved_taps:
		push_error("Smoke test: saved progression did not survive scene restart")
		quit(1)
		return
	# Exercise real gameplay systems after save/load. The CI runner has isolated user data.
	game.set("money", 100000000.0)
	game.call("set_business_buy_mode", 1)
	var business_before: int = int(game.get("business_levels")[0])
	game.call("buy_business", 0)
	if int(game.get("business_levels")[0]) != business_before + 1:
		push_error("Smoke test: business purchase failed")
		quit(1)
		return
	game.call("change_tab", 2)
	game.set("mine_energy", 10.0)
	var ore_before: int = int(game.get("ore"))
	game.call("mine_dig")
	if int(game.get("ore")) <= ore_before:
		push_error("Smoke test: mining did not award ore")
		quit(1)
		return
	game.set("run_earned", 1000000.0)
	game.set("soul_points", 7)
	game.set("soul_power", 3)
	var rebirth_before: int = int(game.get("rebirth_count"))
	game.call("perform_rebirth")
	if int(game.get("rebirth_count")) != rebirth_before + 1 or int(game.get("soul_points")) < 8:
		push_error("Smoke test: rebirth reward not granted")
		quit(1)
		return
	if int(game.get("soul_power")) != 3 or int(game.get("business_levels")[0]) != 0 or int(game.get("mine_depth")) != 1:
		push_error("Smoke test: rebirth reset or permanent progression failed")
		quit(1)
		return
	# A corrupted primary save must recover from the previous valid backup.
	game.call("save_game")
	if not FileAccess.file_exists("user://bottomlife_v1.backup.json"):
		push_error("Smoke test: backup save missing")
		quit(1)
		return
	var backup_file := FileAccess.open("user://bottomlife_v1.json", FileAccess.WRITE)
	if backup_file == null:
		push_error("Smoke test: could not simulate corrupted save")
		quit(1)
		return
	backup_file.store_string("{invalid json")
	backup_file.close()
	game.queue_free()
	await process_frame
	game = scene.instantiate()
	root.add_child(game)
	await process_frame
	if int(game.get("rebirth_count")) < rebirth_before + 1:
		push_error("Smoke test: corrupted save backup recovery failed")
		quit(1)
		return
	var repaired_save = JSON.new()
	if repaired_save.parse(FileAccess.get_file_as_string("user://bottomlife_v1.json")) != OK:
		push_error("Smoke test: recovered primary save was not repaired")
		quit(1)
		return
	if not (repaired_save.data is Dictionary) or int(repaired_save.data.get("rebirth_count", -1)) < rebirth_before + 1:
		push_error("Smoke test: repaired primary save lost rebirth progress")
		quit(1)
		return
	print("SMOKE TEST PASSED: scene, tabs, tapping, business, mining, rebirth, save restart, backup recovery")
	game.queue_free()
	await process_frame
	quit(0)
