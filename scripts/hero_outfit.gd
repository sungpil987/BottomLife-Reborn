extends Control
# Procedural pixel clothing drawn on top of the existing hero sprite.
var tier: int = 0

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE

func _draw() -> void:
	if tier <= 0:
		return
	var unit: float = minf(size.x / 24.0, size.y / 32.0)
	if unit <= 0.0:
		return
	var origin: Vector2 = (size - Vector2(24.0, 32.0) * unit) * 0.5
	var coat: Color = Color("#3d638c") if tier == 1 else (Color("#4a3b62") if tier == 2 else Color("#292b38"))
	var trim: Color = Color("#d7c5a2") if tier < 3 else Color("#e9c66b")
	paint(origin, unit, 7, 13, 10, 9, coat)
	paint(origin, unit, 10, 13, 4, 9, coat.lightened(0.18))
	paint(origin, unit, 11, 14, 2, 6, trim)
	paint(origin, unit, 5, 14, 2, 7, coat.darkened(0.15))
	paint(origin, unit, 17, 14, 2, 7, coat.darkened(0.15))
	if tier >= 2:
		paint(origin, unit, 6, 7, 12, 2, Color("#252331"))
		paint(origin, unit, 8, 4, 8, 3, Color("#252331"))
		paint(origin, unit, 8, 7, 8, 1, trim)
	if tier >= 3:
		paint(origin, unit, 7, 22, 4, 6, Color("#1d1d29"))
		paint(origin, unit, 13, 22, 4, 6, Color("#1d1d29"))
		paint(origin, unit, 7, 28, 4, 2, trim.darkened(0.35))
		paint(origin, unit, 13, 28, 4, 2, trim.darkened(0.35))

func paint(origin: Vector2, unit: float, x: int, y: int, w: int, h: int, color: Color) -> void:
	draw_rect(Rect2(origin + Vector2(float(x), float(y)) * unit, Vector2(float(w), float(h)) * unit), color)
