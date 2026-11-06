extends Control

const SAVE_PATH = "user://bottomlife_v1.json"
const SAVE_BACKUP_PATH = "user://bottomlife_v1.backup.json"
var money: float = 0.0
var run_earned: float = 0.0
var rebirth_count: int = 0
var soul_points: int = 0
var soul_power: int = 0
var offline_report: String = ""
var tap_level: int = 1
var auto_level: int = 0
var business_levels: Array[int] = [0, 0, 0, 0, 0]
var mine_depth: int = 1
var pickaxe_level: int = 1
var ore: int = 0
var gems: int = 0
var luck_level: int = 0
var stamina_level: int = 0
var last_mine_find: String = ""
var mine_dig_counter: int = 0
var mine_event_flash: bool = false
var growth_buttons: Array[Button] = []
var mine_energy: float = 10.0
var mine_buttons: Array[Button] = []
var mine_sell_button: Button
var mine_craft_buttons: Array[Button] = []
var mine_resource_label: Label
var mine_result_label: Label
var detail_scroll: ScrollContainer
var detail_scroll_position: int = 0
var tab_scroll_positions: Array[int] = [0, 0, 0, 0, 0]
var mine_status: Label
var mine_energy_bar: ProgressBar
var rare_ore: int = 0
var soul_mining: int = 0
var claimed_legacy: Array[int] = []
const LEGACY_MILESTONES := [1, 3, 5, 10, 20]
const LEGACY_REWARDS := [2, 5, 10, 25, 60]
var drill_level: int = 0
var refinery_level: int = 0
var mine_art: TextureRect
var mine_effect_layer: Control
var mine_flash_tween: Tween
const MINE_MAX_ENERGY := 10.0
const BUSINESS_NAMES := ["길거리 노점", "분식 가게", "동네 편의점", "작은 식당", "동네 마트"]
const BUSINESS_BASE_COST := [1000.0, 15000.0, 150000.0, 2000000.0, 30000000.0]
const BUSINESS_BASE_INCOME := [12.0, 95.0, 780.0, 7500.0, 85000.0]
var current_tab: int = 0
var header: Label
var income_label: Label
var content: VBoxContainer
var feedback: Label
var save_clock: float = 0.0
var ui_clock: float = 0.0
var hero_sprite: TextureRect
var hero_outfit: Control
var street_evolution: Control
var hero_tier_label: Label
var hero_tier_progress: ProgressBar
var displayed_hero_tier: int = -1
var hero_idle_tween: Tween
var hero_blink_clock: float = 0.0
var hero_blink_active: bool = false
var hero_base_texture: Texture2D = preload("res://assets/hero_pixel.svg")
var hero_blink_texture: Texture2D = preload("res://assets/hero_pixel_blink.svg")
var tap_upgrade_button: Button
var auto_upgrade_button: Button
var idle_time: float = 0.0
var pop_tween: Tween
var street_hit_clock: float = 0.0
var street_hit_phase: int = 0
var tap_combo: int = 0
var street_taps: int = 0
var street_event_label: Label
var street_event_popup: PanelContainer
var street_event_popup_tween: Tween
var tap_combo_clock: float = 0.0
var combo_label: Label
var street_stage: Control
var float_layer: Control
var tab_buttons: Array[Button] = []
var business_buttons: Array[Button] = []
var business_income_label: Label
var business_buy_mode: int = 1
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
	if is_instance_valid(hero_outfit):
		update_hero_appearance()
	if street_hit_clock > 0.0:
		street_hit_clock = maxf(0.0, street_hit_clock - delta)
		if street_hit_clock == 0.0 and is_instance_valid(hero_sprite):
			hero_sprite.rotation_degrees = 0.0
	if tap_combo > 0:
		tap_combo_clock += delta
		if tap_combo_clock >= 2.0:
			tap_combo = 0
			if is_instance_valid(combo_label):
				combo_label.text = "연속 터치로 콤보를 쌓아보세요"
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

func parse_save_json(raw: String) -> Variant:
	# JSON.parse() returns an error code without emitting an engine ERROR log.
	# A corrupt primary save is expected during backup recovery.
	var parser := JSON.new()
	if parser.parse(raw) != OK:
		return null
	return parser.data if parser.data is Dictionary else null

