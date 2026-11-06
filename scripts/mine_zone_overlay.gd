extends Control
# Pixel-art mineral seams layered over the existing cave illustration.
var zone: int = 0
var tick: float = 0.0

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE

func _process(delta: float) -> void:
	tick += delta
	queue_redraw()

func _draw() -> void:
	if zone <= 0:
		return
	var w := size.x
	var h := size.y
	if w <= 0.0 or h <= 0.0:
		return
	var colors := [Color("#4db6d5"), Color("#f5bc48"), Color("#ba7dff")]
	var glow := colors[mini(zone - 1, 2)]
	draw_rect(Rect2(Vector2.ZERO, size), Color(glow.r * 0.12, glow.g * 0.12, glow.b * 0.16, 0.24))
	for i in range(13):
		var px := w * (0.08 + fposmod(float(i) * 0.173, 0.83))
		var py := h * (0.13 + fposmod(float(i) * 0.291, 0.68))
		var scale := 1.0 + float(i % 3) * 0.5
		var shimmer := 0.64 + 0.22 * sin(tick * 1.4 + float(i))
		var shade := Color(glow.r, glow.g, glow.b, shimmer)
		draw_rect(Rect2(px, py, 8.0 * scale, 16.0 * scale), Color("#171724"))
		draw_rect(Rect2(px + 3.0 * scale, py - 6.0 * scale, 4.0 * scale, 20.0 * scale), shade)
		draw_rect(Rect2(px + 8.0 * scale, py + 2.0 * scale, 4.0 * scale, 8.0 * scale), shade.darkened(0.35))
