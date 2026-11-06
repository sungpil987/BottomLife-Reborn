extends Control
# Procedural pixel character: each tile is a separate, animated sprite pixel.
# Rendered at low internal resolution then scaled with nearest-neighbour filtering.
var elapsed: float = 0.0
var hit_time: float = 0.0
const P := 5.0
const PIXELS := [
".........................",
".........hhhhhh..........",
".......hhhhhhhhhh........",
"......hhhhhhhhhhhh.......",
"......hhhsssssshhhh......",
".....hhhssssssssshhh.....",
".....hhssssssssssshh.....",
".....hhssessssessshh.....",
".....hhssssssssssshh.....",
"......hssssnnsssshh......",
".......ssssmmmmsss.......",
"........ssssssssss.......",
".......jjjssssjjj.......",
".....jjjjjjjjjjjjjjj.....",
"....jjjjjjjjjjjjjjjjj....",
"...jjjjjjjjjjjjjjjjjjj...",
"...jjjjjjjjjjjjjjjjjjj...",
"...jjjjjjjjjjjjjjjjjjj...",
"...jjjjjjjjjjjjjjjjjjj...",
"...jjjjjjjjjjjjjjjjjjj...",
"....jjjjjjjjjjjjjjjjj....",
".....jjjjjjjjjjjjjjj.....",
"......jjjjjjjjjjjjj......",
"......ppppppppppppp......",
"......ppppppppppppp......",
".......ppppp.ppppp.......",
".......ppppp.ppppp.......",
".......ppppp.ppppp.......",
".......ppppp.ppppp.......",
".......bbbbb.bbbbb.......",
"......bbbbbb.bbbbbb......",
"........................."
]
const COLORS := {
"h": Color("#1b1a27"), "s": Color("#c58c72"), "e": Color("#20212a"),
"n": Color("#a56b5d"), "m": Color("#694a4d"), "j": Color("#56505e"),
"p": Color("#353443"), "b": Color("#242530")
}
func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE

func _process(delta: float) -> void:
	elapsed += delta
	hit_time = maxf(0.0, hit_time - delta)
	queue_redraw()

func react() -> void:
	hit_time = 0.20

func _draw() -> void:
	var tile := minf(size.x / 29.0, size.y / 37.0)
	var offset := Vector2((size.x - 25.0 * tile) * 0.5, (size.y - 32.0 * tile) * 0.5)
	var bob := sin(elapsed * 2.5) * tile * 0.5
	var squash := 1.0 - (0.08 if hit_time > 0.0 else 0.0)
	var origin := offset + Vector2(0, bob + (1.0 - squash) * 30.0 * tile)
	draw_set_transform(origin, 0.0, Vector2(1.0, squash))
	for y in range(PIXELS.size()):
		var line: String = PIXELS[y]
		for x in range(line.length()):
			var key := line.substr(x, 1)
			if COLORS.has(key):
				draw_rect(Rect2(x * tile, y * tile, ceilf(tile), ceilf(tile)), COLORS[key])
	# Animated hands, shoes and clothing details are separate pixel layers.
	var swing := roundi(sin(elapsed * 3.0) * 1.0)
	for side in [-1, 1]:
		var hand_x := 1 if side < 0 else 22
		var hand_y := 19 + swing * side
		draw_rect(Rect2(hand_x * tile, hand_y * tile, 3 * tile, 5 * tile), Color("#484350"))
		draw_rect(Rect2(hand_x * tile, (hand_y + 5) * tile, 3 * tile, 2 * tile), Color("#c58c72"))
	draw_rect(Rect2(9 * tile, 18 * tile, 7 * tile, tile), Color("#8a7a74"))
	draw_rect(Rect2(10 * tile, 19 * tile, 5 * tile, tile), Color("#2b2934"))
	draw_set_transform(Vector2.ZERO)
