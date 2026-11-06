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

func _ready() -> void:
	load_game()
	build_ui()
	refresh()

func _process(delta: float) -> void:
	money += float(auto_level) * 5.0 * delta
	save_clock += delta
	if save_clock >= 10.0:
		save_clock = 0.0
		save_game()
	refresh_header()

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

func make_button(value: String) -> Button:
	var button := Button.new()
	button.text = value
	button.custom_minimum_size = Vector2(0, 85)
	button.add_theme_font_size_override("font_size", 23)
	return button

func build_ui() -> void:
	var bg := ColorRect.new()
	bg.color = Color("#10131d")
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(bg)
	var outer := VBoxContainer.new()
	outer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	outer.add_theme_constant_override("separation", 12)
	add_child(outer)
	var top := PanelContainer.new()
	top.custom_minimum_size.y = 128
	outer.add_child(top)
	var top_box := VBoxContainer.new()
	top.add_child(top_box)
	header = make_label("", 34)
	top_box.add_child(header)
	income_label = make_label("", 21)
	top_box.add_child(income_label)
	content = VBoxContainer.new()
	content.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content.add_theme_constant_override("separation", 16)
	outer.add_child(content)
	var bottom := HBoxContainer.new()
	bottom.custom_minimum_size.y = 105
	bottom.add_theme_constant_override("separation", 4)
	outer.add_child(bottom)
	var tabs := ["거리", "사업", "광산", "성장", "메뉴"]
	for i in range(tabs.size()):
		var b := make_button(tabs[i])
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		b.add_theme_font_size_override("font_size", 20)
		b.pressed.connect(change_tab.bind(i))
		bottom.add_child(b)

func change_tab(index: int) -> void:
	current_tab = index
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
	content.add_child(make_label("Lv.1  거리의 거지", 34))
	var scene_area := PanelContainer.new()
	scene_area.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content.add_child(scene_area)
	var stage := VBoxContainer.new()
	stage.alignment = BoxContainer.ALIGNMENT_CENTER
	scene_area.add_child(stage)
	stage.add_child(make_label("어두운 골목", 32))
	stage.add_child(make_label("   ▄██▄\n  ( •_• )\n  /|  |\\\n   /  \\", 43))
	var tap := make_button("터치해서 돈 벌기")
	tap.custom_minimum_size.y = 145
	stage.add_child(tap)
	feedback = make_label("터치하면 돈을 얻습니다", 25)
	stage.add_child(feedback)
	tap.pressed.connect(tap_money)
	content.add_child(make_label("능력 강화", 29))
	var tap_cost := 100.0 * pow(1.35, tap_level - 1)
	var tap_upgrade := make_button("터치 수익 Lv.%d   |   %s원" % [tap_level, number(tap_cost)])
	tap_upgrade.disabled = money < tap_cost
	tap_upgrade.pressed.connect(buy_tap)
	content.add_child(tap_upgrade)
	var auto_cost := 250.0 * pow(1.42, auto_level)
	var auto_upgrade := make_button("자동 수익 Lv.%d   |   %s원" % [auto_level, number(auto_cost)])
	auto_upgrade.disabled = money < auto_cost
	auto_upgrade.pressed.connect(buy_auto)
	content.add_child(auto_upgrade)

func tap_money() -> void:
	money += tap_level * 10.0
	feedback.text = "+%s원!" % number(tap_level * 10.0)
	refresh_header()
	# Preserve tap target while allowing upgrade buttons to update.
	for child in content.get_children():
		if child is Button:
			child.disabled = false

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