func load_game() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		return
	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file == null:
		return
	var data = parse_save_json(file.get_as_text())
	if not (data is Dictionary) and FileAccess.file_exists(SAVE_BACKUP_PATH):
		data = parse_save_json(FileAccess.get_file_as_string(SAVE_BACKUP_PATH))
		if data is Dictionary:
			offline_report = "저장 파일 손상 감지 · 이전 백업 복원"
			# Repair the primary file immediately so another restart can recover too.
			DirAccess.copy_absolute(ProjectSettings.globalize_path(SAVE_BACKUP_PATH), ProjectSettings.globalize_path(SAVE_PATH))
	if data is Dictionary:
		money = maxf(0.0, float(data.get("money", 0.0)))
		run_earned = maxf(money, float(data.get("run_earned", money)))
		rebirth_count = maxi(0, int(data.get("rebirth_count", 0)))
		soul_points = maxi(0, int(data.get("soul_points", 0)))
		soul_power = clampi(int(data.get("soul_power", 0)), 0, 1000)
		soul_mining = clampi(int(data.get("soul_mining", 0)), 0, 100)
		var saved_legacy = data.get("claimed_legacy", [])
		if saved_legacy is Array:
			for milestone in saved_legacy:
				var value := int(milestone)
				if value in LEGACY_MILESTONES and not claimed_legacy.has(value):
					claimed_legacy.append(value)
		tap_level = maxi(1, int(data.get("tap_level", 1)))
		street_taps = maxi(0, int(data.get("street_taps", 0)))
		auto_level = maxi(0, int(data.get("auto_level", 0)))
		var saved_business = data.get("business_levels", [0, 0, 0])
		if saved_business is Array:
			for i in range(mini(BUSINESS_NAMES.size(), saved_business.size())):
				business_levels[i] = clampi(int(saved_business[i]), 0, 100000)
		mine_depth = maxi(1, int(data.get("mine_depth", 1)))
		mine_dig_counter = maxi(0, int(data.get("mine_dig_counter", 0)))
		pickaxe_level = maxi(1, int(data.get("pickaxe_level", 1)))
		ore = maxi(0, int(data.get("ore", 0)))
		rare_ore = maxi(0, int(data.get("rare_ore", 0)))
		drill_level = clampi(int(data.get("drill_level", 0)), 0, 50)
		refinery_level = clampi(int(data.get("refinery_level", 0)), 0, 50)
		gems = maxi(0, int(data.get("gems", 0)))
		luck_level = clampi(int(data.get("luck_level", 0)), 0, 50)
		stamina_level = clampi(int(data.get("stamina_level", 0)), 0, 50)
		mine_energy = clampf(float(data.get("mine_energy", max_mine_energy())), 0.0, max_mine_energy())
		var saved_at := float(data.get("saved_at", 0.0))
		if saved_at > 0.0:
			var elapsed := clampf(Time.get_unix_time_from_system() - saved_at, 0.0, 14400.0)
			mine_energy = minf(max_mine_energy(), mine_energy + elapsed * (0.4 + float(stamina_level) * 0.08))
			var offline_gain := total_auto_income() * prestige_multiplier() * elapsed * 0.5
			if offline_gain > 0.0:
				money += offline_gain
				run_earned += offline_gain
				offline_report = "부재중 수익 +%s원 (%d분)" % [number(offline_gain), int(elapsed / 60.0)]

func save_game() -> void:
	# Keep the last valid save before overwriting the primary file.
	if FileAccess.file_exists(SAVE_PATH):
		var previous = parse_save_json(FileAccess.get_file_as_string(SAVE_PATH))
		if previous is Dictionary:
			DirAccess.copy_absolute(ProjectSettings.globalize_path(SAVE_PATH), ProjectSettings.globalize_path(SAVE_BACKUP_PATH))
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file != null:
		file.store_string(JSON.stringify({"money": money, "tap_level": tap_level, "street_taps": street_taps, "auto_level": auto_level, "business_levels": business_levels, "mine_depth": mine_depth, "mine_energy": mine_energy, "mine_dig_counter": mine_dig_counter, "pickaxe_level": pickaxe_level, "ore": ore, "rare_ore": rare_ore, "drill_level": drill_level, "refinery_level": refinery_level, "gems": gems, "luck_level": luck_level, "stamina_level": stamina_level, "run_earned": run_earned, "rebirth_count": rebirth_count, "soul_points": soul_points, "soul_power": soul_power, "soul_mining": soul_mining, "claimed_legacy": claimed_legacy, "saved_at": Time.get_unix_time_from_system()}))

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
	if is_instance_valid(mine_resource_label):
		mine_resource_label.text = "보석 ◆ %d개  |  희귀 광물 %d개" % [gems, rare_ore]
	if is_instance_valid(mine_result_label):
		mine_result_label.text = last_mine_find
	if is_instance_valid(mine_sell_button):
		mine_sell_button.disabled = rare_ore <= 0
	for kind in range(mine_craft_buttons.size()):
		if is_instance_valid(mine_craft_buttons[kind]):
			var level := drill_level if kind == 0 else refinery_level
			mine_craft_buttons[kind].disabled = level >= 50 or rare_ore < craft_cost(kind)
	if mine_buttons.size() == 3:
		if is_instance_valid(mine_buttons[0]):
			mine_buttons[0].disabled = mine_energy < 1.0
		if is_instance_valid(mine_buttons[1]):
			mine_buttons[1].disabled = money < mine_upgrade_cost()
		if is_instance_valid(mine_buttons[2]):
			mine_buttons[2].disabled = ore < mine_depth_cost() or next_mine_rebirth_requirement() > rebirth_count
	if is_instance_valid(business_income_label):
		business_income_label.text = "사업 수익  +%s원/초" % number((total_auto_income() - float(auto_level) * 5.0) * prestige_multiplier())
	for i in range(business_buttons.size()):
		if is_instance_valid(business_buttons[i]):
			var count := business_purchase_count(i)
			business_buttons[i].disabled = count == 0
			business_buttons[i].text = "확장 x%d\n%s원" % [count, number(business_purchase_cost(i, count))] if count > 0 else "구매 불가"
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
	header = make_label("", 27)
	top_box.add_child(header)
	income_label = make_label("", 18)
	top_box.add_child(income_label)
	content = VBoxContainer.new()
	content.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content.add_theme_constant_override("separation", 8)
	outer.add_child(content)
	var bottom := HBoxContainer.new()
	bottom.custom_minimum_size.y = 76
	bottom.add_theme_constant_override("separation", 4)
	outer.add_child(bottom)
	var tabs := ["거리", "사업", "광산", "성장", "메뉴"]
	for i in range(tabs.size()):
		var b := make_button(tabs[i])
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		b.add_theme_font_size_override("font_size", 18)
		b.custom_minimum_size.y = 72
		decorate_button(b, i == current_tab)
		b.pressed.connect(change_tab.bind(i))
		bottom.add_child(b)
		tab_buttons.append(b)

