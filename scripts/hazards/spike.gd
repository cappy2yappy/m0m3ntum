extends Area2D

@export var spike_size: Vector2 = Vector2(50, 20)

func _ready() -> void:
	collision_layer = 4  # layer 3 (bit 2)
	collision_mask = 2   # layer 2 (player)
	monitoring = true
	monitorable = false

	# Collision shape
	var shape = CollisionShape2D.new()
	var rect = RectangleShape2D.new()
	rect.size = spike_size
	shape.shape = rect
	add_child(shape)

	# Visual - red spikes
	var visual = ColorRect.new()
	visual.size = spike_size
	visual.position = -spike_size / 2.0
	visual.color = Color(0.9, 0.15, 0.15)
	add_child(visual)

	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node2D) -> void:
	if body.has_method("die"):
		body.die()
