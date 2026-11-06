extends Control
# Depth-responsive pixel cave: crystalline veins, ruins, dust and mining shockwaves.
var zone: int = 0
var tick: float = 0.0
var redraw_clock: float = 0.0
var impact_age: float = 1.0
var impact_position: Vector2 = Vector2(0.5, 0.55)
const ORE_COLORS = ["#a88767", "#50bfe2", "#eac05d", "#bd88ff", "#63dfb8", "#ff819d"]

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE

func _process(delta: float) -> void:
	tick += delta
	redraw_clock += delta
	impact_age = minf(1.0, impact_age + delta * 2.5)
	if redraw_clock >= 0.05:
		redraw_clock = 0.0
		queue_redraw()

func strike() -> void:
	impact_age = 0.0
	impact_position = Vector2(0.45 + randf_range(-0.14, 0.14), 0.53 + randf_range(-0.10, 0.10))
	queue_redraw()

func _draw() -> void:
	if size.x < 80.0 or size.y < 80.0:
		return
	var w: float = size.x
	var h: float = size.y
	var unit: float = maxf(2.0, floorf(minf(w / 180.0, h / 85.0)))
	var ore_color: Color = Color(ORE_COLORS[clampi(zone, 0, ORE_COLORS.size() - 1)])
	# Geological strata, pixel joints and distant shadowed rock.
	for i in range(6):
		var y: float = floorf(h * (0.10 + float(i) * 0.14))
		var shade: Color = Color("#1c2532") if i % 2 == 0 else Color("#354050")
		draw_rect(Rect2(0.0, y, w * 0.18, unit), shade)
		draw_rect(Rect2(w * 0.82, y + unit * 2.0, w * 0.18, unit), shade)
		for j in range(4):
			var x: float = w * (0.02 + float(j) * 0.044) if i % 2 == 0 else w * (0.81 + float(j) * 0.044)
			draw_rect(Rect2(floorf(x), y + unit * 2.0, unit, unit * 3.0), Color("#151c29"))
	# Mineral clusters around the edges keep the middle legible.
	for i in range(20):
		var left_side: bool = i % 2 == 0
		var x: float = w * (0.025 + float((i * 7) % 9) * 0.015) if left_side else w * (0.82 + float((i * 3) % 10) * 0.014)
		var y: float = h * (0.12 + float((i * 13) % 19) * 0.037)
		var scale: float = 1.0 + float(i % 3) * 0.45
		var shimmer: float = 0.70 + 0.22 * sin(tick * 1.6 + float(i) * 1.3)
		var dark: Color = ore_color.darkened(0.55)
		pixel(x, y, unit * 4.0 * scale, unit * 7.0 * scale, dark)
		pixel(x + unit * scale, y - unit * 2.0 * scale, unit * 2.0 * scale, unit * 7.0 * scale, Color(ore_color.r, ore_color.g, ore_color.b, shimmer))
		pixel(x + unit * 3.0 * scale, y + unit * 2.0 * scale, unit * 2.0 * scale, unit * 3.0 * scale, ore_color.darkened(0.23))
		if i % 4 == 0:
			pixel(x + unit * scale, y, unit, unit, Color("#fff4df"))
	# Suspended dust and glowing embers.
	for i in range(18):
		var x: float = w * (0.12 + fposmod(float(i) * 0.287, 0.76))
		var y: float = h * fposmod(float(i) * 0.173 - tick * (0.008 + float(i % 3) * 0.004), 1.0)
		var alpha: float = 0.13 + 0.15 * (0.5 + 0.5 * sin(tick * 2.0 + float(i)))
		pixel(x, y, unit, unit, Color(ore_color.r, ore_color.g, ore_color.b, alpha))
	if zone >= 3:
		# Crystal arches frame the deeper zones.
		for i in range(2):
			var x: float = w * (0.16 if i == 0 else 0.78)
			pixel(x, h * 0.20, unit * 4.0, h * 0.50, Color("#172234"))
			pixel(x + unit, h * 0.19, unit * 2.0, h * 0.42, ore_color.darkened(0.55))
			pixel(x - unit * 2.0, h * 0.17, unit * 8.0, unit * 2.0, ore_color.darkened(0.35))
	if zone >= 4:
		# Buried ruins and lit windows in the lost underground city.
		for i in range(6):
			var x: float = w * (0.12 + float(i) * 0.14)
			var top: float = h * (0.43 - float(i % 3) * 0.055)
			pixel(x, top, unit * 9.0, h * 0.29, Color("#17212d"))
			pixel(x + unit * 3.0, top + unit * 5.0, unit * 3.0, unit * 3.0, ore_color.darkened(0.25))
	if zone >= 5:
		for i in range(4):
			var x: float = w * (0.24 + float(i) * 0.17)
			var beam_alpha: float = 0.14 + 0.05 * sin(tick * 1.2 + float(i))
			draw_rect(Rect2(x, h * 0.08, unit * 2.0, h * 0.56), Color(ore_color.r, ore_color.g, ore_color.b, beam_alpha))
	# Brief mining impact shockwave and pixel shards.
	if impact_age < 1.0:
		var center: Vector2 = Vector2(w * impact_position.x, h * impact_position.y)
		var progress: float = impact_age
		var radius: float = unit * (5.0 + progress * 24.0)
		var alpha: float = (1.0 - progress) * 0.75
		draw_arc(center, radius, 0.0, TAU, 28, Color(ore_color.r, ore_color.g, ore_color.b, alpha), unit * 2.0)
		for i in range(12):
			var angle: float = TAU * float(i) / 12.0
			var p: Vector2 = center + Vector2(cos(angle), sin(angle)) * (unit * 4.0 + progress * unit * 22.0)
			pixel(p.x, p.y, unit * 2.0, unit * 2.0, Color(ore_color.r, ore_color.g, ore_color.b, alpha))

func pixel(x: float, y: float, width: float, height: float, tint: Color) -> void:
	draw_rect(Rect2(floorf(x), floorf(y), maxf(1.0, floorf(width)), maxf(1.0, floorf(height))), tint)
