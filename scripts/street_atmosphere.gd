extends Control
# Atmospheric street details drawn independently from the character texture.
var clock: float = 0.0
var motes: Array[Vector3] = []
var rng := RandomNumberGenerator.new()

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	rng.seed = 73129
	for i in range(30):
		motes.append(Vector3(rng.randf(), rng.randf(), rng.randf_range(0.3, 1.0)))

func _process(delta: float) -> void:
	clock += delta
	for i in range(motes.size()):
		var p := motes[i]
		p.y -= delta * 0.025 * p.z
		p.x += sin(clock * 0.6 + float(i)) * delta * 0.004
		if p.y < 0.0:
			p.y = 1.0
		motes[i] = p
	queue_redraw()

func _draw() -> void:
	var w := size.x
	var h := size.y
	if w < 1.0 or h < 1.0:
		return
	# Ground contact shadow. Keep behind the hero.
	draw_ellipse_shadow(Vector2(w * 0.5, h * 0.86), Vector2(w * 0.17, h * 0.025), Color(0.03, 0.03, 0.07, 0.36))
	# Subtle illuminated windows and their reflections.
	for i in range(5):
		var x := w * (0.09 if i % 2 == 0 else 0.87)
		var y := h * (0.18 + float(i) * 0.11)
		var flicker := 0.42 + sin(clock * 1.2 + float(i) * 2.0) * 0.07
		draw_rect(Rect2(x, y, w * 0.034, h * 0.025), Color(1.0, 0.68, 0.37, flicker))
	# Wet road glints.
	for i in range(12):
		var t := float(i) / 12.0
		var yy := h * (0.68 + t * 0.30)
		var xx := w * (0.23 + fposmod(float(i) * 0.37, 0.54))
		draw_line(Vector2(xx, yy), Vector2(xx + w * (0.012 + t * 0.045), yy), Color(0.93, 0.69, 0.50, 0.11 + t * 0.13), 2.0)
	# Slowly floating warm dust particles.
	for i in range(motes.size()):
		var p := motes[i]
		var alpha := (0.18 + sin(clock * 1.8 + float(i)) * 0.07) * p.z
		draw_circle(Vector2(p.x * w, p.y * h), 1.0 + 2.0 * p.z, Color(1.0, 0.77, 0.51, alpha))

func draw_ellipse_shadow(center: Vector2, radius: Vector2, tint: Color) -> void:
	var points := PackedVector2Array()
	for i in range(33):
		var angle := float(i) * TAU / 32.0
		points.append(center + Vector2(cos(angle) * radius.x, sin(angle) * radius.y))
	draw_colored_polygon(points, tint)