func change_tab(index: int) -> void:
	if index == current_tab:
		return
	if is_instance_valid(detail_scroll):
		tab_scroll_positions[current_tab] = detail_scroll.scroll_vertical
		# The old tab's scroll container must not overwrite the new tab's position.
		detail_scroll = null
	current_tab = index
	detail_scroll_position = tab_scroll_positions[index]
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

func claim_legacy(milestone: int) -> void:
	var index := LEGACY_MILESTONES.find(milestone)
	if index < 0 or rebirth_count < milestone or claimed_legacy.has(milestone):
		return
	claimed_legacy.append(milestone)
	soul_points += LEGACY_REWARDS[index]
	save_game()
	refresh()

func soul_mining_cost() -> int:
	return 2 + soul_mining * 2

func buy_soul_mining() -> void:
	var cost := soul_mining_cost()
	if soul_points < cost or soul_mining >= 100:
		return
	soul_points -= cost
	soul_mining += 1
	save_game()
	refresh()

func soul_mining_multiplier() -> float:
	return 1.0 + float(soul_mining) * 0.05

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
	street_taps = 0
	auto_level = 0
	business_levels = [0, 0, 0, 0, 0]
	mine_depth = 1
	mine_dig_counter = 0
	pickaxe_level = 1
	ore = 0
	rare_ore = 0
	drill_level = 0
	refinery_level = 0
	gems = 0
	luck_level = 0
	stamina_level = 0
	mine_energy = MINE_MAX_ENERGY
	tab_scroll_positions = [0, 0, 0, 0, 0]
	detail_scroll_position = 0
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
	content.add_child(make_label("환생의 제단", 28))
	if offline_report != "":
		content.add_child(make_label(offline_report, 20))
	content.add_child(make_label("환생 %d회  |  영혼 %d개" % [rebirth_count, soul_points], 23))
	content.add_child(make_label("영구 수익 배율  x%.1f" % prestige_multiplier(), 22))
	content.add_child(make_label("영구 채굴 배율  x%.2f" % soul_mining_multiplier(), 21))
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
	content.add_child(make_label("환생 준비도  %d%%" % int(clampf(run_earned / 1000000.0 * 100.0, 0.0, 100.0)), 19))
	var reward := rebirth_reward()
	content.add_child(make_label("현재 환생 보상: 영혼 %d개" % reward, 24))
	var upgrade := make_button("영혼의 힘 강화  수익 +10%%\n영혼 %d개" % soul_upgrade_cost())
	upgrade.disabled = soul_points < soul_upgrade_cost() or soul_power >= 1000
	upgrade.pressed.connect(buy_soul_power)
	content.add_child(upgrade)
	var mining_upgrade := make_button("영혼의 광부 Lv.%d/100  ·  채굴 수익/광석 +5%%\n영혼 %d개" % [soul_mining, soul_mining_cost()])
	mining_upgrade.disabled = soul_points < soul_mining_cost() or soul_mining >= 100
	mining_upgrade.pressed.connect(buy_soul_mining)
	content.add_child(mining_upgrade)
	var button := make_button("환생하기  |  영혼 +%d" % reward)
	decorate_button(button, true)
	button.disabled = reward == 0
	button.pressed.connect(request_rebirth)
	content.add_child(button)
	content.add_child(make_label("새로운 광산 지역 · 환생 3회에 지하도시 / 10회에 태고의 심층 해금", 19))
	content.add_child(make_label("환생 업적 · 영구 보상", 23))
	for i in range(LEGACY_MILESTONES.size()):
		var milestone: int = LEGACY_MILESTONES[i]
		var claimed: bool = claimed_legacy.has(milestone)
		var achieved: bool = rebirth_count >= milestone
		var status := "수령 완료" if claimed else ("보상 받기" if achieved else "잠김")
		var legacy_button := make_button("환생 %d회 달성 · 영혼 +%d\n%s" % [milestone, LEGACY_REWARDS[i], status])
		legacy_button.disabled = claimed or not achieved
		legacy_button.pressed.connect(claim_legacy.bind(milestone))
		content.add_child(legacy_button)
	content.add_child(make_label("환생 시 일반 성장과 보유 자원은 초기화됩니다.", 20))

func total_auto_income() -> float:
	var result := float(auto_level) * 5.0
	for i in range(BUSINESS_NAMES.size()):
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

func business_purchase_cost(index: int, count: int) -> float:
	if count <= 0:
		return 0.0
	var first := business_cost(index)
	var growth := 1.24
	return first * (pow(growth, count) - 1.0) / (growth - 1.0)

func business_purchase_count(index: int) -> int:
	var first := business_cost(index)
	if money < first:
		return 0
	var limit := mini(100000 - business_levels[index], 1000 if business_buy_mode == 0 else business_buy_mode)
	if limit <= 0:
		return 0
	var low := 0
	var high := limit
	while low < high:
		var mid := int((low + high + 1) / 2)
		if business_purchase_cost(index, mid) <= money:
			low = mid
		else:
			high = mid - 1
	return low

func set_business_buy_mode(mode: int) -> void:
	business_buy_mode = mode
	refresh()

func buy_business(index: int) -> void:
	var count := business_purchase_count(index)
	if count <= 0:
		return
	var cost := business_purchase_cost(index, count)
	if money + maxf(0.000001, money * 0.000000000001) < cost:
		return
	money -= cost
	business_levels[index] += count
	save_game()
	refresh()

