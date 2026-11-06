extends Control
# Crisp, animated pixel-art street props. All shapes snap to whole pixels.
var elapsed: float = 0.0
var tier: int = 0

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE

func _process(delta: float) -> void:
	elapsed += delta
	if elapsed > 10000.0:
		elapsed = 0.0
	queue_redraw()

func _draw() -> void:
	if size.x < 100.0 or size.y < 100.0:
		return
	var w: float = size.x
	var h: float = size.y
	var pixel: float = maxf(2.0, floorf(minf(w / 180.0, h / 110.0)))
	# Recessed brickwork on the side walls.
	for side in range(2):
		var left: float = 0.0 if side == 0 else w * 0.84
		for row in range(7):
			var yy: float = floorf(h * (0.08 + row * 0.082))
			for col in range(3):
				var xx: float = left + (col * 2.8 + (row % 2) * 1.4) * pixel
				draw_rect(Rect2(floorf(xx), yy, pixel * 2.0, pixel), Color("#687086", 0.18))
	# Street-level utility boxes and cables.
	px(w * 0.04, h * 0.73, pixel * 9.0, pixel * 11.0, Color("#1d2532"))
	px(w * 0.04, h * 0.73, pixel * 9.0, pixel * 2.0, Color("#566173"))
	px(w * 0.065, h * 0.80, pixel * 3.0, pixel, Color("#e0ae63"))
	draw_line(Vector2(w * 0.05, h * 0.16), Vector2(w * 0.95, h * 0.10), Color("#171a28"), pixel)
	# Hanging warm bulbs; tiny animated halos.
	for i in range(5):
		var x: float = w * (0.18 + float(i) * 0.16)
		var y: float = h * (0.15 - float(i) * 0.010)
		var pulse: float = 0.75 + 0.25 * sin(elapsed * 1.7 + float(i))
		draw_circle(Vector2(x, y), pixel * 4.0, Color(1.0, 0.65, 0.29, 0.045 * pulse))
		px(x - pixel, y, pixel * 2.0, pixel * 2.0, Color(1.0, 0.77, 0.42, pulse))
	# Foreground pavement blocks and puddles.
	for i in range(10):
		var x: float = w * (0.04 + float(i) * 0.095)
		var y: float = h * (0.89 + float(i % 3) * 0.025)
		px(x, y, pixel * 9.0, pixel, Color("#8b8b9b", 0.14))
		if i % 2 == 0:
			px(x + pixel * 2.0, y + pixel * 2.0, pixel * 5.0, pixel, Color("#b5a1a0", 0.11))
	if tier >= 1:
		# Lantern-lit market awning and stacked crates.
		px(w * 0.02, h * 0.43, pixel * 22.0, pixel * 3.0, Color("#b9574b"))
		for i in range(5):
			px(w * 0.02 + pixel * 4.0 * i, h * 0.46, pixel * 2.0, pixel * 2.0, Color("#e8bc85"))
		for i in range(2):
			px(w * 0.08 + i * pixel * 8.0, h * 0.73, pixel * 7.0, pixel * 6.0, Color("#92694b"))
			px(w * 0.08 + i * pixel * 8.0, h * 0.73, pixel * 7.0, pixel, Color("#c49361"))
	if tier >= 2:
		# Pixel neon sign, shimmering without affecting gameplay.
		var glow: float = 0.70 + sin(elapsed * 2.5) * 0.20
		px(w * 0.78, h * 0.28, pixel * 17.0, pixel * 8.0, Color("#142d40"))
		px(w * 0.79, h * 0.29, pixel * 15.0, pixel, Color("#45d5d1", glow))
		px(w * 0.79, h * 0.35, pixel * 15.0, pixel, Color("#45d5d1", glow))
		for i in range(3):
			px(w * 0.81 + pixel * i * 4.0, h * 0.32, pixel * 2.0, pixel * 2.0, Color("#d2ffff", glow))
	if tier >= 3:
		# Golden trim and high-end street lights for the final city tier.
		for i in range(4):
			var x: float = w * (0.13 + float(i) * 0.23)
			px(x, h * 0.65, pixel * 2.0, pixel * 18.0, Color("#6b573f"))
			px(x - pixel * 2.0, h * 0.64, pixel * 6.0, pixel * 3.0, Color("#f0c876"))
			draw_circle(Vector2(x + pixel, h * 0.68), pixel * 5.0, Color("#f0c876", 0.09))

func px(x: float, y: float, width: float, height: float, color: Color) -> void:
	draw_rect(Rect2(floorf(x), floorf(y), maxf(1.0, floorf(width)), maxf(1.0, floorf(height))), color)
