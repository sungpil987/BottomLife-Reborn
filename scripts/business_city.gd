extends Control
# Five business silhouettes, pixel-lit windows and moving storefront life.
var levels: Array[int] = [0, 0, 0, 0, 0]
var clock: float = 0.0
var frame_clock: float = 0.0
const PALETTES = ["#bf7851", "#cf9a62", "#6798aa", "#a37b9e", "#7e96b6"]

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE

func _process(delta: float) -> void:
	clock += delta
	frame_clock += delta
	if frame_clock > 0.09:
		frame_clock = 0.0
		queue_redraw()

func _draw() -> void:
	if size.x < 160.0 or size.y < 80.0:
		return
	var w: float = size.x
	var h: float = size.y
	var px: float = maxf(2.0, floorf(minf(w / 210.0, h / 72.0)))
	# Evening skyline and low street haze.
	draw_rect(Rect2(0, h * 0.72, w, h * 0.28), Color("#1b2635", 0.65))
	for i in range(18):
		var x: float = w * float(i) / 18.0
		var y: float = h * (0.77 + float(i % 3) * 0.018)
		draw_rect(Rect2(x, y, w * 0.042, px), Color("#c8a47c", 0.16))
	# Every property has a distinct shape, roof and window layout.
	for i in range(5):
		var level: int = levels[i] if i < levels.size() else 0
		var x: float = w * (0.025 + float(i) * 0.198)
		var width: float = w * 0.177
		var tall: float = h * (0.27 + float(i) * 0.085 + (0.08 if level >= 25 else 0.0))
		var bottom: float = h * 0.76
		var top: float = bottom - tall
		var base: Color = Color(PALETTES[i])
		var active: bool = level > 0
		var wall: Color = base if active else Color("#394252")
		var edge: Color = wall.darkened(0.38)
		draw_rect(Rect2(x - px, top - px * 2.0, width + px * 2.0, tall + px * 3.0), edge)
		draw_rect(Rect2(x, top, width, tall), wall)
		# Distinct roof treatments: stall canopy, restaurant awning, convenience store sign, office cornice, market rooftop.
		if i == 0:
			draw_rect(Rect2(x - px * 2.0, top, width + px * 4.0, px * 4.0), Color("#bf5b53") if active else Color("#56505a"))
			for stripe in range(5):
				draw_rect(Rect2(x + width * float(stripe) / 5.0, top + px * 3.0, width / 10.0, px * 3.0), Color("#f4d7aa") if active else Color("#6a6770"))
		elif i == 1:
			draw_rect(Rect2(x - px, top + tall * 0.57, width + px * 2.0, px * 4.0), Color("#d9a45f") if active else Color("#646674"))
		elif i == 2:
			draw_rect(Rect2(x, top + px * 2.0, width, px * 5.0), Color("#40b4c5") if active else Color("#4d6272"))
		elif i == 3:
			draw_rect(Rect2(x - px * 2.0, top - px * 2.0, width + px * 4.0, px * 3.0), Color("#dbb885") if active else Color("#626473"))
		else:
			draw_rect(Rect2(x + width * 0.12, top - px * 5.0, width * 0.76, px * 5.0), Color("#7b9eaf") if active else Color("#495467"))
		# Pixel windows: number of floors scales with building identity.
		var floors: int = 1 if i < 2 else (2 if i == 2 else 3)
		for floor_index in range(floors):
			for column in range(2):
				var wx: float = x + width * (0.16 + float(column) * 0.46)
				var wy: float = top + tall * (0.21 + float(floor_index) * (0.53 / float(floors)))
				var lit: bool = active and (level >= 50 or (floor_index + column + i) % 3 != 0)
				var pulse: float = 0.88 + sin(clock * 1.2 + float(i * 7 + floor_index)) * 0.08
				draw_rect(Rect2(wx - px, wy - px, width * 0.23 + px * 2.0, px * 5.0), edge)
				draw_rect(Rect2(wx, wy, width * 0.23, px * 3.0), Color(1.0, 0.79, 0.47, pulse) if lit else Color("#1b2b3e"))
		# Doors, shop counters, and high-level neon accents.
		draw_rect(Rect2(x + width * 0.38, bottom - px * 6.0, width * 0.24, px * 6.0), Color("#1b2636"))
		if level >= 25:
			draw_rect(Rect2(x + px, top + px * 8.0, width - px * 2.0, px * 2.0), Color("#f7c976"))
		if level >= 50:
			var glow: float = 0.75 + sin(clock * 2.0 + float(i)) * 0.2
			draw_rect(Rect2(x + px, bottom - px * 3.0, width - px * 2.0, px), Color(0.45, 0.97, 0.92, glow))
		if level >= 100:
			draw_rect(Rect2(x + width * 0.45, top - px * 7.0, px * 3.0, px * 5.0), Color("#f9db8c"))
			draw_rect(Rect2(x + width * 0.38, top - px * 9.0, px * 6.0, px * 2.0), Color("#fff1ba"))
	# A tiny delivery scooter travels past active businesses.
	if levels[0] > 0:
		var travel: float = fposmod(clock * w * 0.075, w + 30.0) - 30.0
		var sy: float = h * 0.87
		draw_rect(Rect2(travel, sy - px * 3.0, px * 10.0, px * 3.0), Color("#cf6959"))
		draw_rect(Rect2(travel + px * 2.0, sy - px * 5.0, px * 4.0, px * 2.0), Color("#f3d8b6"))
		draw_circle(Vector2(travel + px * 2.0, sy), px * 1.7, Color("#20242d"))
		draw_circle(Vector2(travel + px * 9.0, sy), px * 1.7, Color("#20242d"))