func build_business() -> void:
	content.add_child(make_label("나만의 사업 거리", 27))
	var art := TextureRect.new()
	art.texture = load("res://assets/business_stall.svg")
	art.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	art.custom_minimum_size.y = 118
	content.add_child(art)
	business_income_label = make_label("사업 수익  +%s원/초" % number((total_auto_income() - float(auto_level) * 5.0) * prestige_multiplier()), 26)
	content.add_child(business_income_label)
	var mode_row := HBoxContainer.new()
	mode_row.add_theme_constant_override("separation", 6)
	content.add_child(mode_row)
	for mode in [1, 10, 0]:
		var mode_button := make_button("x%d" % mode if mode > 0 else "최대")
		mode_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		mode_button.custom_minimum_size.y = 60
		decorate_button(mode_button, mode == business_buy_mode)
		mode_button.pressed.connect(set_business_buy_mode.bind(mode))
		mode_row.add_child(mode_button)
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	content.add_child(scroll)
	detail_scroll = scroll
	if detail_scroll_position > 0:
		call_deferred("restore_detail_scroll", scroll, detail_scroll_position)
	var rows := VBoxContainer.new()
	rows.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	rows.add_theme_constant_override("separation", 12)
	scroll.add_child(rows)
	for i in range(BUSINESS_NAMES.size()):
		var panel := PanelContainer.new()
		panel.add_theme_stylebox_override("panel", panel_style(Color("#24212c"), Color("#826744"), 2))
		rows.add_child(panel)
		var row := HBoxContainer.new()
		panel.add_child(row)
		var info := VBoxContainer.new()
		info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(info)
		info.add_child(make_label("%s  Lv.%d" % [BUSINESS_NAMES[i], business_levels[i]], 20))
		info.add_child(make_label("+%s원/초" % number(float(business_levels[i]) * BUSINESS_BASE_INCOME[i] * business_milestone_multiplier(business_levels[i]) * prestige_multiplier()), 19))
		var next_goal := 25 if business_levels[i] < 25 else (50 if business_levels[i] < 50 else (100 if business_levels[i] < 100 else 0))
		info.add_child(make_label("다음 보너스: Lv.%d (%d 남음)" % [next_goal, next_goal - business_levels[i]] if next_goal > 0 else "모든 단계 보너스 달성!", 16))
		var milestone_bar := ProgressBar.new()
		milestone_bar.custom_minimum_size.y = 10
		milestone_bar.show_percentage = false
		milestone_bar.max_value = 100.0
		var previous_goal: int = 0 if business_levels[i] < 25 else (25 if business_levels[i] < 50 else 50)
		milestone_bar.value = 100.0 if next_goal == 0 else clampf(float(business_levels[i] - previous_goal) / float(next_goal - previous_goal) * 100.0, 0.0, 100.0)
		info.add_child(milestone_bar)
		var count := business_purchase_count(i)
		var cost := business_purchase_cost(i, count)
		var button := make_button("확장 x%d\n%s원" % [count, number(cost)] if count > 0 else "구매 불가")
		button.custom_minimum_size = Vector2(122, 78)
		button.disabled = count == 0
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
	content.add_child(make_label("생존자의 성장", 28))
	content.add_child(make_label("보유 보석  ◆ %d개" % gems, 23))
	content.add_child(make_label("광산 보석으로 능력 강화", 20))
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	content.add_child(scroll)
	detail_scroll = scroll
	if detail_scroll_position > 0:
		call_deferred("restore_detail_scroll", scroll, detail_scroll_position)
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
		box.add_child(make_label(("행운의 감각" if i == 0 else "강인한 체력") + "  Lv.%d/50" % level, 23))
		var level_bar := ProgressBar.new()
		level_bar.custom_minimum_size.y = 12
		level_bar.show_percentage = false
		level_bar.max_value = 50.0
		level_bar.value = float(level)
		box.add_child(level_bar)
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

func mine_event_name() -> String:
	if mine_depth >= 125:
		return "태고의 수정 폭발"
	if mine_depth >= 75:
		return "지하도시 보물 창고"
	if mine_depth >= 50:
		return "심연의 광맥"
	if mine_depth >= 25:
		return "황금 광맥"
	if mine_depth >= 10:
		return "푸른 광석 군집"
	return "숨겨진 광석 더미"

func trigger_mine_event() -> String:
	var bonus_ore: int = maxi(5, (pickaxe_level + drill_level) * 4)
	var bonus_gems: int = maxi(1, int(mine_depth / 15))
	var bonus_rare: int = maxi(1, int(mine_depth / 20))
	if mine_depth >= 75:
		gems += bonus_gems
		rare_ore += bonus_rare
		return "%s! 보석 +%d / 희귀 광물 +%d" % [mine_event_name(), bonus_gems, bonus_rare]
	if mine_depth >= 25:
		rare_ore += bonus_rare
		ore += bonus_ore
		return "%s! 광석 +%d / 희귀 광물 +%d" % [mine_event_name(), bonus_ore, bonus_rare]
	ore += bonus_ore
	return "%s! 광석 +%d" % [mine_event_name(), bonus_ore]

func mine_dig() -> void:
	if mine_energy < 1.0:
		return
	mine_energy -= 1.0
	mine_dig_counter += 1
	mine_event_flash = false
	var reward := float(20 * (pickaxe_level + drill_level) * mine_depth)
	reward *= prestige_multiplier() * mine_zone_bonus() * soul_mining_multiplier()
	money += reward
	run_earned += reward
	ore += maxi(1, int(ceil(float(pickaxe_level + drill_level) * soul_mining_multiplier())))
	var rare_chance := minf(0.25, 0.01 + float(mine_depth) * 0.002)
	var found_rare := randf() < rare_chance
	if found_rare:
		rare_ore += 1 + int(mine_depth / 25) + int(refinery_level / 5)
	var chance := minf(0.60, 0.03 + float(luck_level) * 0.01 + float(mine_depth - 1) * 0.002)
	if randf() < chance:
		var found := 1 + int(mine_depth / 10)
		gems += found
		last_mine_find = "희귀 보석 %d개 발견!" % found
	else:
		last_mine_find = "희귀 광물 발견!" if found_rare else "광석 %d개 획득" % maxi(1, int(ceil(float(pickaxe_level + drill_level) * soul_mining_multiplier())))
	if mine_dig_counter % 15 == 0:
		last_mine_find = trigger_mine_event()
		mine_event_flash = true
	save_game()
	refresh()
	play_mine_hit_effect()

