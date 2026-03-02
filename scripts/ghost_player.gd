extends Node2D
class_name GhostPlayer

# ============================================================
# M0M3NTUM — Ghost Player
# Replays the best-time run as a semi-transparent ghost
# ============================================================

var _frames: Array = []
var _frame_idx: int = 0
var _tick: int = 0
var _is_active: bool = false
var _facing: int = 1

func setup(frames: Array) -> void:
	_frames = frames
	_frame_idx = 0
	_tick = 0
	_is_active = frames.size() > 0
	visible = _is_active
	if _is_active:
		_apply_frame(0)
		queue_redraw()

func reset_playback() -> void:
	_frame_idx = 0
	_tick = 0
	_is_active = _frames.size() > 0
	visible = _is_active
	if _is_active:
		_apply_frame(0)
		queue_redraw()

func _apply_frame(idx: int) -> void:
	if idx < 0 or idx >= _frames.size():
		return
	var f = _frames[idx]
	position = Vector2(f.get("x", 0.0), f.get("y", 0.0))
	_facing = f.get("f", 1)

func _process(_delta: float) -> void:
	if not _is_active or _frames.is_empty():
		return
	_tick += 1
	if _tick >= 3:
		_tick = 0
		_frame_idx += 1
		if _frame_idx >= _frames.size():
			_is_active = false
			visible = false
			return
		_apply_frame(_frame_idx)
		queue_redraw()

func _draw() -> void:
	if not _is_active:
		return
	var oy := -28.0
	var c := Color(0.45, 0.75, 1.0, 0.28)
	var c_bright := Color(0.6, 0.9, 1.0, 0.35)
	# Legs
	draw_rect(Rect2(-8, oy + 14, 6, 14), c)
	draw_rect(Rect2(2, oy + 14, 6, 14), c)
	# Torso
	draw_rect(Rect2(-10, oy - 6, 20, 22), c)
	# Arms
	draw_rect(Rect2(-14, oy - 4, 5, 14), c)
	draw_rect(Rect2(9, oy - 4, 5, 14), c)
	# Head
	draw_circle(Vector2(0, oy - 14), 8.0, c_bright)
	# Scarf hint
	for i in range(4):
		var sx = -_facing * i * 4.0
		draw_circle(Vector2(sx - _facing * 4, oy - 18 + i * 1.5), 2.5 - i * 0.3, Color(0.8, 0.3, 0.5, 0.22))
