extends Node2D
class_name PlatformDraw

# ============================================================
# PlatformDraw — Stylized rooftop platform visuals
# Dark stone body with warm amber torch-lit top edge
# Matches M0M3NTUM night-city aesthetic
# ============================================================

var platform_size: Vector2 = Vector2(100, 20)

# Torch particle data (for platforms wide enough)
var torches: Array = []
var time_elapsed: float = 0.0
var particles: Array = []

func _ready() -> void:
	# Generate torch positions on wider platforms
	if platform_size.x >= 80:
		var torch_count := int(platform_size.x / 80)
		for i in range(torch_count):
			var tx := (float(i + 1) / float(torch_count + 1)) * platform_size.x
			torches.append(Vector2(tx, -4))
	_spawn_initial_particles()

func _spawn_initial_particles() -> void:
	for torch in torches:
		for _i in range(6):
			particles.append(_make_particle(torch))

func _make_particle(origin: Vector2) -> Dictionary:
	return {
		"x": origin.x + randf_range(-4, 4),
		"y": origin.y,
		"vx": randf_range(-0.8, 0.8),
		"vy": randf_range(-2.5, -1.0),
		"life": randf_range(0.3, 0.8),
		"max_life": randf_range(0.3, 0.8),
		"origin": origin,
	}

func _process(delta: float) -> void:
	time_elapsed += delta
	# Update particles
	var dead := []
	for i in range(particles.size()):
		var p = particles[i]
		p["x"] += p["vx"] * delta * 60
		p["y"] += p["vy"] * delta * 60
		p["vy"] -= 0.05 * delta * 60  # slow upward drift
		p["life"] -= delta
		if p["life"] <= 0:
			dead.append(i)
	# Remove dead, spawn new
	for i in dead:
		particles[i] = _make_particle(particles[i]["origin"])
	queue_redraw()

func _draw() -> void:
	var w := platform_size.x
	var h := platform_size.y

	# ── BODY ────────────────────────────────────────────────
	# Dark stone gradient: slightly lighter at top
	var body_rect := Rect2(0, 0, w, h)
	draw_rect(body_rect, Color(0.10, 0.09, 0.14))

	# Stone texture suggestion — subtle horizontal bands
	var band_h := 8.0
	var band_y := 4.0
	while band_y < h:
		draw_rect(Rect2(0, band_y, w, 1.5), Color(0.12, 0.11, 0.17, 0.6))
		band_y += band_h

	# Subtle grain lines (vertical cracks)
	var rng := RandomNumberGenerator.new()
	rng.seed = int(w * 7 + h * 13)  # deterministic per platform size
	for _i in range(int(w / 30)):
		var cx := rng.randf() * w
		draw_line(Vector2(cx, 2), Vector2(cx + rng.randf_range(-3, 3), h - 2),
			Color(0.08, 0.07, 0.12, 0.4), 1.0)

	# ── TOP SURFACE EDGE ─────────────────────────────────────
	# Bright amber lit edge (torch light from above)
	draw_line(Vector2(0, 0), Vector2(w, 0), Color(0.55, 0.35, 0.12), 2.5)
	# Softer glow rim just below
	draw_line(Vector2(0, 1), Vector2(w, 1), Color(0.35, 0.22, 0.08, 0.5), 1.5)
	# Side edges
	draw_line(Vector2(0, 0), Vector2(0, h), Color(0.15, 0.12, 0.22, 0.6), 1.0)
	draw_line(Vector2(w, 0), Vector2(w, h), Color(0.08, 0.07, 0.12, 0.4), 1.0)

	# ── TORCHES ──────────────────────────────────────────────
	for torch in torches:
		var tx: float = torch.x
		var ty: float = torch.y
		# Torch bracket (simple bracket shape)
		draw_rect(Rect2(tx - 2, ty, 4, 5), Color(0.45, 0.35, 0.18))
		draw_rect(Rect2(tx - 3, ty + 4, 6, 3), Color(0.35, 0.27, 0.14))
		# Flame glow
		var flicker := 0.7 + 0.3 * sin(time_elapsed * 8.0 + torch.x * 0.1)
		var glow_r := 18.0 * flicker
		# Outer glow
		draw_circle(Vector2(tx, ty - 2), glow_r, Color(0.6, 0.3, 0.05, 0.06 * flicker))
		draw_circle(Vector2(tx, ty - 2), glow_r * 0.6, Color(0.8, 0.45, 0.1, 0.1 * flicker))
		# Flame core
		draw_circle(Vector2(tx, ty - 3), 3.5, Color(1.0, 0.7, 0.2, 0.9 * flicker))
		draw_circle(Vector2(tx, ty - 4.5), 2.0, Color(1.0, 0.9, 0.5, flicker))

	# ── EMBER PARTICLES ──────────────────────────────────────
	for p in particles:
		var life_frac: float = p["life"] / p["max_life"]
		var r: float = lerpf(1.0, 0.8, 1.0 - life_frac)
		var g: float = lerpf(0.3, 0.6, 1.0 - life_frac)
		var alpha: float = life_frac * 0.85
		var pr := lerpf(1.5, 0.3, 1.0 - life_frac)
		draw_circle(Vector2(p["x"], p["y"]), pr, Color(r, g, 0.05, alpha))
