extends Control
# Street upgrades are decorative and never intercept taps.
var tier: int = 0
var time_passed: float = 0.0
var redraw_clock: float = 0.0

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE

func _process(delta: float) -> void:
	if tier <= 0:
		return
	time_passed += delta
	redraw_clock += delta
	if redraw_clock >= 0.1:
		redraw_clock = 0.0
		queue_redraw()

func _draw() -> void:
	if tier <= 0 or size.x <= 0.0 or size.y <= 0.0:
		return
	var w: float = size.x
	var h: float = size.y
	# Tier 1: an improvised stall and lit sign.
	draw_rect(Rect2(w * 0.02, h * 0.64, w * 0.26, h * 0.07), Color("#573c39"))
	draw_rect(Rect2(w * 0.04, h * 0.48, w * 0.22, h * 0.16), Color("#80614d"))
	draw_rect(Rect2(w * 0.04, h * 0.46, w * 0.22, h * 0.045), Color("#d5a466"))
	draw_rect(Rect2(w * 0.09, h * 0.51, w * 0.12, h * 0.055), Color("#f6db9d"))
	if tier >= 2:
		# A brighter shopfront and a pixel neon sign.
		draw_rect(Rect2(w * 0.73, h * 0.30, w * 0.25, h * 0.43), Color("#343d54"))
		draw_rect(Rect2(w * 0.76, h * 0.36, w * 0.19, h * 0.11), Color("#1c263e"))
		var pulse: float = 0.75 + sin(time_passed * 2.0) * 0.18
		draw_rect(Rect2(w * 0.77, h * 0.38, w * 0.17, h * 0.055), Color(0.37, 0.92, 0.88, pulse))
		draw_rect(Rect2(w * 0.79, h * 0.51, w * 0.13, h * 0.21), Color("#a0c3c7"))
	if tier >= 3:
		# The city prospers: windows and gold-lit pavement.
		for i in range(5):
			var x: float = w * (0.08 + float(i) * 0.18)
			var y: float = h * (0.10 + float(i % 2) * 0.055)
			draw_rect(Rect2(x, y, w * 0.09, h * 0.14), Color("#283347"))
			draw_rect(Rect2(x + w * 0.018, y + h * 0.025, w * 0.055, h * 0.07), Color("#f2c97a"))
		draw_rect(Rect2(w * 0.05, h * 0.84, w * 0.9, h * 0.018), Color("#b68a55"))
