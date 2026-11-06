extends Control

const SAVE_PATH = "user://bottomlife_v1.json"
var money: float = 0.0
var run_earned: float = 0.0
var rebirth_count: int = 0
var soul_points: int = 0
var soul_power: int = 0
var offline_report: String = ""
var tap_level: int = 1
var auto_level: int = 0
var business_levels: Array[int] = [0, 0, 0]
var mine_depth: int = 1
var pickaxe_level: int = 1
var ore: int = 0
var gems: int = 0
var luck_level: int = 0
var stamina_level: int = 0
var last_mine_find: String = ""
var growth_buttons: Array[Button] = []
var mine_energy: float = 10.0
var mine_buttons: Array[Button] = []
var mine_status: Label
var mine_energy_bar: ProgressBar
var mine_art: TextureRect
var mine_effect_layer: Control
var mine_flash_tween: Tween
const MINE_MAX_ENERGY := 10.0
const BUSINESS_NAMES := ["길거리 노점", "분식 가게", "동네 편의점"]
const BUSINESS_BASE_COST := [1000.0, 15000.0, 150000.0]
const BUSINESS_BASE_INCOME := [12.0, 95.0, 780.0]
var current_tab: int = 0
var header: Label
var income_label: Label
var content: VBoxContainer
var feedback: Label
var save_clock: float = 0.0
var ui_clock: float = 0.0
var hero_sprite: TextureRect
var hero_idle_tween: Tween
var hero_blink_clock: float = 0.0
var hero_blink_active: bool = false
var hero_base_texture: Texture2D = preload("res://assets/hero_pixel.svg")
var hero_blink_texture: Texture2D = preload("res://assets/hero_pixel_blink.svg")
var tap_upgrade_button: Button
var auto_upgrade_button: Button
var idle_time: float = 0.0
var pop_tween: Tween
var street_stage: Control
var float_layer: Control
var tab_buttons: Array[Button] = []
var business_buttons: Array[Button] = []
var tap_cost_label: Label
var auto_cost_label: Label

func _ready() -> void:
	load_game()
	build_ui()
	refresh()

func _process(delta: float) -> void:
	var gain := total_auto_income() * delta * prestige_multiplier()
	money += gain
	run_earned += gain
	save_clock += delta
	ui_clock += delta
	idle_time += delta
	if is_instance_valid(hero_sprite):
		hero_blink_clock += delta
		if hero_blink_active and hero_blink_clock >= 0.14:
			hero_sprite.texture = hero_base_texture
			hero_blink_active = false
			hero_blink_clock = 0.0
		elif not hero_blink_active and hero_blink_clock >= 3.2:
			hero_sprite.texture = hero_blink_texture
			hero_blink_active = true
			hero_blink_clock = 0.0
	mine_energy = minf(max_mine_energy(), mine_energy + delta * (0.4 + float(stamina_level) * 0.08))
	if is_instance_valid(mine_status):
		mine_status.text = "곡괭이 Lv.%d  |  기력 %d/%d  |  광석 %d개" % [pickaxe_level, int(mine_energy), int(max_mine_energy()), ore]
	if is_instance_valid(mine_energy_bar):
		mine_energy_bar.max_value = max_mine_energy()
		mine_energy_bar.value = mine_energy
	if save_clock >= 10.0:
		save_clock = 0.0
		save_game()
	if ui_clock >= 0.15:
		ui_clock = 0.0
		refresh_header()
		refresh_upgrade_buttons()

func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST or what == NOTIFICATION_APPLICATION_PAUSED:
		save_game()

