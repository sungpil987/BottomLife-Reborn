extends Control

var drops: Array[Vector4] = []
var rng := RandomNumberGenerator.new()

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	rng.randomize()
	for i in range(64):
		drops.append(Vector4(rng.randf(), rng.randf(), rng.randf_range(0.35, 0.85), rng.randf_range(0.35, 0.8)))

func _process(delta: float) -> void:
	for i in range(drops.size()):
		var drop := drops[i]
		drop.y += delta * drop.z
		drop.x -= delta * 0.10 * drop.z
		if drop.y > 1.1:
			drop.y = -0.1
			drop.x = rng.randf()
		if drop.x < -0.1:
			drop.x = 1.1
		drops[i] = drop
	queue_redraw()

func _draw() -> void:
	var bounds := size
	for drop in drops:
		var origin := Vector2(drop.x * bounds.x, drop.y * bounds.y)
		var finish := origin + Vector2(-8.0, 22.0) * drop.z
		draw_line(origin, finish, Color(0.73, 0.83, 1.0, drop.w * 0.36), 1.5, true)
