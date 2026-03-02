extends Area2D

@export var radius: float = 25.0
@export var move_x: float = 0.0
@export var move_y: float = 0.0
@export var speed: float = 0.0
@export var phase: float = 0.0

var origin: Vector2
var time: float = 0.0
var rotation_speed: float = 5.0

func _ready() -> void:
	collision_layer = 4  # layer 3
	collision_mask = 2   # layer 2 (player)
	monitoring = true
	monitorable = false

	origin = position
	time = phase

	# Collision shape - circle
	var shape = CollisionShape2D.new()
	var circle = CircleShape2D.new()
	circle.radius = radius
	shape.shape = circle
	add_child(shape)

	# Visual - orange circle
	var visual = ColorRect.new()
	visual.size = Vector2(radius * 2, radius * 2)
	visual.position = Vector2(-radius, -radius)
	visual.color = Color(1.0, 0.5, 0.0)
	add_child(visual)

	body_entered.connect(_on_body_entered)

func _process(delta: float) -> void:
	time += delta * speed
	position.x = origin.x + sin(time) * move_x
	position.y = origin.y + sin(time) * move_y
	# Spin visual
	rotation += rotation_speed * delta

func _on_body_entered(body: Node2D) -> void:
	if body.has_method("die"):
		body.die()