func load_game() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		return
	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file == null:
		return
	var data = JSON.parse_string(file.get_as_text())
	if data is Dictionary:
		money = maxf(0.0, float(data.get("money", 0.0)))
		run_earned = maxf(money, float(data.get("run_earned", money)))
		rebirth_count = maxi(0, int(data.get("rebirth_count", 0)))
		soul_points = maxi(0, int(data.get("soul_points", 0)))
		soul_power = clampi(int(data.get("soul_power", 0)), 0, 1000)
		tap_level = maxi(1, int(data.get("tap_level", 1)))
		auto_level = maxi(0, int(data.get("auto_level", 0)))
		var saved_business = data.get("business_levels", [0, 0, 0])
		if saved_business is Array:
			for i in range(mini(3, saved_business.size())):
				business_levels[i] = clampi(int(saved_business[i]), 0, 100000)
		mine_depth = maxi(1, int(data.get("mine_depth", 1)))
		pickaxe_level = maxi(1, int(data.get("pickaxe_level", 1)))
		ore = maxi(0, int(data.get("ore", 0)))
		gems = maxi(0, int(data.get("gems", 0)))
		luck_level = clampi(int(data.get("luck_level", 0)), 0, 50)
		stamina_level = clampi(int(data.get("stamina_level", 0)), 0, 50)
		mine_energy = max_mine_energy()
		var saved_at := float(data.get("saved_at", 0.0))
		if saved_at > 0.0:
			var elapsed := clampf(Time.get_unix_time_from_system() - saved_at, 0.0, 14400.0)
			var offline_gain := total_auto_income() * prestige_multiplier() * elapsed * 0.5
			if offline_gain > 0.0:
				money += offline_gain
				run_earned += offline_gain
				offline_report = "부재중 수익 +%s원 (%d분)" % [number(offline_gain), int(elapsed / 60.0)]

func save_game() -> void:
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file != null:
		file.store_string(JSON.stringify({"money": money, "tap_level": tap_level, "auto_level": auto_level, "business_levels": business_levels, "mine_depth": mine_depth, "pickaxe_level": pickaxe_level, "ore": ore, "gems": gems, "luck_level": luck_level, "stamina_level": stamina_level, "run_earned": run_earned, "rebirth_count": rebirth_count, "soul_points": soul_points, "soul_power": soul_power, "saved_at": Time.get_unix_time_from_system()}))

func make_label(value: String, size: int = 27) -> Label:
	var label := Label.new()
	label.text = value
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", Color("#f2e7d1"))
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	return label

func panel_style(bg: Color, outline: Color, radius: int = 16) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = bg
	style.border_color = outline
	style.set_border_width_all(2)
	style.set_corner_radius_all(radius)
	style.content_margin_left = 12.0
	style.content_margin_right = 12.0
	style.content_margin_top = 12.0
	style.content_margin_bottom = 12.0
	return style

func decorate_button(button: Button, gold: bool = false) -> void:
	var normal := panel_style(Color("#bc8849") if gold else Color("#24232d"), Color("#f0c47a") if gold else Color("#75614f"), 2)
	var hover := panel_style(Color("#d9a55b") if gold else Color("#37323c"), Color("#ffe1a0"), 2)
	var pressed := panel_style(Color("#94652f") if gold else Color("#171720"), Color("#f0c47a"), 2)
	button.add_theme_stylebox_override("normal", normal)
	button.add_theme_stylebox_override("hover", hover)
	button.add_theme_stylebox_override("pressed", pressed)
	button.add_theme_stylebox_override("disabled", panel_style(Color("#25242b"), Color("#4c4441"), 2))
	button.add_theme_color_override("font_color", Color("#16151b") if gold else Color("#f8e6c9"))
	button.add_theme_color_override("font_disabled_color", Color("#a29b95"))
	button.add_theme_color_override("font_hover_color", Color("#16151b") if gold else Color("#ffffff"))

