extends Node
class_name LevelLoader

const SPIKE_SCENE = preload("res://scenes/hazards/spike.tscn")
const SAW_SCENE = preload("res://scenes/hazards/saw.tscn")
const LASER_SCENE = preload("res://scenes/hazards/laser.tscn")
const GOLD_SCENE = preload("res://scenes/gold.tscn")
const GRAPPLE_POINT_SCENE = preload("res://scenes/grapple_point.tscn")

var level_data: Array = []
var current_level_index: int = 0

func _ready() -> void:
	_load_level_data()

func _load_level_data() -> void:
	var file = FileAccess.open("res://levels/level_data.json", FileAccess.READ)
	if file:
		var json = JSON.new()
		var err = json.parse(file.get_as_text())
		if err == OK:
			level_data = json.data
		else:
			push_error("Failed to parse level_data.json: " + json.get_error_message())
	else:
		push_error("Failed to open level_data.json")

func get_level_count() -> int:
	return level_data.size()

func get_level_name(index: int) -> String:
	if index >= 0 and index < level_data.size():
		return level_data[index].get("name", "UNKNOWN")
	return "UNKNOWN"

func load_level(index: int, parent: Node) -> Dictionary:
	if index < 0 or index >= level_data.size():
		push_error("Invalid level index: %d" % index)
		return {}

	current_level_index = index
	var data = level_data[index]
	var result = {"platforms": [], "hazards": [], "gold": [], "grapple_points": []}

	# Build platforms as StaticBody2D
	for p in data.get("platforms", []):
		var body = StaticBody2D.new()
		var shape = CollisionShape2D.new()
		var rect = RectangleShape2D.new()
		rect.size = Vector2(p["w"], p["h"])
		shape.shape = rect
		body.position = Vector2(p["x"] + p["w"] / 2.0, p["y"] + p["h"] / 2.0)
		body.add_child(shape)
		# Visual
		var sprite = ColorRect.new()
		sprite.size = Vector2(p["w"], p["h"])
		sprite.position = Vector2(-p["w"] / 2.0, -p["h"] / 2.0)
		sprite.color = Color(0.3, 0.3, 0.35)
		body.add_child(sprite)
		body.collision_layer = 1
		body.collision_mask = 0
		parent.add_child(body)
		result["platforms"].append(body)

	# Spawn hazards
	for h in data.get("hazards", []):
		var hazard: Node2D = null
		match h["type"]:
			"spike":
				hazard = SPIKE_SCENE.instantiate()
				hazard.position = Vector2(h["x"] + h["w"] / 2.0, h["y"] + h["h"] / 2.0)
				hazard.spike_size = Vector2(h["w"], h["h"])
			"saw":
				hazard = SAW_SCENE.instantiate()
				hazard.position = Vector2(h["x"], h["y"])
				hazard.radius = h.get("radius", 25)
				hazard.move_x = h.get("moveX", 0)
				hazard.move_y = h.get("moveY", 0)
				hazard.speed = h.get("speed", 0)
				hazard.phase = h.get("phase", 0.0)
			"laser":
				hazard = LASER_SCENE.instantiate()
				hazard.point_a = Vector2(h["x1"], h["y1"])
				hazard.point_b = Vector2(h["x2"], h["y2"])
				hazard.on_time = h.get("onTime", 60)
				hazard.off_time = h.get("offTime", 90)
				hazard.phase = h.get("phase", 0)
		if hazard:
			parent.add_child(hazard)
			result["hazards"].append(hazard)

	# Spawn gold
	for g in data.get("gold", []):
		var gold = GOLD_SCENE.instantiate()
		gold.position = Vector2(g["x"], g["y"])
		parent.add_child(gold)
		result["gold"].append(gold)

	# Spawn grapple points
	for gp in data.get("grapplePoints", []):
		var point = GRAPPLE_POINT_SCENE.instantiate()
		point.position = Vector2(gp["x"], gp["y"])
		parent.add_child(point)
		result["grapple_points"].append(point)

	return result

func get_player_start(index: int) -> Vector2:
	if index >= 0 and index < level_data.size():
		var ps = level_data[index].get("playerStart", {"x": 50, "y": 940})
		return Vector2(ps["x"], ps["y"])
	return Vector2(50, 940)
