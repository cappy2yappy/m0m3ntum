extends Node2D

# ============================================================
# M0M3NTUM — Dark City Parallax Background
# Procedural night-city with stars, buildings, torch glows
# Matches HTML prototype v7 aesthetic
# ============================================================

const VIEWPORT_W := 1280.0
const VIEWPORT_H := 720.0

# Star data (generated once)
var stars: Array = []
var torch_particles: Array = []
var time_elapsed: float = 0.0

# Building layers (3 parallax depths)
var buildings_far: Array = []
var buildings_mid: Array = []
var buildings_near: Array = []

# Camera reference (set by game manager)
var camera_ref: Camera2D = null

func _ready() -> void:
	_generate_stars()
	_generate_buildings()
	_generate_torches()
	z_index = -10  # behind everything

func set_camera(cam: Camera2D) -> void:
	camera_ref = cam

func _generate_stars() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 42  # deterministic stars
	for i in range(160):
		stars.append({
			"x": rng.randf() * VIEWPORT_W * 3,
			"y": rng.randf() * VIEWPORT_H * 0.55,
			"r": rng.randf_range(0.5, 2.0),
			"twinkle": rng.randf() * TAU,
			"speed": rng.randf_range(0.01, 0.04),
		})

func _generate_buildings() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 100

	# Far layer — small silhouettes
	for i in range(24):
		buildings_far.append({
			"x": i * 160.0 - 400,
			"w": rng.randf_range(60, 140),
			"h": rng.randf_range(80, 200),
			"windows": _gen_windows(rng, 60, 100),
		})

	# Mid layer — medium
	for i in range(18):
		buildings_mid.append({
			"x": i * 220.0 - 300,
			"w": rng.randf_range(80, 180),
			"h": rng.randf_range(150, 320),
			"windows": _gen_windows(rng, 80, 140),
		})

	# Near layer — large foreground
	for i in range(12):
		buildings_near.append({
			"x": i * 380.0 - 200,
			"w": rng.randf_range(120, 260),
			"h": rng.randf_range(240, 440),
			"windows": _gen_windows(rng, 100, 200),
		})

func _gen_windows(rng: RandomNumberGenerator, bw: float, bh: float) -> Array:
	var wins := []
	var cols := int(bw / 18)
	var rows := int(bh / 22)
	for r in range(rows):
		for c in range(cols):
			if rng.randf() > 0.45:
				wins.append({
					"cx": c * 18 + 7,
					"cy": r * 22 + 8,
					"lit": rng.randf() > 0.4,
				})
	return wins

func _generate_torches() -> void:
	# Some glow particles for atmosphere
	pass

func _process(delta: float) -> void:
	time_elapsed += delta
	queue_redraw()

func _get_scroll_offset() -> Vector2:
	if camera_ref:
		return camera_ref.get_screen_center_position() - Vector2(VIEWPORT_W / 2.0, VIEWPORT_H / 2.0)
	return Vector2.ZERO

func _draw() -> void:
	var scroll := _get_scroll_offset()
	# Offset our drawing origin to stay in screen space
	var ox := scroll.x
	var oy2 := scroll.y

	# ── SKY GRADIENT ──────────────────────────────────────────
	for y in range(0, int(VIEWPORT_H), 4):
		var tf := float(y) / VIEWPORT_H
		var r := lerpf(0.02, 0.06, tf)
		var g := lerpf(0.02, 0.04, tf)
		var b := lerpf(0.08, 0.12, tf)
		draw_rect(Rect2(ox, oy2 + y, VIEWPORT_W, 5), Color(r, g, b))

	# ── STARS ─────────────────────────────────────────────────
	for star in stars:
		var sx: float = fmod(float(star["x"]) - scroll.x * 0.02, VIEWPORT_W * 2.5) + ox
		var sy: float = float(star["y"]) + oy2
		var twinkle: float = 0.5 + 0.5 * sin(time_elapsed * float(star["speed"]) * 60.0 + float(star["twinkle"]))
		var alpha: float = lerpf(0.3, 1.0, twinkle)
		draw_circle(Vector2(sx, sy), float(star["r"]), Color(1.0, 0.95, 0.85, alpha))

	# ── FAR BUILDINGS ─────────────────────────────────────────
	for b in buildings_far:
		var bx: float = fmod(float(b["x"]) - scroll.x * 0.15, VIEWPORT_W * 2.0) - 100.0 + ox
		var by: float = VIEWPORT_H - float(b["h"]) + oy2
		draw_rect(Rect2(bx, by, float(b["w"]), float(b["h"])), Color(0.06, 0.06, 0.10))
		_draw_windows(b["windows"], bx, by, Color(0.9, 0.75, 0.35, 0.25), Color(0.15, 0.13, 0.08, 0.3))

	# ── MID BUILDINGS ─────────────────────────────────────────
	for b in buildings_mid:
		var bx: float = fmod(float(b["x"]) - scroll.x * 0.35, VIEWPORT_W * 2.5) - 150.0 + ox
		var by: float = VIEWPORT_H - float(b["h"]) + oy2
		draw_rect(Rect2(bx, by, float(b["w"]), float(b["h"])), Color(0.07, 0.06, 0.12))
		draw_line(Vector2(bx, by), Vector2(bx + float(b["w"]), by), Color(0.18, 0.16, 0.28), 1.5)
		_draw_windows(b["windows"], bx, by, Color(0.95, 0.8, 0.4, 0.35), Color(0.15, 0.13, 0.08, 0.4))

	# ── NEAR BUILDINGS ────────────────────────────────────────
	for b in buildings_near:
		var bx: float = fmod(float(b["x"]) - scroll.x * 0.6, VIEWPORT_W * 2.8) - 200.0 + ox
		var by: float = VIEWPORT_H - float(b["h"]) + oy2
		draw_rect(Rect2(bx, by, float(b["w"]), float(b["h"])), Color(0.05, 0.04, 0.09))
		draw_line(Vector2(bx, by), Vector2(bx + float(b["w"]), by), Color(0.22, 0.18, 0.30), 2.0)
		_draw_windows(b["windows"], bx, by, Color(1.0, 0.85, 0.45, 0.45), Color(0.12, 0.10, 0.06, 0.5))
		if int(b["x"]) % 3 == 0:
			var ant_x: float = bx + float(b["w"]) * 0.7
			draw_line(Vector2(ant_x, by), Vector2(ant_x, by - 20), Color(0.3, 0.25, 0.4), 1.5)
			draw_circle(Vector2(ant_x, by - 20), 2.0, Color(0.9, 0.2, 0.2, 0.6 + 0.4 * sin(time_elapsed * 1.5)))

	# ── GROUND FOG ────────────────────────────────────────────
	for i in range(4):
		var alpha: float = 0.12 - i * 0.025
		draw_rect(Rect2(ox, VIEWPORT_H - 30 + i * 8 + oy2, VIEWPORT_W, 12), Color(0.08, 0.05, 0.15, alpha))

func _draw_windows(windows: Array, bx: float, by: float, lit_col: Color, unlit_col: Color) -> void:
	for w in windows:
		var col: Color = lit_col if w["lit"] else unlit_col
		draw_rect(Rect2(bx + float(w["cx"]), by + float(w["cy"]), 8, 10), col)