func refresh_upgrade_buttons() -> void:
	for i in range(growth_buttons.size()):
		if is_instance_valid(growth_buttons[i]):
			growth_buttons[i].disabled = gems < growth_cost(i) or (luck_level if i == 0 else stamina_level) >= 50
	if mine_buttons.size() == 3:
		if is_instance_valid(mine_buttons[0]):
			mine_buttons[0].disabled = mine_energy < 1.0
		if is_instance_valid(mine_buttons[1]):
			mine_buttons[1].disabled = money < mine_upgrade_cost()
		if is_instance_valid(mine_buttons[2]):
			mine_buttons[2].disabled = ore < mine_depth_cost()
	for i in range(business_buttons.size()):
		if is_instance_valid(business_buttons[i]):
			business_buttons[i].disabled = money < business_cost(i)
	if is_instance_valid(tap_upgrade_button):
		tap_upgrade_button.disabled = money < 100.0 * pow(1.35, tap_level - 1)
	if is_instance_valid(auto_upgrade_button):
		auto_upgrade_button.disabled = money < 250.0 * pow(1.42, auto_level)

func make_button(value: String) -> Button:
	var button := Button.new()
	button.text = value
	button.custom_minimum_size = Vector2(0, 72)
	button.add_theme_font_size_override("font_size", 23)
	decorate_button(button)
	return button

func build_ui() -> void:
	var bg := ColorRect.new()
	bg.color = Color("#111016")
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(bg)
	var outer := VBoxContainer.new()
	outer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	outer.offset_left = 12.0
	outer.offset_right = -12.0
	outer.offset_top = 12.0
	outer.offset_bottom = -12.0
	outer.add_theme_constant_override("separation", 8)
	add_child(outer)
	var top := PanelContainer.new()
	top.custom_minimum_size.y = 104
	top.add_theme_stylebox_override("panel", panel_style(Color("#1e1b26"), Color("#ad8652"), 2))
	outer.add_child(top)
	var top_box := VBoxContainer.new()
	top_box.add_theme_constant_override("separation", 4)
	top.add_child(top_box)
	header = make_label("", 32)
	top_box.add_child(header)
	income_label = make_label("", 20)
	top_box.add_child(income_label)
	content = VBoxContainer.new()
	content.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content.add_theme_constant_override("separation", 8)
	outer.add_child(content)
	var bottom := HBoxContainer.new()
	bottom.custom_minimum_size.y = 88
	bottom.add_theme_constant_override("separation", 4)
	outer.add_child(bottom)
	var tabs := ["거리", "사업", "광산", "성장", "메뉴"]
	for i in range(tabs.size()):
		var b := make_button(tabs[i])
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		b.add_theme_font_size_override("font_size", 18)
		b.custom_minimum_size.y = 80
		decorate_button(b, i == current_tab)
		b.pressed.connect(change_tab.bind(i))
		bottom.add_child(b)
		tab_buttons.append(b)

func change_tab(index: int) -> void:
	current_tab = index
	for i in range(tab_buttons.size()):
		decorate_button(tab_buttons[i], i == index)
	refresh()

func prestige_multiplier() -> float:
	return 1.0 + float(soul_power) * 0.1

func rebirth_reward() -> int:
	if run_earned < 1000000.0:
		return 0
	return maxi(1, int(floor(sqrt(run_earned / 1000000.0))))

func soul_upgrade_cost() -> int:
	return 1 + int(soul_power / 5)

func buy_soul_power() -> void:
	var cost := soul_upgrade_cost()
	if soul_points < cost or soul_power >= 1000:
		return
	soul_points -= cost
	soul_power += 1
	save_game()
	refresh()

func perform_rebirth() -> void:
	var reward := rebirth_reward()
	if reward == 0:
		return
	soul_points += reward
	rebirth_count += 1
	money = 0.0
	run_earned = 0.0
	tap_level = 1
	auto_level = 0
	business_levels = [0, 0, 0]
	mine_depth = 1
	pickaxe_level = 1
	ore = 0
	gems = 0
	luck_level = 0
	stamina_level = 0
	mine_energy = MINE_MAX_ENERGY
	last_mine_find = ""
	save_game()
	refresh()