func play_mine_hit_effect() -> void:
	if not is_instance_valid(mine_art) or not is_instance_valid(mine_effect_layer):
		return
	if mine_flash_tween and mine_flash_tween.is_running():
		mine_flash_tween.kill()
	var is_event: bool = mine_event_flash
	var found_gem: bool = last_mine_find.begins_with("희귀 보석")
	var effect_color: Color = Color("#ffcd73") if is_event else (Color("#8ef4ff") if found_gem else Color("#ffe0a0"))
	mine_art.modulate = effect_color if is_event else Color("#fff0b3")
	mine_flash_tween = create_tween()
	mine_flash_tween.tween_property(mine_art, "modulate", Color.WHITE, 0.48 if is_event else 0.28)
	var flash: Label = make_label("특별 채굴 이벤트!" if is_event else ("보석 발견!" if found_gem else "쾅! +광석"), 26 if is_event else 30)
	flash.z_index = 2
	flash.add_theme_color_override("font_color", effect_color)
	flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	flash.position = Vector2(18, 70)
	mine_effect_layer.add_child(flash)
	var motion: Tween = create_tween()
	motion.set_parallel(true)
	motion.tween_property(flash, "position:y", 12.0, 1.25 if is_event else 0.8).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	motion.tween_property(flash, "modulate:a", 0.0, 1.25 if is_event else 0.8)
	motion.set_parallel(false)
	motion.tween_callback(flash.queue_free)
	if is_event:
		for i in range(12):
			var spark: ColorRect = ColorRect.new()
			spark.color = effect_color
			spark.mouse_filter = Control.MOUSE_FILTER_IGNORE
			spark.size = Vector2(5.0 + float(i % 3) * 3.0, 5.0 + float(i % 3) * 3.0)
			spark.position = Vector2(115.0, 95.0)
			mine_effect_layer.add_child(spark)
			var angle: float = TAU * float(i) / 12.0
			var target: Vector2 = spark.position + Vector2(cos(angle), sin(angle)) * (45.0 + float(i % 4) * 14.0)
			var burst: Tween = create_tween()
			burst.set_parallel(true)
			burst.tween_property(spark, "position", target, 0.75).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
			burst.tween_property(spark, "modulate:a", 0.0, 0.75)
			burst.set_parallel(false)
			burst.tween_callback(spark.queue_free)
	mine_event_flash = false

func mine_upgrade_pickaxe() -> void:
	var cost := mine_upgrade_cost()
	if money < cost:
		return
	money -= cost
	pickaxe_level += 1
	save_game()
	refresh()

func craft_cost(kind: int) -> int:
	var level := drill_level if kind == 0 else refinery_level
	return 3 + level * 2 + int(level * level / 4)

func craft_equipment(kind: int) -> void:
	var level := drill_level if kind == 0 else refinery_level
	var cost := craft_cost(kind)
	if level >= 50 or rare_ore < cost:
		return
	rare_ore -= cost
	if kind == 0:
		drill_level += 1
	else:
		refinery_level += 1
	last_mine_find = "장비 제작 성공!"
	save_game()
	refresh()

func sell_rare_ore() -> void:
	if rare_ore <= 0:
		return
	var income := float(rare_ore) * 2500.0 * float(mine_depth) * prestige_multiplier() * (1.0 + float(refinery_level) * 0.1)
	money += income
	run_earned += income
	rare_ore = 0
	last_mine_find = "희귀 광물 판매 +%s원" % number(income)
	save_game()
	refresh()

func mine_zone_name() -> String:
	if mine_depth >= 125:
		return "태고의 심층"
	if mine_depth >= 75:
		return "망각의 지하도시"
	if mine_depth >= 50:
		return "심연의 수정동굴"
	if mine_depth >= 25:
		return "잊힌 금맥"
	if mine_depth >= 10:
		return "푸른 광맥"
	return "버려진 폐광"

func mine_zone_bonus() -> float:
	if mine_depth >= 125:
		return 12.0
	if mine_depth >= 75:
		return 7.0
	if mine_depth >= 50:
		return 4.0
	if mine_depth >= 25:
		return 2.5
	if mine_depth >= 10:
		return 1.5
	return 1.0

func next_mine_rebirth_requirement() -> int:
	if mine_depth == 74:
		return 3
	if mine_depth == 124:
		return 10
	return 0

func mine_go_deeper() -> void:
	var required := next_mine_rebirth_requirement()
	if required > rebirth_count:
		last_mine_find = "새 지역 해금: 환생 %d회 필요" % required
		refresh()
		return
	var cost := mine_depth_cost()
	if ore < cost:
		return
	ore -= cost
	mine_depth += 1
	if mine_depth % 5 == 0:
		var bonus := maxi(1, int(mine_depth / 5))
		gems += bonus
		last_mine_find = "지하 %d층 돌파! 보석 %d개 보상" % [mine_depth, bonus]
	else:
		last_mine_find = "지하 %d층 도착" % mine_depth
	save_game()
	refresh()

