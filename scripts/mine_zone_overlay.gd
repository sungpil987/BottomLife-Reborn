extends Control
# Animated pixel-art mineral layers and depth-specific ruins.
var zone: int = 0
var tick: float = 0.0
var redraw_clock: float = 0.0

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE

func _process(delta: float) -> void:
	tick += delta
	redraw_clock += delta
	if redraw_clock >= 0.05:
		redraw_clock = 0.0
		queue_redraw()

func _draw() -> void:
	if zone <= 0 or size.x <= 0.0 or size.y <= 0.0:
		return
	var w: float = size.x
	var h: float = size.y
	var colors: Array[Color] = [Color("#4db6d5"), Color("#f5bc48"), Color("#ba7dff"), Color("#58e0c2"), Color("#ff768d")]
	var glow: Color = colors[clampi(zone - 1, 0, colors.size() - 1)]
	draw_rect(Rect2(Vector2.ZERO, size), Color(glow.r * 0.12, glow.g * 0.12, glow.b * 0.16, 0.24))
	# Parallax silhouettes: the lost city and primordial deep have unique skylines.
	if zone >= 4:
		for i in range(9):
			var tower_x: float = w * (0.04 + float(i) * 0.115)
			var tower_h: float = h * (0.17 + float((i * 7) % 5) * 0.052)
			draw_rect(Rect2(tower_x, h * 0.69 - tower_h, w * 0.065, tower_h), Color("#111b27" if zone == 4 else "#231321"))
			draw_rect(Rect2(tower_x + w * 0.02, h * 0.72 - tower_h, w * 0.015, h * 0.032), glow.darkened(0.28))
		draw_rect(Rect2(0.0, h * 0.69, w, h * 0.04), Color("#111b27" if zone == 4 else "#231321"))
	if zone >= 5:
		for i in range(5):
			var x: float = w * (0.12 + float(i) * 0.19)
			var pulse: float = 0.70 + 0.20 * sin(tick * 1.1 + float(i))
			draw_rect(Rect2(x, h * 0.12, w * 0.023, h * 0.57), Color(glow.r, glow.g, glow.b, pulse * 0.65))
			draw_rect(Rect2(x - w * 0.012, h * 0.12, w * 0.047, h * 0.025), Color("#f7cfad"))
	for i in range(17 if zone >= 4 else 13):
		var px: float = w * (0.08 + fposmod(float(i) * 0.173, 0.83))
		var py: float = h * (0.13 + fposmod(float(i) * 0.291, 0.68))
		var scale: float = 1.0 + float(i % 3) * 0.5
		var shimmer: float = 0.64 + 0.22 * sin(tick * 1.4 + float(i))
		var shade: Color = Color(glow.r, glow.g, glow.b, shimmer)
		draw_rect(Rect2(px, py, 8.0 * scale, 16.0 * scale), Color("#171724"))
		draw_rect(Rect2(px + 3.0 * scale, py - 6.0 * scale, 4.0 * scale, 20.0 * scale), shade)
		draw_rect(Rect2(px + 8.0 * scale, py + 2.0 * scale, 4.0 * scale, 8.0 * scale), shade.darkened(0.35))