func request_rebirth() -> void:
	if rebirth_reward() == 0:
		return
	var dialog := ConfirmationDialog.new()
	dialog.title = "환생 확인"
	dialog.dialog_text = "돈, 사업, 광산과 일반 성장이 초기화됩니다.\n영혼과 영구 강화는 유지됩니다.\n정말 환생하시겠습니까?"
	dialog.confirmed.connect(perform_rebirth)
	dialog.confirmed.connect(dialog.queue_free)
	dialog.canceled.connect(dialog.queue_free)
	add_child(dialog)
	dialog.popup_centered()

func build_rebirth() -> void:
	content.add_child(make_label("환생의 제단", 34))
	if offline_report != "":
		content.add_child(make_label(offline_report, 20))
	content.add_child(make_label("환생 %d회  |  영혼 %d개" % [rebirth_count, soul_points], 27))
	content.add_child(make_label("영구 수익 배율  x%.1f" % prestige_multiplier(), 27))
	content.add_child(make_label("이번 회차 누적 획득  %s원" % number(run_earned), 22))
	var progress := ProgressBar.new()
	progress.custom_minimum_size.y = 22
	progress.show_percentage = false
	progress.max_value = 1000000.0
	progress.value = minf(run_earned, 1000000.0)
	progress.add_theme_stylebox_override("background", panel_style(Color("#191923"), Color("#554b43"), 0))
	progress.add_theme_stylebox_override("fill", panel_style(Color("#b68dce"), Color("#e2b7fc"), 0))
	content.add_child(progress)
	content.add_child(make_label("환생 조건: 회차 누적 100만원", 20))
	var reward := rebirth_reward()
	content.add_child(make_label("현재 환생 보상: 영혼 %d개" % reward, 24))
	var upgrade := make_button("영혼의 힘 강화  수익 +10%%\n영혼 %d개" % soul_upgrade_cost())
	upgrade.disabled = soul_points < soul_upgrade_cost() or soul_power >= 1000
	upgrade.pressed.connect(buy_soul_power)
	content.add_child(upgrade)
	var button := make_button("환생하기  |  영혼 +%d" % reward)
	decorate_button(button, true)
	button.disabled = reward == 0
	button.pressed.connect(request_rebirth)
	content.add_child(button)
	content.add_child(make_label("환생 시 일반 성장과 보유 자원은 초기화됩니다.", 20))

func total_auto_income() -> float:
	var result := float(auto_level) * 5.0
	for i in range(3):
		result += float(business_levels[i]) * BUSINESS_BASE_INCOME[i] * business_milestone_multiplier(business_levels[i])
	return result

func business_milestone_multiplier(level: int) -> float:
	if level >= 100:
		return 8.0
	if level >= 50:
		return 4.0
	if level >= 25:
		return 2.0
	return 1.0

func business_cost(index: int) -> float:
	return BUSINESS_BASE_COST[index] * pow(1.24, business_levels[index])

func buy_business(index: int) -> void:
	var cost := business_cost(index)
	if money < cost:
		return
	money -= cost
	business_levels[index] += 1
	save_game()
	refresh()

func build_business() -> void:
	content.add_child(make_label("나만의 사업 거리", 32))
	var art := TextureRect.new()
	art.texture = load("res://assets/business_stall.svg")
	art.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	art.custom_minimum_size.y = 190
	content.add_child(art)
	content.add_child(make_label("사업 수익  +%s원/초" % number((total_auto_income() - float(auto_level) * 5.0) * prestige_multiplier()), 26))
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content.add_child(scroll)
	var rows := VBoxContainer.new()
	rows.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	rows.add_theme_constant_override("separation", 12)
	scroll.add_child(rows)
	for i in range(3):
		var panel := PanelContainer.new()
		panel.add_theme_stylebox_override("panel", panel_style(Color("#24212c"), Color("#826744"), 2))
		rows.add_child(panel)
		var row := HBoxContainer.new()
		panel.add_child(row)
		var info := VBoxContainer.new()
		info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(info)
		info.add_child(make_label("%s  Lv.%d" % [BUSINESS_NAMES[i], business_levels[i]], 23))
		info.add_child(make_label("+%s원/초" % number(float(business_levels[i]) * BUSINESS_BASE_INCOME[i] * business_milestone_multiplier(business_levels[i])), 19))
		info.add_child(make_label("달성 보너스 x%.0f (25/50/100레벨)" % business_milestone_multiplier(business_levels[i]), 16))
		var cost := business_cost(i)
		var button := make_button("확장\n%s원" % number(cost))
		button.custom_minimum_size = Vector2(180, 88)
		button.disabled = money < cost
		button.pressed.connect(buy_business.bind(i))
		row.add_child(button)
		business_buttons.append(button)
	content.add_child(make_label("25/50/100레벨 달성 시 사업 수익 2/4/8배!", 19))

