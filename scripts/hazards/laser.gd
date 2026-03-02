extends Area2D

@export var point_a: Vector2 = Vector2.ZERO
@export var point_b: Vector2 = Vector2(100, 0)
@export var on_time: int = 60   # frames on
@export var off_time: int = 90  # frames off
@export var phase: int = 0      # frame offset

var timer: int = 0
var is_on: bool = true
var beam_width: float = 4.0

func _ready() -> void:
	collision_layer = 4  # layer 3 (hazards)
	collision_mask = 2   # layer 2 (player)
	monitoring = true
	monitorable = false
	
	# Position at midpoint, collision along the line
	var mid = (point_a + point_b) / 2.0
	global_position = mid
	
	var diff = point_b - point_a
	var length = diff.length()
	
	var shape_node = CollisionShape2D.new()
	var rect = RectangleShape2D.new()
	rect.size = Vector2(length, beam_width * 2)
	shape_node.shape = rect
	shape_node.rotation = diff.angle()
	add_child(shape_node)
	
	# Apply phase offset
	timer = -phase
	_update_state()
	
	body_entered.connect(_on_body_entered)

func _process(_delta: float) -> void:
	timer += 1
	_update_state()
	queue_redraw()

func _update_state() -> void:
	var cycle = on_time + off_time
	if cycle <= 0:
		is_on = true
		return
	var pos_in_cycle = timer % cycle
	if pos_in_cycle < 0:
		pos_in_cycle += cycle
	is_on = pos_in_cycle < on_time
	
	# Disable collision when off
	set_deferred("monitoring", is_on)

func _draw() -> void:
	var mid = global_position
	var half_a = point_a - mid
	var half_b = point_b - mid
	
	if is_on:
		# Bright red beam
		draw_line(half_a, half_b, Color(1.0, 0.1, 0.1, 0.9), beam_width)
		# Glow
		draw_line(half_a, half_b, Color(1.0, 0.3, 0.3, 0.3), beam_width * 3)
	else:
		# Dim indicator
		draw_line(half_a, half_b, Color(0.3, 0.1, 0.1, 0.3), 1.0)

func _on_body_entered(body: Node2D) -> void:
	if is_on and body.has_method("die"):
		body.die()
