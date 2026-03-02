extends Area2D

const GRAPPLE_RANGE := 300.0

func _ready() -> void:
	collision_layer = 16  # layer 5 (grapple points)
	collision_mask = 2    # layer 2 (player)
	monitoring = false
	monitorable = true
	add_to_group("grapple_points")
	
	# Collision shape
	var shape = CollisionShape2D.new()
	var circle = CircleShape2D.new()
	circle.radius = 16.0
	shape.shape = circle
	add_child(shape)

func _draw() -> void:
	# Yellow diamond
	var size = 12.0
	var points = PackedVector2Array([
		Vector2(0, -size),
		Vector2(size, 0),
		Vector2(0, size),
		Vector2(-size, 0)
	])
	draw_colored_polygon(points, Color(1.0, 0.9, 0.0))
	# Inner highlight
	var inner = size * 0.5
	var inner_points = PackedVector2Array([
		Vector2(0, -inner),
		Vector2(inner, 0),
		Vector2(0, inner),
		Vector2(-inner, 0)
	])
	draw_colored_polygon(inner_points, Color(1.0, 1.0, 0.6, 0.6))