func max_mine_energy() -> float:
	return MINE_MAX_ENERGY + float(stamina_level) * 2.0

func growth_cost(index: int) -> int:
	var level := luck_level if index == 0 else stamina_level
	return 2 + level * (level + 3)

func buy_growth(index: int) -> void:
	var cost := growth_cost(index)
	if gems < cost:
		return
	if index == 0 and luck_level < 50:
		gems -= cost
		luck_level += 1
	elif index == 1 and stamina_level < 50:
		gems -= cost
		stamina_level += 1
	else:
		return
	save_game()
	refresh()

func build_growth() -> void:
	content.add_child(make_label("생존자의 성장", 34))
	content.add_child(make_label("보유 보석  ◆ %d개" % gems, 28))
	content.add_child(make_label("광산 보석으로 능력 강화", 20))
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content.add_child(scroll)
	var rows := VBoxContainer.new()
	rows.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(rows)
	for i in range(2):
		var level := luck_level if i == 0 else stamina_level
		var panel := PanelContainer.new()
		panel.add_theme_stylebox_override("panel", panel_style(Color("#24212c"), Color("#826744"), 12))
		rows.add_child(panel)
		var box := VBoxContainer.new()
		panel.add_child(box)
		box.add_child(make_label(("행운의 감각" if i == 0 else "강인한 체력") + "  Lv.%d/50" % level, 27))
		box.add_child(make_label("보석 발견 확률 +%d%%p" % (level * 1) if i == 0 else "최대 기력 +%d / 회복 속도 증가" % (level * 2), 20))
		var button := make_button("보석 %d개로 강화" % growth_cost(i))
		button.disabled = gems < growth_cost(i) or level >= 50
		button.pressed.connect(buy_growth.bind(i))
		box.add_child(button)
		growth_buttons.append(button)
	content.add_child(make_label("행운은 보석 발견 확률을 높여줍니다.", 19))

func mine_upgrade_cost() -> float:
	return 500.0 * pow(1.65, pickaxe_level - 1)

func mine_depth_cost() -> int:
	return 8 + mine_depth * 5

func mine_dig() -> void:
	if mine_energy < 1.0:
		return
	mine_energy -= 1.0
	var reward := float(20 * pickaxe_level * mine_depth)
	reward *= prestige_multiplier()
	money += reward
	run_earned += reward
	ore += pickaxe_level
	var chance := minf(0.60, 0.03 + float(luck_level) * 0.01 + float(mine_depth - 1) * 0.002)
	if randf() < chance:
		var found := 1 + int(mine_depth / 10)
		gems += found
		last_mine_find = "희귀 보석 %d개 발견!" % found
	else:
		last_mine_find = "광석 %d개 획득" % pickaxe_level
	save_game()
	refresh()
	play_mine_hit_effect()

