extends Control
# Lightweight pixel HUD ornaments; no input capture.
var clock: float = 0.0
var redraw_timer: float = 0.0

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE

func _process(delta: float) -> void:
	clock += delta
	redraw_timer += delta
	if redraw_timer >= 0.12:
		redraw_timer = 0.0
		queue_redraw()

func _draw() -> void:
	if size.x < 40.0 or size.y < 40.0:
		return
	var w: float = size.x
	var h: float = size.y
	# Fine pixel frame and diagonal etched corners.
	var gold := Color("#c89a5a", 0.50)
	var dim := Color("#8b6e55", 0.22)
	draw_rect(Rect2(2, 2, w - 4, 2), gold)
	draw_rect(Rect2(2, h - 4, w - 4, 2), dim)
	for side in range(2):
		var x: float = 8.0 if side == 0 else w - 28.0
		draw_rect(Rect2(x, 8, 20, 3), gold)
		draw_rect(Rect2(x, 8, 3, 19), gold)
		draw_rect(Rect2(x, h - 13, 20, 3), dim)
	# Status dots, with a very subtle breathing highlight.
	for i in range(4):
		var alpha: float = 0.35 + 0.18 * sin(clock * 1.3 + float(i) * 0.6)
		draw_rect(Rect2(w - 28.0 - float(i) * 9.0, h - 13.0, 4, 4), Color(0.96, 0.76, 0.43, alpha))
