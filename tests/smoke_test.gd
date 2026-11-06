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
	game.call("change_tab", -1)
	game.call("change_tab", 5)
	if int(game.get("current_tab")) != 0:
		push_error("Smoke test: invalid tab index changed navigation")
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
	if not str(game.call("number", 10000000000000000.0)).contains("경") or not str(game.call("number", 100000000000000000000.0)).contains("해"):
		push_error("Smoke test: large Korean currency formatting failed")
		quit(1)
		return
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
	var lifetime_before_tap: float = float(game.get("lifetime_earned"))
	game.call("tap_money")
	if float(game.get("money")) <= before:
		push_error("Smoke test: tapping did not earn money")
		quit(1)
		return
	if float(game.get("lifetime_earned")) <= lifetime_before_tap:
		push_error("Smoke test: tapping did not count toward lifetime wealth")
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
	var ore_before_invalid: int = int(game.get("rare_ore"))
	game.call("craft_equipment", -1)
	game.call("craft_equipment", 3)
	if int(game.get("rare_ore")) != ore_before_invalid:
		push_error("Smoke test: invalid equipment craft changed resources")
		quit(1)
		return
	if not str(game.call("mine_depth_button_text")).contains("광석"):
		push_error("Smoke test: mine depth button lacks ore guidance")
		quit(1)
		return
	game.call("set_business_buy_mode", 1)
	game.call("set_business_buy_mode", 7)
	if int(game.get("business_buy_mode")) != 1:
		push_error("Smoke test: invalid business buy mode was accepted")
		quit(1)
		return
	var level_before_invalid: int = int(game.get("business_levels")[0])
	game.call("buy_business", -1)
	game.call("buy_business", 99)
	if int(game.get("business_levels")[0]) != level_before_invalid:
		push_error("Smoke test: invalid business index changed progress")
		quit(1)
		return
	var original_levels: Array = game.get("business_levels").duplicate()
	var capped_levels: Array = original_levels.duplicate()
	capped_levels[0] = 100000
	game.set("business_levels", capped_levels)
	if int(game.call("business_purchase_count", 0)) != 0 or str(game.call("business_button_text", 0, 0)) != "최대 레벨":
		push_error("Smoke test: capped business purchase feedback failed")
		quit(1)
		return
	game.set("business_levels", original_levels)
	var business_before: int = int(game.get("business_levels")[0])
	game.call("buy_business", 0)
	if int(game.get("business_levels")[0]) != business_before + 1:
		push_error("Smoke test: business purchase failed")
		quit(1)
		return
	game.call("change_tab", 2)
	game.set("mine_energy", 10.0)
	var ore_before: int = int(game.get("ore"))
	var lifetime_before_mining: float = float(game.get("lifetime_earned"))
	game.call("mine_dig")
	if int(game.get("ore")) <= ore_before:
		push_error("Smoke test: mining did not award ore")
		quit(1)
		return
	if float(game.get("lifetime_earned")) <= lifetime_before_mining:
		push_error("Smoke test: mining did not count toward lifetime wealth")
		quit(1)
		return
	var previous_wealth: float = float(game.get("lifetime_earned"))
	game.call("trigger_street_event")
	if float(game.get("lifetime_earned")) <= previous_wealth:
		push_error("Street event wealth tracking failed")
		quit(1)
		return
	game.set("rare_ore", 2)
	previous_wealth = float(game.get("lifetime_earned"))
	game.call("sell_rare_ore")
	if float(game.get("lifetime_earned")) <= previous_wealth:
		push_error("Rare ore wealth tracking failed")
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
	# v7.2: permanent startup capital must survive rebirth and save/load.
	game.set("soul_points", 200)
	game.call("buy_legacy_capital")
	if int(game.get("legacy_capital")) != 1 or int(game.get("soul_points")) != 197:
		push_error("Smoke test: legacy capital purchase or cost failed")
		quit(1)
		return
	game.set("run_earned", 1000000.0)
	var capital_rebirth_before: int = int(game.get("rebirth_count"))
	game.call("perform_rebirth")
	if int(game.get("rebirth_count")) != capital_rebirth_before + 1 or absf(float(game.get("money")) - 1000.0) > 0.01:
		push_error("Smoke test: rebirth did not grant permanent startup capital")
		quit(1)
		return
	# v7.3: wealth milestones are claimable once, and persist across restarts.
	game.set("lifetime_earned", 100000000.0)
	var soul_before_wealth: int = int(game.get("soul_points"))
	game.call("claim_wealth", 0)
	if int(game.get("soul_points")) != soul_before_wealth + 3 or not game.get("claimed_wealth").has(0):
		push_error("Smoke test: lifetime wealth milestone reward failed")
		quit(1)
		return
	game.call("claim_wealth", 0)
	if int(game.get("soul_points")) != soul_before_wealth + 3:
		push_error("Smoke test: lifetime wealth milestone rewarded twice")
		quit(1)
		return
	game.call("claim_wealth", 2)
	if game.get("claimed_wealth").has(2):
		push_error("Smoke test: locked wealth milestone claimed prematurely")
		quit(1)
		return
	game.call("save_game")
	game.queue_free()
	await process_frame
	game = scene.instantiate()
	root.add_child(game)
	await process_frame
	if int(game.get("legacy_capital")) != 1 or not game.get("claimed_wealth").has(0) or float(game.get("lifetime_earned")) < 100000000.0:
		push_error("Smoke test: permanent wealth progress lost after restart")
		quit(1)
		return
	# Offline earnings must increase cash, run earnings and lifetime earnings together.
	game.set("auto_level", 10)
	game.call("save_game")
	var offline_data = JSON.parse_string(FileAccess.get_file_as_string("user://bottomlife_v1.json"))
	if not (offline_data is Dictionary):
		push_error("Offline regression: invalid saved JSON")
		quit(1)
		return
	offline_data["saved_at"] = Time.get_unix_time_from_system() - 120.0
	var cash_before_offline: float = float(offline_data["money"])
	var lifetime_before_offline: float = float(offline_data["lifetime_earned"])
	var offline_file := FileAccess.open("user://bottomlife_v1.json", FileAccess.WRITE)
	offline_file.store_string(JSON.stringify(offline_data))
	offline_file.close()
	game.queue_free()
	await process_frame
	game = scene.instantiate()
	root.add_child(game)
	await process_frame
	var offline_cash_gain: float = float(game.get("money")) - cash_before_offline
	var offline_lifetime_gain: float = float(game.get("lifetime_earned")) - lifetime_before_offline
	if offline_cash_gain < 2000.0 or absf(offline_cash_gain - offline_lifetime_gain) > 100.0:
		push_error("Offline regression: lifetime earnings differ from offline cash")
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
	# Also recover when the primary save is missing entirely.
	var delete_error: Error = DirAccess.remove_absolute(ProjectSettings.globalize_path("user://bottomlife_v1.json"))
	if delete_error != OK:
		push_error("Smoke test: could not delete primary save")
		quit(1)
		return
	game.queue_free()
	await process_frame
	game = scene.instantiate()
	root.add_child(game)
	await process_frame
	if not FileAccess.file_exists("user://bottomlife_v1.json") or int(game.get("rebirth_count")) < rebirth_before + 1:
		push_error("Smoke test: missing primary save recovery failed")
		quit(1)
		return
	print("SMOKE TEST PASSED: scene, tabs, tapping, business, mining, rebirth, legacy capital, lifetime wealth claims, save restart, corrupt/missing backup recovery")
	game.queue_free()
	await process_frame
	quit(0)