func build_mine() -> void:
	content.add_child(make_label("%s  ·  지하 %d층" % [mine_zone_name(), mine_depth], 27))
	content.add_child(make_label("지역 채굴 수익 x%.1f  |  5층마다 보석 보상" % mine_zone_bonus(), 19))
	content.add_child(make_label("채굴 이벤트: %s · %d/15회" % [mine_event_name(), mine_dig_counter % 15], 18))
	if next_mine_rebirth_requirement() > rebirth_count:
		content.add_child(make_label("다음 지역 잠김 · 환생 %d회 필요" % next_mine_rebirth_requirement(), 20))
	var stage := Control.new()
	stage.custom_minimum_size.y = 170
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
	var mineral_overlay := Control.new()
	mineral_overlay.set_script(load("res://scripts/mine_zone_overlay.gd"))
	mineral_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mineral_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	mineral_overlay.set("zone", 5 if mine_depth >= 125 else (4 if mine_depth >= 75 else (3 if mine_depth >= 50 else (2 if mine_depth >= 25 else (1 if mine_depth >= 10 else 0)))))
	stage.add_child(mineral_overlay)
	mine_effect_layer = Control.new()
	mine_effect_layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mine_effect_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	stage.add_child(mine_effect_layer)
	mine_status = make_label("", 21)
	content.add_child(mine_status)
	mine_energy_bar = ProgressBar.new()
	mine_energy_bar.custom_minimum_size.y = 15
	mine_energy_bar.show_percentage = false
	mine_energy_bar.max_value = max_mine_energy()
	mine_energy_bar.value = mine_energy
	mine_energy_bar.add_theme_stylebox_override("background", panel_style(Color("#191923"), Color("#554b43"), 0))
	mine_energy_bar.add_theme_stylebox_override("fill", panel_style(Color("#c79b51"), Color("#e6c479"), 0))
	content.add_child(mine_energy_bar)
	mine_resource_label = make_label("보석 ◆ %d개  |  희귀 광물 %d개" % [gems, rare_ore], 21)
	content.add_child(mine_resource_label)
	mine_result_label = make_label(last_mine_find, 19)
	content.add_child(mine_result_label)
	var dig := make_button("곡괭이질  +%s원 / 광석 %d개" % [number(float(20 * (pickaxe_level + drill_level) * mine_depth) * prestige_multiplier() * mine_zone_bonus() * soul_mining_multiplier()), maxi(1, int(ceil(float(pickaxe_level + drill_level) * soul_mining_multiplier())))])
	dig.custom_minimum_size.y = 82
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
	deeper.disabled = ore < mine_depth_cost() or next_mine_rebirth_requirement() > rebirth_count
	deeper.pressed.connect(mine_go_deeper)
	content.add_child(deeper)
	mine_buttons.append(deeper)
	content.add_child(make_label("장비 제작 · 희귀 광물", 22))
	var equipment_row := HBoxContainer.new()
	equipment_row.add_theme_constant_override("separation", 8)
	content.add_child(equipment_row)
	for kind in range(2):
		var level := drill_level if kind == 0 else refinery_level
		var title := "강화 드릴" if kind == 0 else "정제 설비"
		var craft := make_button("%s Lv.%d\n광물 %d개" % [title, level, craft_cost(kind)])
		craft.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		craft.add_theme_font_size_override("font_size", 19)
		craft.disabled = level >= 50 or rare_ore < craft_cost(kind)
		craft.pressed.connect(craft_equipment.bind(kind))
		equipment_row.add_child(craft)
		mine_craft_buttons.append(craft)
	var sell := make_button("희귀 광물 모두 판매 · 개당 %s원" % number(float(2500 * mine_depth) * prestige_multiplier() * (1.0 + float(refinery_level) * 0.1)))
	sell.custom_minimum_size.y = 64
	sell.disabled = rare_ore <= 0
	sell.pressed.connect(sell_rare_ore)
	content.add_child(sell)
	mine_sell_button = sell
	content.add_child(make_label("기력은 시간이 지나면 자동 회복됩니다.", 18))

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
	if is_instance_valid(detail_scroll):
		detail_scroll_position = detail_scroll.scroll_vertical
		tab_scroll_positions[current_tab] = detail_scroll_position
	detail_scroll = null
	business_buttons.clear()
	business_income_label = null
	growth_buttons.clear()
	mine_buttons.clear()
	mine_craft_buttons.clear()
	mine_sell_button = null
	mine_resource_label = null
	mine_result_label = null
	mine_status = null
	mine_energy_bar = null
	mine_art = null
	mine_effect_layer = null
	if hero_idle_tween and hero_idle_tween.is_running():
		hero_idle_tween.kill()
	hero_sprite = null
	hero_outfit = null
	street_evolution = null
	hero_tier_label = null
	hero_tier_progress = null
	displayed_hero_tier = -1
	tap_cost_label = null
	auto_cost_label = null
	street_stage = null
	float_layer = null
	combo_label = null
	street_event_label = null
	street_event_popup = null
	if street_event_popup_tween and street_event_popup_tween.is_running():
		street_event_popup_tween.kill()
	street_event_popup_tween = null
	tap_upgrade_button = null
	auto_upgrade_button = null
	refresh_header()
	for child in content.get_children():
		content.remove_child(child)
		child.queue_free()
	match current_tab:
		0:
			build_street()
			wrap_content_scroll()
		1:
			build_business()
		2:
			build_mine()
			wrap_content_scroll()
		3:
			build_growth()
		4:
			build_rebirth()
			wrap_content_scroll()

func wrap_content_scroll() -> void:
	# Keep the bottom navigation visible even on short Android screens.
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	var inner := VBoxContainer.new()
	inner.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	inner.add_theme_constant_override("separation", 8)
	var existing := content.get_children()
	content.add_child(scroll)
	scroll.add_child(inner)
	for node in existing:
		node.reparent(inner)
	detail_scroll = scroll
	if detail_scroll_position > 0:
		call_deferred("restore_detail_scroll", scroll, detail_scroll_position)

