extends Control
# 24x32 pixel-art costume overlays with animated highlights and hit reactions.
var tier: int = 0
var elapsed: float = 0.0
var hit_time: float = 0.0

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE

func _process(delta: float) -> void:
	elapsed += delta
	hit_time = maxf(0.0, hit_time - delta)
	if tier > 0:
		queue_redraw()

func celebrate() -> void:
	hit_time = 0.28
	queue_redraw()

func _draw() -> void:
	if tier <= 0:
		return
	var unit: float = minf(size.x / 24.0, size.y / 32.0)
	if unit <= 0.0:
		return
	var origin: Vector2 = (size - Vector2(24.0, 32.0) * unit) * 0.5
	var coat: Color = Color("#39688e") if tier == 1 else (Color("#55456e") if tier == 2 else Color("#242e45"))
	var shadow: Color = coat.darkened(0.34)
	var light: Color = coat.lightened(0.27)
	var trim: Color = Color("#dfb987") if tier < 3 else Color("#f4d379")
	# Pixel silhouette: shoulders, sleeves, jacket, hem and shoes.
	paint(origin, unit, 7, 13, 10, 10, shadow)
	paint(origin, unit, 8, 13, 8, 9, coat)
	paint(origin, unit, 8, 14, 2, 7, light)
	paint(origin, unit, 6, 14, 2, 7, shadow)
	paint(origin, unit, 16, 14, 2, 7, shadow)
	paint(origin, unit, 7, 22, 10, 2, shadow)
	paint(origin, unit, 8, 23, 3, 5, Color("#30313d"))
	paint(origin, unit, 13, 23, 3, 5, Color("#30313d"))
	paint(origin, unit, 7, 28, 5, 2, Color("#24232c"))
	paint(origin, unit, 13, 28, 5, 2, Color("#24232c"))
	# Shirt collar and jacket seam.
	paint(origin, unit, 10, 13, 4, 2, Color("#efe4cb"))
	paint(origin, unit, 11, 15, 2, 6, trim)
	paint(origin, unit, 9, 18, 1, 1, Color("#f5e4c4"))
	paint(origin, unit, 9, 21, 1, 1, Color("#f5e4c4"))
	if tier == 1:
		# Blue worker jacket, rolled cuffs and utility pocket.
		paint(origin, unit, 6, 19, 2, 2, trim)
		paint(origin, unit, 16, 19, 2, 2, trim)
		paint(origin, unit, 13, 18, 3, 3, shadow)
		paint(origin, unit, 13, 18, 3, 1, light)
	elif tier == 2:
		# Tailored coat, dark fedora and gold chain.
		paint(origin, unit, 6, 7, 12, 2, Color("#262536"))
		paint(origin, unit, 8, 4, 8, 4, Color("#322b43"))
		paint(origin, unit, 8, 7, 8, 1, trim)
		paint(origin, unit, 9, 14, 2, 4, light)
		paint(origin, unit, 13, 14, 2, 4, light)
		paint(origin, unit, 14, 19, 2, 1, trim)
	else:
		# Legendary suit: long coat, gold epaulettes, crown-like hat.
		paint(origin, unit, 6, 13, 2, 3, trim)
		paint(origin, unit, 16, 13, 2, 3, trim)
		paint(origin, unit, 6, 22, 3, 6, shadow)
		paint(origin, unit, 15, 22, 3, 6, shadow)
		paint(origin, unit, 8, 5, 8, 3, Color("#232535"))
		paint(origin, unit, 7, 7, 10, 2, Color("#232535"))
		paint(origin, unit, 9, 5, 1, 2, trim)
		paint(origin, unit, 12, 4, 2, 3, trim)
		paint(origin, unit, 15, 5, 1, 2, trim)
		paint(origin, unit, 11, 16, 2, 3, Color("#fff1b0"))
	# Occasional pixel glints on premium outfits.
	if tier >= 2 and sin(elapsed * 3.0) > 0.86:
		paint(origin, unit, 16, 12, 1, 2, Color("#fff5c5"))
		paint(origin, unit, 15, 13, 3, 1, Color("#fff5c5"))
	if hit_time > 0.0:
		paint(origin, unit, 4, 12, 2, 1, Color("#fff2b6"))
		paint(origin, unit, 19, 10, 1, 3, Color("#fff2b6"))

func paint(origin: Vector2, unit: float, x: int, y: int, w: int, h: int, color: Color) -> void:
	draw_rect(Rect2(origin + Vector2(float(x), float(y)) * unit, Vector2(float(w), float(h)) * unit), color)
