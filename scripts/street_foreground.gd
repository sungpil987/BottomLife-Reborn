extends Control
# Foreground pixel-art props and puddle reflections; drawn over the character.
var elapsed: float = 0.0

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE

func _process(delta: float) -> void:
	elapsed += delta
	queue_redraw()

func _draw() -> void:
	var w := size.x
	var h := size.y
	if w <= 0.0 or h <= 0.0:
		return
	# Road curb and low perspective ledge.
	draw_rect(Rect2(0, h * 0.88, w, h * 0.018), Color("#333340"))
	draw_rect(Rect2(0, h * 0.90, w, h * 0.10), Color("#24242f"))
	draw_rect(Rect2(0, h * 0.88, w, h * 0.006), Color("#70635b"))
	# Pixelated puddles, broken into sharp horizontal strips.
	for i in range(8):
		var xx := w * (0.07 + fposmod(float(i) * 0.271, 0.83))
		var yy := h * (0.925 + float(i % 3) * 0.019)
		var shimmer := 0.45 + 0.2 * sin(elapsed * 1.5 + float(i))
		draw_rect(Rect2(xx, yy, w * (0.025 + float(i % 4) * 0.012), 3.0), Color(0.59, 0.72, 0.79, shimmer))
	# Left foreground rubbish bin.
	var bx := w * 0.045
	var by := h * 0.72
	draw_rect(Rect2(bx, by, w * 0.11, h * 0.19), Color("#1a222d"))
	draw_rect(Rect2(bx - 4, by, w * 0.12 + 8, 7), Color("#56616b"))
	draw_rect(Rect2(bx + 6, by + 15, 5, h * 0.13), Color("#3c4a54"))
	draw_rect(Rect2(bx + w * 0.07, by + 15, 5, h * 0.13), Color("#3c4a54"))
	# Right foreground cardboard box.
	var rx := w * 0.84
	var ry := h * 0.81
	draw_rect(Rect2(rx, ry, w * 0.12, h * 0.085), Color("#6e5140"))
	draw_rect(Rect2(rx + 5, ry + 4, w * 0.10, h * 0.012), Color("#a17b58"))
	draw_rect(Rect2(rx + w * 0.055, ry + 4, 5, h * 0.07), Color("#4d392f"))