func restore_detail_scroll(scroll: ScrollContainer, position: int) -> void:
	if is_instance_valid(scroll) and scroll == detail_scroll:
		scroll.scroll_vertical = position

func build_placeholder(title: String, description: String) -> void:
	content.add_child(make_label(title, 45))
	content.add_child(make_label(description, 25))

func hero_appearance_tier() -> int:
	if run_earned >= 100000000.0:
		return 3
	if run_earned >= 1000000.0:
		return 2
	if run_earned >= 10000.0:
		return 1
	return 0

func hero_appearance_name(tier: int) -> String:
	match tier:
		1:
			return "동네의 생존자"
		2:
			return "거리의 사업가"
		3:
			return "밑바닥의 전설"
	return "맨손의 거지"

func update_hero_appearance() -> void:
	var tier: int = hero_appearance_tier()
	if is_instance_valid(hero_tier_progress):
		var thresholds: Array[float] = [10000.0, 1000000.0, 100000000.0]
		hero_tier_progress.value = 100.0 if tier >= 3 else clampf(run_earned / thresholds[tier] * 100.0, 0.0, 100.0)
	if tier == displayed_hero_tier:
		return
	displayed_hero_tier = tier
	if is_instance_valid(street_evolution):
		street_evolution.set("tier", tier)
		street_evolution.queue_redraw()
	if is_instance_valid(hero_outfit):
		hero_outfit.set("tier", tier)
		hero_outfit.queue_redraw()
	if is_instance_valid(street_event_label):
		street_event_label.text = "거리 이벤트: %s  ·  %d/25 터치" % [street_event_title(), street_taps % 25]
	if is_instance_valid(hero_tier_label):
		hero_tier_label.text = "%s  ·  다음 외형: %s" % [hero_appearance_name(tier), "최고 단계" if tier == 3 else number([10000.0, 1000000.0, 100000000.0][tier]) + "원 누적"]

func build_street() -> void:
	content.add_child(make_label("제1장  ·  비 내린 골목", 29))
	if offline_report != "":
		content.add_child(make_label(offline_report, 19))
	var scene_area := Control.new()
	scene_area.custom_minimum_size.y = 280
	scene_area.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
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
	var evolution := Control.new()
	evolution.set_script(load("res://scripts/street_evolution.gd"))
	evolution.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	evolution.mouse_filter = Control.MOUSE_FILTER_IGNORE
	scene_area.add_child(evolution)
	street_evolution = evolution
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
	var outfit := Control.new()
	outfit.set_script(load("res://scripts/hero_outfit.gd"))
	outfit.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	outfit.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hero.add_child(outfit)
	hero_outfit = outfit
	var foreground := Control.new()
	foreground.set_script(load("res://scripts/street_foreground.gd"))
	foreground.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	foreground.mouse_filter = Control.MOUSE_FILTER_IGNORE
	scene_area.add_child(foreground)
	hero_blink_clock = 0.0
	hero_blink_active = false
	hero.pivot_offset = Vector2(0, 0)
	street_hit_clock = 0.0
	street_hit_phase = 0
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
	hero_tier_label = make_label("", 18)
	hero_tier_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	content.add_child(hero_tier_label)
	hero_tier_progress = ProgressBar.new()
	hero_tier_progress.custom_minimum_size.y = 12
	hero_tier_progress.show_percentage = false
	hero_tier_progress.max_value = 100.0
	content.add_child(hero_tier_progress)
	street_event_label = make_label("", 18)
	content.add_child(street_event_label)
	street_event_label.text = "거리 이벤트: %s  ·  %d/25 터치" % [street_event_title(), street_taps % 25]
	update_hero_appearance()
	combo_label = make_label("연속 터치로 콤보를 쌓아보세요", 18)
	combo_label.anchor_left = 0.05
	combo_label.anchor_right = 0.95
	combo_label.anchor_top = 0.02
	combo_label.anchor_bottom = 0.13
	combo_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	scene_area.add_child(combo_label)
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
	tap_info.add_child(make_label("터치 수익 · Lv.%d" % tap_level, 20))
	tap_info.add_child(make_label("%s원 → %s원 / 터치" % [number(tap_level * 10.0), number((tap_level + 1) * 10.0)], 18))
	var tap_upgrade := make_button("강화\n%s원" % number(tap_cost))
	tap_upgrade.custom_minimum_size = Vector2(126, 76)
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
	auto_info.add_child(make_label("자동 수익 · Lv.%d" % auto_level, 20))
	auto_info.add_child(make_label("%s원 → %s원 / 초" % [number(auto_level * 5.0), number((auto_level + 1) * 5.0)], 18))
	var auto_upgrade := make_button("강화\n%s원" % number(auto_cost))
	auto_upgrade.custom_minimum_size = Vector2(126, 76)
	auto_upgrade.disabled = money < auto_cost
	auto_upgrade.pressed.connect(buy_auto)
	auto_row.add_child(auto_upgrade)
	auto_upgrade_button = auto_upgrade
	decorate_button(auto_upgrade, true)

func street_event_title() -> String:
	match hero_appearance_tier():
		1:
			return "노점 손님 몰려옴"
		2:
			return "상점 특별 주문"
		3:
			return "도시 투자 계약"
	return "길거리 행운 발견"

func trigger_street_event() -> String:
	var tier: int = hero_appearance_tier()
	var reward: float = float(tap_level) * 10.0 * prestige_multiplier() * float(30 + tier * 25)
	money += reward
	run_earned += reward
	if tier >= 2:
		gems += tier - 1
	return "%s! +%s원%s" % [street_event_title(), number(reward), " / 보석 +%d" % (tier - 1) if tier >= 2 else ""]