func play_mine_hit_effect() -> void:
	if not is_instance_valid(mine_art) or not is_instance_valid(mine_effect_layer):
		return
	if mine_flash_tween and mine_flash_tween.is_running():
		mine_flash_tween.kill()
	mine_art.modulate = Color("#fff0b3")
	mine_flash_tween = create_tween()
	mine_flash_tween.tween_property(mine_art, "modulate", Color.WHITE, 0.28)
	var found_gem := last_mine_find.begins_with("희귀")
	var flash := make_label("◆ 보석 발견!" if found_gem else "쾅!  +광석", 31)
	flash.z_index = 2
	flash.add_theme_color_override("font_color", Color("#8ef4ff") if found_gem else Color("#ffe0a0"))
	flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	flash.position = Vector2(115, 82)
	mine_effect_layer.add_child(flash)
	var motion := create_tween()
	motion.set_parallel(true)
	motion.tween_property(flash, "position:y", 15.0, 0.8).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	motion.tween_property(flash, "modulate:a", 0.0, 0.8)
	motion.set_parallel(false)
	motion.tween_callback(flash.queue_free)

func mine_upgrade_pickaxe() -> void:
	var cost := mine_upgrade_cost()
	if money < cost:
		return
	money -= cost
	pickaxe_level += 1
	save_game()
	refresh()

func mine_go_deeper() -> void:
	var cost := mine_depth_cost()
	if ore < cost:
		return
	ore -= cost
	mine_depth += 1
	save_game()
	refresh()

func build_mine() -> void:
	content.add_child(make_label("폐광 탐험  ·  지하 %d층" % mine_depth, 31))
	var stage := Control.new()
	stage.custom_minimum_size.y = 230
	stage.clip_contents = true
	content.add_child(stage)
	var art := TextureRect.new()
	art.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	art.texture = load("res://assets/mine_cave.svg")
	art.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	stage.add_child(art)
	mine_art = art
	mine_effect_layer = Control.new()
	mine_effect_layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mine_effect_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	stage.add_child(mine_effect_layer)
	mine_status = make_label("", 24)
	content.add_child(mine_status)
	mine_energy_bar = ProgressBar.new()
	mine_energy_bar.custom_minimum_size.y = 22
	mine_energy_bar.show_percentage = false
	mine_energy_bar.max_value = max_mine_energy()
	mine_energy_bar.value = mine_energy
	mine_energy_bar.add_theme_stylebox_override("background", panel_style(Color("#191923"), Color("#554b43"), 0))
	mine_energy_bar.add_theme_stylebox_override("fill", panel_style(Color("#c79b51"), Color("#e6c479"), 0))
	content.add_child(mine_energy_bar)
	content.add_child(make_label("보석 ◆ %d개   |   %s" % [gems, last_mine_find], 21))
	var dig := make_button("곡괭이질  +%s원 / 광석 %d개" % [number(float(20 * pickaxe_level * mine_depth) * prestige_multiplier()), pickaxe_level])
	dig.custom_minimum_size.y = 105
	decorate_button(dig, true)
	dig.disabled = mine_energy < 1.0
	dig.pressed.connect(mine_dig)
	content.add_child(dig)
	mine_buttons.append(dig)
	var pick := make_button("곡괭이 강화  Lv.%d → %d\n%s원" % [pickaxe_level, pickaxe_level + 1, number(mine_upgrade_cost())])
	pick.disabled = money < mine_upgrade_cost()
	pick.pressed.connect(mine_upgrade_pickaxe)
	content.add_child(pick)
	mine_buttons.append(pick)
	var deeper := make_button("다음 층 내려가기\n광석 %d개 필요" % mine_depth_cost())
	deeper.disabled = ore < mine_depth_cost()
	deeper.pressed.connect(mine_go_deeper)
	content.add_child(deeper)
	mine_buttons.append(deeper)
	content.add_child(make_label("기력은 시간이 지나면 자동 회복됩니다.", 19))

func refresh_header() -> void:
	if header == null:
		return
	var next_text := "밑바닥 인생     %s원" % number(money)
	if header.text != next_text:
		header.text = next_text
	income_label.text = "터치 +%s원     자동 +%s원/초" % [number(float(tap_level) * 10.0 * prestige_multiplier()), number(total_auto_income() * prestige_multiplier())]

