extends Area2D

signal collected

var bob_offset: float = 0.0
var origin_y: float = 0.0

func _ready() -> void:
	collision_layer = 8   # layer 4 (collectibles)
	collision_mask = 2    # layer 2 (player)
	monitoring = true
	monitorable = false
	add_to_group("gold")
	
	origin_y = position.y
	bob_offset = randf() * TAU
	
	# Collision shape - small circle
	var shape = CollisionShape2D.new()
	var circle = CircleShape2D.new()
	circle.radius = 12.0
	shape.shape = circle
	add_child(shape)
	
	body_entered.connect(_on_body_entered)

func _process(delta: float) -> void:
	bob_offset += delta * 3.0
	position.y = origin_y + sin(bob_offset) * 4.0
	queue_redraw()

func _draw() -> void:
	# Gold coin - yellow circle with shine
	draw_circle(Vector2.ZERO, 10.0, Color(1.0, 0.85, 0.0))
	draw_circle(Vector2(-2, -2), 4.0, Color(1.0, 0.95, 0.5, 0.6))

func _on_body_entered(body: Node2D) -> void:
	if body.has_method("die"):
		emit_signal("collected")
		_spawn_collect_particles()
		# Find game manager and notify
		var manager = get_tree().get_first_node_in_group("game_manager")
		if manager and manager.has_method("collect_gold"):
			manager.collect_gold()
		elif body.has_signal("collected_gold"):
			body.emit_signal("collected_gold")
		queue_free()

func _spawn_collect_particles() -> void:
	if not is_inside_tree():
		return
	var p := CPUParticles2D.new()
	get_parent().add_child(p)
	p.global_position = global_position
	p.emitting = true
	p.one_shot = true
	p.explosiveness = 0.92
	p.amount = 14
	p.lifetime = 0.5
	p.initial_velocity_min = 70.0
	p.initial_velocity_max = 200.0
	p.direction = Vector2(0.0, -1.0)
	p.spread = 180.0
	p.gravity = Vector2(0.0, 180.0)
	p.scale_amount_min = 3.0
	p.scale_amount_max = 6.0
	p.color = Color(1.0, 0.88, 0.05)
	get_tree().create_timer(1.0).timeout.connect(p.queue_free)
