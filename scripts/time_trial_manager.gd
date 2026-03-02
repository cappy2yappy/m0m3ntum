extends Node
class_name TimeTrialManager

# ============================================================
# M0M3NTUM — Time Trial Manager
# Handles best times, grades, ghost recording/playback
# ============================================================

const SAVE_PATH := "user://momentum_records.cfg"
const GHOST_SAVE_PATH := "user://momentum_ghosts.cfg"

var _config: ConfigFile
var _ghost_config: ConfigFile
var _recording_frames: Array = []
var _ghost_cache: Dictionary = {}   # level_index -> Array of {x,y,f}
var _frame_tick: int = 0
var _is_recording: bool = false

func _ready() -> void:
	_config = ConfigFile.new()
	_config.load(SAVE_PATH)
	_ghost_config = ConfigFile.new()
	_ghost_config.load(GHOST_SAVE_PATH)
	# Pre-load ghost data into memory cache
	for i in range(20):
		var key := "g%d" % i
		if _ghost_config.has_section_key("g", key):
			_ghost_cache[i] = _ghost_config.get_value("g", key, [])

# ---- Recording ----

func start_recording() -> void:
	_recording_frames = []
	_frame_tick = 0
	_is_recording = true

func stop_recording() -> void:
	_is_recording = false

func record_position(pos: Vector2, facing: int) -> void:
	if not _is_recording:
		return
	_frame_tick += 1
	if _frame_tick % 3 == 0:
		_recording_frames.append({"x": pos.x, "y": pos.y, "f": facing})

# ---- Best Times ----

func get_best_time(level_index: int) -> float:
	return _config.get_value("t", "l%d" % level_index, -1.0)

func get_best_grade(level_index: int) -> String:
	return _config.get_value("gr", "l%d" % level_index, "")

func try_save_best(level_index: int, time: float, deaths: int) -> bool:
	"""Returns true if this run beats the previous best time."""
	var key := "l%d" % level_index
	var old_time: float = _config.get_value("t", key, -1.0)
	var is_new_best := (old_time < 0.0 or time < old_time)
	if is_new_best:
		_config.set_value("t", key, time)
		var grade := calculate_grade(time, deaths)
		_config.set_value("gr", key, grade)
		_config.save(SAVE_PATH)
		# Save ghost recording
		_ghost_cache[level_index] = _recording_frames.duplicate()
		_ghost_config.set_value("g", "g%d" % level_index, _recording_frames)
		_ghost_config.save(GHOST_SAVE_PATH)
	return is_new_best

# ---- Ghost ----

func get_ghost_frames(level_index: int) -> Array:
	return _ghost_cache.get(level_index, [])

# ---- Grading ----

func calculate_grade(time: float, deaths: int) -> String:
	if time < 30.0 and deaths == 0:
		return "S"
	elif time < 60.0 and deaths <= 1:
		return "A"
	elif time < 120.0 and deaths <= 3:
		return "B"
	else:
		return "C"

func get_grade_color(grade: String) -> Color:
	match grade:
		"S": return Color(1.0, 0.9, 0.0)
		"A": return Color(0.3, 1.0, 0.3)
		"B": return Color(0.3, 0.6, 1.0)
		_:   return Color(0.65, 0.65, 0.65)

# ---- Formatting ----

func format_time(t: float) -> String:
	if t < 0.0:
		return "---"
	var mins := int(t) / 60
	var secs := int(t) % 60
	var cs := int(fmod(t, 1.0) * 100)
	if mins > 0:
		return "%d:%02d.%02d" % [mins, secs, cs]
	return "%d.%02d" % [secs, cs]