func number(n: float) -> String:
	if n >= 1000000000000.0:
		return "%.2f조" % (n / 1000000000000.0)
	if n >= 100000000.0:
		return "%.2f억" % (n / 100000000.0)
	if n >= 10000.0:
		return "%.1f만" % (n / 10000.0)
	return str(int(n))

func refresh() -> void:
	business_buttons.clear()
	growth_buttons.clear()
	mine_buttons.clear()
	mine_status = null
	mine_energy_bar = null
	mine_art = null
	mine_effect_layer = null
	if hero_idle_tween and hero_idle_tween.is_running():
		hero_idle_tween.kill()
	hero_sprite = null
	tap_cost_label = null
	auto_cost_label = null
	street_stage = null
	float_layer = null
	tap_upgrade_button = null
	auto_upgrade_button = null
	refresh_header()
	for child in content.get_children():
		content.remove_child(child)
		child.queue_free()
	match current_tab:
		0:
			build_street()
		1:
			build_business()
		2:
			build_mine()
		3:
			build_growth()
		4:
			build_rebirth()

func build_placeholder(title: String, description: String) -> void:
	content.add_child(make_label(title, 45))
	content.add_child(make_label(description, 25))

func build_street() -> void:
	content.add_child(make_label("제1장  ·  비 내린 골목", 29))
	if offline_report != "":
		content.add_child(make_label(offline_report, 19))
	var scene_area := Control.new()
	scene_area.custom_minimum_size.y = 280
	scene_area.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scene_area.clip_contents = true
	content.add_child(scene_area)
	street_stage = scene_area
	var backdrop := TextureRect.new()
	backdrop.texture = load("res://assets/street_pixel.svg")
	backdrop.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	backdrop.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	backdrop.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	backdrop.mouse_filter = Control.MOUSE_FILTER_IGNORE
	scene_area.add_child(backdrop)
	var atmosphere := Control.new()
	atmosphere.set_script(load("res://scripts/street_atmosphere.gd"))
	atmosphere.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	atmosphere.mouse_filter = Control.MOUSE_FILTER_IGNORE
	scene_area.add_child(atmosphere)
	var rain := Control.new()
	rain.set_script(load("res://scripts/rain_overlay.gd"))
	rain.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	rain.mouse_filter = Control.MOUSE_FILTER_IGNORE
	scene_area.add_child(rain)
	# Reliable texture fallback until procedural sprite is verified on Android.
	var hero := TextureRect.new()
	hero.texture = hero_base_texture
	hero.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	hero.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	hero.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	hero.anchor_left = 0.31
	hero.anchor_right = 0.69
	hero.anchor_top = 0.18
	hero.anchor_bottom = 0.89
	hero.mouse_filter = Control.MOUSE_FILTER_IGNORE
	scene_area.add_child(hero)
	hero_sprite = hero
	var foreground := Control.new()
	foreground.set_script(load("res://scripts/street_foreground.gd"))
	foreground.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	foreground.mouse_filter = Control.MOUSE_FILTER_IGNORE
	scene_area.add_child(foreground)
	hero_blink_clock = 0.0
	hero_blink_active = false
	hero.pivot_offset = Vector2(0, 0)
	hero_idle_tween = create_tween().set_loops()
	hero_idle_tween.tween_property(hero, "modulate", Color("#d7d0e1"), 1.15).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	hero_idle_tween.tween_property(hero, "modulate", Color.WHITE, 1.15).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

	var tap := Button.new()
	tap.flat = true
	tap.text = ""
	tap.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	tap.pressed.connect(tap_money)
	scene_area.add_child(tap)
	float_layer = Control.new()
	float_layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	float_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	scene_area.add_child(float_layer)
	feedback = make_label("화면을 터치해 돈을 벌어보세요", 23)
	feedback.anchor_left = 0.05
	feedback.anchor_right = 0.95
	feedback.anchor_top = 0.90
	feedback.anchor_bottom = 1.0
	feedback.grow_horizontal = Control.GROW_DIRECTION_BOTH
	feedback.mouse_filter = Control.MOUSE_FILTER_IGNORE
	scene_area.add_child(feedback)
	content.add_child(make_label("생존 능력 강화", 25))
	var separator := HSeparator.new()
	content.add_child(separator)
	var tap_cost := 100.0 * pow(1.35, tap_level - 1)
	var tap_row := HBoxContainer.new()
	tap_row.custom_minimum_size.y = 82
	content.add_child(tap_row)
	var tap_info := VBoxContainer.new()
	tap_info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	tap_row.add_child(tap_info)
	tap_info.add_child(make_label("터치 수익 · Lv.%d" % tap_level, 23))
	tap_info.add_child(make_label("%s원 → %s원 / 터치" % [number(tap_level * 10.0), number((tap_level + 1) * 10.0)], 18))
	var tap_upgrade := make_button("강화\n%s원" % number(tap_cost))
	tap_upgrade.custom_minimum_size = Vector2(190, 82)
	tap_upgrade.disabled = money < tap_cost
	tap_upgrade.pressed.connect(buy_tap)
	tap_row.add_child(tap_upgrade)
	tap_upgrade_button = tap_upgrade
	decorate_button(tap_upgrade, true)
	var auto_cost := 250.0 * pow(1.42, auto_level)
	var auto_row := HBoxContainer.new()
	auto_row.custom_minimum_size.y = 82
	content.add_child(auto_row)
	var auto_info := VBoxContainer.new()
	auto_info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	auto_row.add_child(auto_info)
	auto_info.add_child(make_label("자동 수익 · Lv.%d" % auto_level, 23))
	auto_info.add_child(make_label("%s원 → %s원 / 초" % [number(auto_level * 5.0), number((auto_level + 1) * 5.0)], 18))
	var auto_upgrade := make_button("강화\n%s원" % number(auto_cost))
	auto_upgrade.custom_minimum_size = Vector2(190, 82)
	auto_upgrade.disabled = money < auto_cost
	auto_upgrade.pressed.connect(buy_auto)
	auto_row.add_child(auto_upgrade)
	auto_upgrade_button = auto_upgrade
	decorate_button(auto_upgrade, true)

