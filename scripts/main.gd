extends Control

const SAVE_PATH = "user://bottomlife_v1.json"
var money: float = 0.0
var tap_level: int = 1
var auto_level: int = 0
var current_tab: int = 0
var header: Label
var income_label: Label
var content: VBoxContainer
var feedback: Label
var save_clock: float = 0.0
var hero_sprite: Control
var tap_upgrade_button: Button
var auto_upgrade_button: Button
var idle_time: float = 0.0
var pop_tween: Tween
var street_stage: Control
var float_layer: Control
var tab_buttons: Array[Button] = []
var tap_cost_label: Label
var auto_cost_label: Label

func _ready() -> void:
	load_game()
	build_ui()
	refresh()

func _process(delta: float) -> void:
	money += float(auto_level) * 5.0 * delta
	save_clock += delta
	idle_time += delta
	if save_clock >= 10.0:
		save_clock = 0.0
		save_game()
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
		tap_level = maxi(1, int(data.get("tap_level", 1)))
		auto_level = maxi(0, int(data.get("auto_level", 0)))

func save_game() -> void:
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file != null:
		file.store_string(JSON.stringify({"money": money, "tap_level": tap_level, "auto_level": auto_level}))

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
	var normal := panel_style(Color("#bc8849") if gold else Color("#24232d"), Color("#f0c47a") if gold else Color("#75614f"))
	var hover := panel_style(Color("#d9a55b") if gold else Color("#37323c"), Color("#ffe1a0"))
	var pressed := panel_style(Color("#94652f") if gold else Color("#171720"), Color("#f0c47a"))
	button.add_theme_stylebox_override("normal", normal)
	button.add_theme_stylebox_override("hover", hover)
	button.add_theme_stylebox_override("pressed", pressed)
	button.add_theme_stylebox_override("disabled", panel_style(Color("#25242b"), Color("#4c4441")))
	button.add_theme_color_override("font_color", Color("#16151b") if gold else Color("#f8e6c9"))
	button.add_theme_color_override("font_disabled_color", Color("#a29b95"))
	button.add_theme_color_override("font_hover_color", Color("#16151b") if gold else Color("#ffffff"))

func refresh_upgrade_buttons() -> void:
	if is_instance_valid(tap_upgrade_button):
		tap_upgrade_button.disabled = money < 100.0 * pow(1.35, tap_level - 1)
	if is_instance_valid(auto_upgrade_button):
		auto_upgrade_button.disabled = money < 250.0 * pow(1.42, auto_level)

func make_button(value: String) -> Button:
	var button := Button.new()
	button.text = value
	button.custom_minimum_size = Vector2(0, 85)
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
	top.custom_minimum_size.y = 120
	top.add_theme_stylebox_override("panel", panel_style(Color("#1e1b26"), Color("#ad8652"), 8))
	outer.add_child(top)
	var top_box := VBoxContainer.new()
	top.add_child(top_box)
	header = make_label("", 34)
	top_box.add_child(header)
	income_label = make_label("", 21)
	top_box.add_child(income_label)
	content = VBoxContainer.new()
	content.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content.add_theme_constant_override("separation", 8)
	outer.add_child(content)
	var bottom := HBoxContainer.new()
	bottom.custom_minimum_size.y = 104
	bottom.add_theme_constant_override("separation", 4)
	outer.add_child(bottom)
	var tabs := ["거리", "사업", "광산", "성장", "메뉴"]
	for i in range(tabs.size()):
		var b := make_button(tabs[i])
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		b.add_theme_font_size_override("font_size", 20)
		decorate_button(b, i == current_tab)
		b.pressed.connect(change_tab.bind(i))
		bottom.add_child(b)
		tab_buttons.append(b)

func change_tab(index: int) -> void:
	current_tab = index
	for i in range(tab_buttons.size()):
		decorate_button(tab_buttons[i], i == index)
	refresh()

func refresh_header() -> void:
	if header == null:
		return
	header.text = "밑바닥 인생   |   %s원" % number(money)
	income_label.text = "터치 +%s원     자동 +%s원/초" % [number(tap_level * 10.0), number(auto_level * 5.0)]

func number(n: float) -> String:
	if n >= 1000000000000.0:
		return "%.2f조" % (n / 1000000000000.0)
	if n >= 100000000.0:
		return "%.2f억" % (n / 100000000.0)
	if n >= 10000.0:
		return "%.1f만" % (n / 10000.0)
	return str(int(n))

func refresh() -> void:
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
			build_placeholder("사업", "사업장 운영은 다음 업데이트에서 열립니다.")
		2:
			build_placeholder("광산", "광물 채굴은 다음 업데이트에서 열립니다.")
		3:
			build_placeholder("성장", "캐릭터 성장 콘텐츠 준비 중")
		4:
			build_placeholder("메뉴", "게임은 10초마다 자동 저장됩니다.")

func build_placeholder(title: String, description: String) -> void:
	content.add_child(make_label(title, 45))
	content.add_child(make_label(description, 25))

func build_street() -> void:
	content.add_child(make_label("제1장 · 비 내린 골목", 29))
	var scene_area := Control.new()
	scene_area.custom_minimum_size.y = 380
	scene_area.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scene_area.clip_contents = true
	content.add_child(scene_area)
	street_stage = scene_area
	var backdrop := TextureRect.new()
	backdrop.texture = load("res://assets/street.svg")
	backdrop.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	backdrop.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	backdrop.mouse_filter = Control.MOUSE_FILTER_IGNORE
	scene_area.add_child(backdrop)
	var rain := Control.new()
	rain.set_script(load("res://scripts/rain_overlay.gd"))
	rain.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	rain.mouse_filter = Control.MOUSE_FILTER_IGNORE
	scene_area.add_child(rain)
	var hero := Control.new()
	hero.set_script(load("res://scripts/pixel_hero.gd"))
	hero.anchor_left = 0.27
	hero.anchor_right = 0.73
	hero.anchor_top = 0.29
	hero.anchor_bottom = 0.91
	hero.mouse_filter = Control.MOUSE_FILTER_IGNORE
	scene_area.add_child(hero)
	hero_sprite = hero
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
	content.add_child(make_label("능력 강화", 27))
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
	money += tap_level * 10.0
	feedback.text = "+%s원!" % number(tap_level * 10.0)
	spawn_floating_money()
	if is_instance_valid(hero_sprite):
		hero_sprite.call("react")
	refresh_header()
	refresh_upgrade_buttons()

func spawn_floating_money() -> void:
	if not is_instance_valid(float_layer):
		return
	var label := make_label("+%s" % number(tap_level * 10.0), 34)
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