func tap_money() -> void:
	tap_combo = mini(tap_combo + 1, 100)
	street_taps += 1
	tap_combo_clock = 0.0
	var combo_multiplier: float = 1.0 + float(mini(int(tap_combo / 10), 10)) * 0.05
	var earned: float = float(tap_level) * 10.0 * prestige_multiplier() * combo_multiplier
	money += earned
	run_earned += earned
	feedback.text = "+%s원!" % number(earned)
	if street_taps % 25 == 0:
		feedback.text = trigger_street_event()
		play_street_event_fx(feedback.text)
	if is_instance_valid(street_event_label):
		street_event_label.text = "거리 이벤트: %s  ·  %d/25 터치" % [street_event_title(), street_taps % 25]
	if is_instance_valid(combo_label):
		combo_label.text = "COMBO %d  ·  터치 수익 x%.2f" % [tap_combo, combo_multiplier]
	spawn_floating_money(earned)
	spawn_street_hit_sparks()
	if is_instance_valid(hero_sprite):
		if pop_tween and pop_tween.is_running():
			pop_tween.kill()
		street_hit_clock = 0.22
		street_hit_phase += 1
		hero_sprite.pivot_offset = hero_sprite.size * 0.5
		hero_sprite.scale = Vector2(0.93, 0.86)
		hero_sprite.rotation_degrees = -5.0 if street_hit_phase % 2 == 0 else 5.0
		hero_sprite.modulate = Color("#fff0c9")
		pop_tween = create_tween()
		pop_tween.set_parallel(true)
		pop_tween.tween_property(hero_sprite, "scale", Vector2.ONE, 0.22).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		pop_tween.tween_property(hero_sprite, "rotation_degrees", 0.0, 0.22).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		pop_tween.tween_property(hero_sprite, "modulate", Color.WHITE, 0.22)
	refresh_header()
	update_hero_appearance()
	refresh_upgrade_buttons()

func play_street_event_fx(message: String) -> void:
	if not is_instance_valid(float_layer):
		return
	if street_event_popup_tween and street_event_popup_tween.is_running():
		street_event_popup_tween.kill()
	if is_instance_valid(street_event_popup):
		street_event_popup.queue_free()
	var popup := PanelContainer.new()
	popup.mouse_filter = Control.MOUSE_FILTER_IGNORE
	popup.set_anchors_preset(Control.PRESET_TOP_WIDE)
	popup.anchor_left = 0.08
	popup.anchor_right = 0.92
	popup.offset_left = 0.0
	popup.offset_right = 0.0
	popup.offset_top = 48.0
	popup.offset_bottom = 108.0
	popup.add_theme_stylebox_override("panel", panel_style(Color("#312940"), Color("#f1c76c"), 12))
	var text_label := make_label(message, 20)
	text_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	popup.add_child(text_label)
	float_layer.add_child(popup)
	street_event_popup = popup
	popup.modulate.a = 0.0
	popup.scale = Vector2(0.85, 0.85)
	popup.pivot_offset = Vector2(0.0, 30.0)
	street_event_popup_tween = create_tween()
	street_event_popup_tween.tween_property(popup, "modulate:a", 1.0, 0.18)
	street_event_popup_tween.parallel().tween_property(popup, "scale", Vector2.ONE, 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	street_event_popup_tween.tween_interval(1.3)
	street_event_popup_tween.tween_property(popup, "modulate:a", 0.0, 0.35)
	street_event_popup_tween.tween_callback(popup.queue_free)
	for i in range(12):
		var spark := ColorRect.new()
		spark.color = Color("#ffe18a") if i % 2 == 0 else Color("#80e8ff")
		spark.size = Vector2(7.0, 7.0)
		spark.mouse_filter = Control.MOUSE_FILTER_IGNORE
		spark.position = float_layer.size * Vector2(0.5, 0.45)
		float_layer.add_child(spark)
		var angle: float = TAU * float(i) / 12.0
		var target: Vector2 = spark.position + Vector2(cos(angle), sin(angle)) * 100.0
		var fx := create_tween().set_parallel(true)
		fx.tween_property(spark, "position", target, 0.55).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		fx.tween_property(spark, "modulate:a", 0.0, 0.55)
		fx.chain().tween_callback(spark.queue_free)

func spawn_street_hit_sparks() -> void:
	if not is_instance_valid(float_layer):
		return
	var center: Vector2 = float_layer.size * Vector2(0.50, 0.58)
	for i in range(4):
		var spark: ColorRect = ColorRect.new()
		spark.color = Color("#ffdc84") if tap_combo < 30 else Color("#8ef4ff")
		spark.mouse_filter = Control.MOUSE_FILTER_IGNORE
		spark.size = Vector2(5.0, 5.0)
		spark.position = center
		float_layer.add_child(spark)
		var angle: float = TAU * float(i) / 4.0 + float(street_hit_phase % 2) * 0.35
		var distance: float = 23.0 + float(tap_combo % 4) * 5.0
		var target: Vector2 = center + Vector2(cos(angle), sin(angle)) * distance
		var burst: Tween = create_tween()
		burst.set_parallel(true)
		burst.tween_property(spark, "position", target, 0.32)
		burst.tween_property(spark, "modulate:a", 0.0, 0.32)
		burst.set_parallel(false)
		burst.tween_callback(spark.queue_free)

func spawn_floating_money(earned: float) -> void:
	if not is_instance_valid(float_layer):
		return
	var label := make_label("+%s" % number(earned), 34)
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