func tap_money() -> void:
	var earned := float(tap_level) * 10.0 * prestige_multiplier()
	money += earned
	run_earned += earned
	feedback.text = "+%s원!" % number(earned)
	spawn_floating_money()
	if is_instance_valid(hero_sprite):
		if pop_tween and pop_tween.is_running():
			pop_tween.kill()
		hero_sprite.scale = Vector2(0.91, 0.91)
		hero_sprite.modulate = Color("#ffe2ad")
		pop_tween = create_tween()
		pop_tween.set_parallel(true)
		pop_tween.tween_property(hero_sprite, "scale", Vector2.ONE, 0.18).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		pop_tween.tween_property(hero_sprite, "modulate", Color.WHITE, 0.18)
	refresh_header()
	refresh_upgrade_buttons()

func spawn_floating_money() -> void:
	if not is_instance_valid(float_layer):
		return
	var label := make_label("+%s" % number(float(tap_level) * 10.0 * prestige_multiplier()), 34)
	label.add_theme_color_override("font_color", Color("#ffd37b"))
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.position = Vector2(float_layer.size.x * randf_range(0.30, 0.65), float_layer.size.y * randf_range(0.35, 0.65))
	float_layer.add_child(label)
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(label, "position:y", label.position.y - 115.0, 0.75).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.tween_property(label, "modulate:a", 0.0, 0.75)
	tween.set_parallel(false)
	tween.tween_callback(label.queue_free)

func buy_tap() -> void:
	var cost := 100.0 * pow(1.35, tap_level - 1)
	if money < cost:
		return
	money -= cost
	tap_level += 1
	save_game()
	refresh()

func buy_auto() -> void:
	var cost := 250.0 * pow(1.42, auto_level)
	if money < cost:
		return
	money -= cost
	auto_level += 1
	save_game()
	refresh()
