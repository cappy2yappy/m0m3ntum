extends Node2D

# ============================================================
# M0M3NTUM — Game Manager v2
# Level loading, scoring, death/respawn, UI, time trials,
# ghost replay, level complete screen, level select
# ============================================================

const _TimeTrialManagerScript = preload("res://scripts/time_trial_manager.gd")
const _GhostPlayerScript = preload("res://scripts/ghost_player.gd")

@onready var player: CharacterBody2D = $Player
@onready var camera: Camera2D = $Player/Camera2D
@onready var level_loader: LevelLoader = $LevelLoader
@onready var city_background: Node2D = $CityBackground
@onready var level_container: Node2D = $Level
@onready var ui: CanvasLayer = $UI
@onready var gold_label: Label = $UI/HUD/GoldLabel
@onready var deaths_label: Label = $UI/HUD/DeathsLabel
@onready var timer_label: Label = $UI/HUD/TimerLabel
@onready var dashes_label: Label = $UI/HUD/DashesLabel
@onready var level_name_label: Label = $UI/HUD/LevelName
@onready var assist_label: Label = $UI/HUD/AssistLabel

var total_gold := 0
var collected_gold := 0
var deaths := 0
var level_time := 0.0
var game_running := false
var current_level := 0
var spawn_point := Vector2.ZERO

const DEATH_RESPAWN_TIME := 0.33

var death_timer := 0.0

# New systems
var time_trial: TimeTrialManager = null
var ghost_player: GhostPlayer = null
var best_time_label: Label = null
var new_best_label: Label = null
var new_best_timer: float = 0.0
var death_flash: ColorRect = null
var death_flash_timer: float = 0.0
var level_complete_layer: CanvasLayer = null
var level_select_layer: CanvasLayer = null

# ── Combo system ──────────────────────────────────────────────────────────
var combo_count := 0
var combo_timer := 0.0
const COMBO_WINDOW := 1.5   # seconds to chain next move
var combo_label: Label = null
var combo_bar: ColorRect = null
var combo_bar_fill: ColorRect = null

func _ready() -> void:
	player.died.connect(_on_player_died)
	player.combo_triggered.connect(_on_combo_triggered)
	player.combo_reset.connect(_on_combo_reset)
	# Hook background parallax to camera
	if city_background and city_background.has_method("set_camera"):
		city_background.set_camera(camera)

	# Create time trial manager
	time_trial = _TimeTrialManagerScript.new()
	time_trial.name = "TimeTrialManager"
	add_child(time_trial)

	# Create ghost player (sibling to player, drawn behind)
	ghost_player = _GhostPlayerScript.new()
	ghost_player.name = "GhostPlayer"
	ghost_player.z_index = -2
	add_child(ghost_player)

	# Add extra HUD / overlay elements
	_setup_extra_ui()

	load_level(current_level)


func _setup_extra_ui() -> void:
	var hud = $UI/HUD

	# Best time label added to HUD bar
	best_time_label = Label.new()
	best_time_label.name = "BestTimeLabel"
	best_time_label.custom_minimum_size = Vector2(180, 0)
	best_time_label.text = "Best: ---"
	hud.add_child(best_time_label)

	# "NEW BEST!" flash label — positioned in center-top of screen
	new_best_label = Label.new()
	new_best_label.name = "NewBestLabel"
	new_best_label.text = "★  NEW BEST!  ★"
	new_best_label.visible = false
	new_best_label.add_theme_font_size_override("font_size", 30)
	new_best_label.add_theme_color_override("font_color", Color(1.0, 0.95, 0.1))
	new_best_label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.8))
	new_best_label.add_theme_constant_override("shadow_offset_x", 2)
	new_best_label.add_theme_constant_override("shadow_offset_y", 2)
	# Center it via anchors
	new_best_label.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	new_best_label.offset_top = 55
	new_best_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	$UI.add_child(new_best_label)

	# Death flash — full-screen red overlay that fades
	death_flash = ColorRect.new()
	death_flash.name = "DeathFlash"
	death_flash.color = Color(1.0, 0.0, 0.0, 0.0)
	death_flash.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	death_flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	$UI.add_child(death_flash)

	# Combo bar — thin bar below HUD
	combo_bar = ColorRect.new()
	combo_bar.name = "ComboBar"
	combo_bar.color = Color(0, 0, 0, 0.4)
	combo_bar.set_anchors_preset(Control.PRESET_TOP_WIDE)
	combo_bar.offset_top = 36
	combo_bar.offset_bottom = 50
	combo_bar.visible = false
	$UI.add_child(combo_bar)

	combo_bar_fill = ColorRect.new()
	combo_bar_fill.name = "ComboBarFill"
	combo_bar_fill.color = Color(0.95, 0.8, 0.1)
	combo_bar_fill.set_anchors_preset(Control.PRESET_TOP_WIDE)
	combo_bar_fill.offset_top = 38
	combo_bar_fill.offset_bottom = 48
	combo_bar_fill.offset_right = 0
	combo_bar_fill.visible = false
	$UI.add_child(combo_bar_fill)

	combo_label = Label.new()
	combo_label.name = "ComboLabel"
	combo_label.text = ""
	combo_label.visible = false
	combo_label.add_theme_font_size_override("font_size", 11)
	combo_label.add_theme_color_override("font_color", Color(1, 1, 1))
	combo_label.set_anchors_preset(Control.PRESET_TOP_WIDE)
	combo_label.offset_top = 37
	combo_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	$UI.add_child(combo_label)


func _on_combo_triggered(action: String) -> void:
	combo_count += 1
	combo_timer = COMBO_WINDOW
	_update_combo_hud()

func _on_combo_reset() -> void:
	combo_count = 0
	combo_timer = 0.0
	_update_combo_hud()

func _update_combo_hud() -> void:
	if not combo_label: return
	var show = combo_count >= 2
	combo_label.visible = show
	combo_bar.visible = show
	combo_bar_fill.visible = show
	if show:
		var mult = min(combo_count, 8)
		var labels = ["", "", "x2 COMBO", "x3 HOT!", "x4 SICK!", "x5 WILD!", "x6 INSANE!", "x7 GODLIKE!", "x8 MAX!"]
		combo_label.text = labels[mult] if mult < labels.size() else ("x%d COMBO!" % mult)
		var fill_w = (combo_timer / COMBO_WINDOW)
		combo_bar_fill.anchor_right = fill_w
		# Color shift by multiplier
		var col: Color
		if mult >= 5: col = Color(1.0, 0.2, 0.2)
		elif mult >= 3: col = Color(1.0, 0.5, 0.1)
		else: col = Color(0.95, 0.85, 0.1)
		combo_bar_fill.color = col
		combo_label.add_theme_color_override("font_color", col)

func _process(delta: float) -> void:
	if game_running and not player.is_dead:
		level_time += delta
		if time_trial:
			time_trial.record_position(player.global_position, player.facing_dir)

	if player.is_dead:
		death_timer -= delta
		if death_timer <= 0:
			_respawn_player()

	# Combo timer tick
	if combo_timer > 0.0:
		combo_timer -= delta
		if combo_timer <= 0.0:
			_on_combo_reset()
		else:
			_update_combo_hud()

	# Fade death flash
	if death_flash_timer > 0.0:
		death_flash_timer -= delta
		death_flash.color.a = clampf(death_flash_timer * 2.2, 0.0, 0.5)
		if death_flash_timer <= 0.0:
			death_flash.color.a = 0.0

	# Animate NEW BEST label
	if new_best_timer > 0.0:
		new_best_timer -= delta
		new_best_label.visible = true
		var pulse = 1.0 + sin(new_best_timer * 12.0) * 0.04
		new_best_label.scale = Vector2(pulse, pulse)
		if new_best_timer <= 0.0:
			new_best_label.visible = false

	_update_ui()


func load_level(index: int) -> void:
	# Clear existing level
	for child in level_container.get_children():
		child.queue_free()

	# Close any open overlay screens
	if level_complete_layer:
		level_complete_layer.queue_free()
		level_complete_layer = null
	if level_select_layer:
		level_select_layer.queue_free()
		level_select_layer = null

	current_level = index
	level_loader.load_level(index, level_container)
	spawn_point = level_loader.get_player_start(index)

	if level_name_label:
		level_name_label.text = level_loader.get_level_name(index)

	# Update best time display
	if time_trial and best_time_label:
		var bt := time_trial.get_best_time(index)
		best_time_label.text = "Best: " + time_trial.format_time(bt)

	# Setup ghost from saved best run
	if time_trial and ghost_player:
		ghost_player.setup(time_trial.get_ghost_frames(index))

	# Start fresh recording for this run
	if time_trial:
		time_trial.start_recording()

	# Wait a frame for nodes to enter the tree
	await get_tree().process_frame

	total_gold = get_tree().get_nodes_in_group("gold").size()
	collected_gold = 0
	deaths = 0
	level_time = 0.0
	game_running = true

	player.respawn(spawn_point)


func start_level() -> void:
	load_level(current_level)


func _on_player_died() -> void:
	deaths += 1
	death_timer = DEATH_RESPAWN_TIME
	_screen_shake(12.0, 0.2)
	# Flash red
	if death_flash:
		death_flash_timer = 0.22
		death_flash.color.a = 0.48


func _respawn_player() -> void:
	player.respawn(spawn_point)
	# Reset ghost to beginning
	if ghost_player:
		ghost_player.reset_playback()
	# Restart timer and recording for new attempt
	level_time = 0.0
	if time_trial:
		time_trial.start_recording()


func collect_gold() -> void:
	collected_gold += 1
	if collected_gold >= total_gold:
		_level_complete()


func _level_complete() -> void:
	game_running = false
	if time_trial:
		time_trial.stop_recording()
		var is_new_best := time_trial.try_save_best(current_level, level_time, deaths)
		if is_new_best:
			new_best_timer = 2.8
	_show_level_complete_screen()


# ============================================================
# LEVEL COMPLETE SCREEN
# ============================================================

func _show_level_complete_screen() -> void:
	level_complete_layer = CanvasLayer.new()
	level_complete_layer.layer = 10
	level_complete_layer.name = "LevelCompleteLayer"
	add_child(level_complete_layer)

	# Semi-transparent dim
	var dim := ColorRect.new()
	dim.color = Color(0.0, 0.0, 0.05, 0.7)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	level_complete_layer.add_child(dim)

	# Centered panel container
	var panel := PanelContainer.new()
	panel.set_anchor(SIDE_LEFT, 0.5)
	panel.set_anchor(SIDE_TOP, 0.5)
	panel.set_anchor(SIDE_RIGHT, 0.5)
	panel.set_anchor(SIDE_BOTTOM, 0.5)
	panel.offset_left = -220.0
	panel.offset_top = -210.0
	panel.offset_right = 220.0
	panel.offset_bottom = 210.0
	level_complete_layer.add_child(panel)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 28)
	margin.add_theme_constant_override("margin_right", 28)
	margin.add_theme_constant_override("margin_top", 24)
	margin.add_theme_constant_override("margin_bottom", 24)
	panel.add_child(margin)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 10)
	margin.add_child(vbox)

	# Level name
	var name_lbl := Label.new()
	name_lbl.text = level_loader.get_level_name(current_level)
	name_lbl.add_theme_font_size_override("font_size", 22)
	name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_lbl.add_theme_color_override("font_color", Color(1.0, 0.92, 0.3))
	vbox.add_child(name_lbl)

	# COMPLETE header
	var complete_lbl := Label.new()
	complete_lbl.text = "— LEVEL COMPLETE —"
	complete_lbl.add_theme_font_size_override("font_size", 16)
	complete_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	complete_lbl.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
	vbox.add_child(complete_lbl)

	# Grade
	var grade := ""
	if time_trial:
		grade = time_trial.calculate_grade(level_time, deaths)
	var grade_lbl := Label.new()
	grade_lbl.text = grade
	grade_lbl.add_theme_font_size_override("font_size", 52)
	grade_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	if time_trial:
		grade_lbl.add_theme_color_override("font_color", time_trial.get_grade_color(grade))
	vbox.add_child(grade_lbl)

	vbox.add_child(HSeparator.new())

	# Time
	var time_lbl := Label.new()
	var time_str := time_trial.format_time(level_time) if time_trial else ("%.2fs" % level_time)
	time_lbl.text = "Time      %s" % time_str
	time_lbl.add_theme_font_size_override("font_size", 17)
	vbox.add_child(time_lbl)

	# Best time
	if time_trial:
		var bt := time_trial.get_best_time(current_level)
		var best_lbl := Label.new()
		best_lbl.text = "Best      %s" % time_trial.format_time(bt)
		best_lbl.add_theme_font_size_override("font_size", 17)
		best_lbl.add_theme_color_override("font_color", Color(0.7, 1.0, 0.7))
		vbox.add_child(best_lbl)

	# Deaths
	var deaths_lbl := Label.new()
	deaths_lbl.text = "Deaths    %d" % deaths
	deaths_lbl.add_theme_font_size_override("font_size", 17)
	if deaths == 0:
		deaths_lbl.add_theme_color_override("font_color", Color(0.4, 1.0, 0.4))
	vbox.add_child(deaths_lbl)

	# Gold
	var gold_lbl := Label.new()
	gold_lbl.text = "Gold      %d / %d" % [collected_gold, total_gold]
	gold_lbl.add_theme_font_size_override("font_size", 17)
	vbox.add_child(gold_lbl)

	# Perfect run bonus
	if deaths == 0:
		var perfect_lbl := Label.new()
		perfect_lbl.text = "✦  PERFECT RUN  ✦"
		perfect_lbl.add_theme_font_size_override("font_size", 18)
		perfect_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		perfect_lbl.add_theme_color_override("font_color", Color(1.0, 0.85, 0.0))
		vbox.add_child(perfect_lbl)

	vbox.add_child(HSeparator.new())

	# Buttons
	var btn_row := HBoxContainer.new()
	btn_row.add_theme_constant_override("separation", 14)
	btn_row.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_child(btn_row)

	var retry_btn := Button.new()
	retry_btn.text = "↺  RETRY"
	retry_btn.custom_minimum_size = Vector2(130, 40)
	retry_btn.pressed.connect(func(): load_level(current_level))
	btn_row.add_child(retry_btn)

	var has_next := (current_level + 1 < level_loader.get_level_count())
	var next_btn := Button.new()
	next_btn.text = "NEXT  →" if has_next else "SELECT"
	next_btn.custom_minimum_size = Vector2(130, 40)
	if has_next:
		next_btn.pressed.connect(func(): load_level(current_level + 1))
	else:
		next_btn.pressed.connect(_show_level_select)
	btn_row.add_child(next_btn)

	var select_btn := Button.new()
	select_btn.text = "☰  LEVELS"
	select_btn.custom_minimum_size = Vector2(130, 40)
	select_btn.pressed.connect(_show_level_select)
	btn_row.add_child(select_btn)


# ============================================================
# LEVEL SELECT SCREEN
# ============================================================

func _show_level_select() -> void:
	if level_complete_layer:
		level_complete_layer.queue_free()
		level_complete_layer = null

	level_select_layer = CanvasLayer.new()
	level_select_layer.layer = 11
	level_select_layer.name = "LevelSelectLayer"
	add_child(level_select_layer)

	# Background
	var bg := ColorRect.new()
	bg.color = Color(0.04, 0.04, 0.10, 0.95)
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	level_select_layer.add_child(bg)

	# Main container
	var root_vbox := VBoxContainer.new()
	root_vbox.add_theme_constant_override("separation", 16)
	root_vbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root_vbox.offset_left = 40
	root_vbox.offset_top = 30
	root_vbox.offset_right = -40
	root_vbox.offset_bottom = -30
	level_select_layer.add_child(root_vbox)

	# Title row
	var title_row := HBoxContainer.new()
	title_row.add_theme_constant_override("separation", 20)
	root_vbox.add_child(title_row)

	var title := Label.new()
	title.text = "M0M3NTUM  —  SELECT LEVEL"
	title.add_theme_font_size_override("font_size", 26)
	title.add_theme_color_override("font_color", Color(1.0, 0.92, 0.2))
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title_row.add_child(title)

	var close_btn := Button.new()
	close_btn.text = "✕  BACK"
	close_btn.custom_minimum_size = Vector2(110, 36)
	close_btn.pressed.connect(func():
		level_select_layer.queue_free()
		level_select_layer = null
	)
	title_row.add_child(close_btn)

	# Separator
	root_vbox.add_child(HSeparator.new())

	# Level grid
	var grid := GridContainer.new()
	grid.columns = 3
	grid.add_theme_constant_override("h_separation", 14)
	grid.add_theme_constant_override("v_separation", 14)
	root_vbox.add_child(grid)

	# Determine unlock boundary: first level without a best time
	var level_count := level_loader.get_level_count()
	var max_unlocked := 0
	for i in range(level_count):
		if time_trial and time_trial.get_best_time(i) >= 0.0:
			max_unlocked = i + 1
	max_unlocked = min(max_unlocked, level_count - 1)

	for i in range(level_count):
		grid.add_child(_build_level_cell(i, i <= max_unlocked))


func _build_level_cell(index: int, unlocked: bool) -> Control:
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(230, 105)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 12)
	margin.add_theme_constant_override("margin_right", 12)
	margin.add_theme_constant_override("margin_top", 10)
	margin.add_theme_constant_override("margin_bottom", 10)
	panel.add_child(margin)

	var inner := VBoxContainer.new()
	inner.add_theme_constant_override("separation", 5)
	margin.add_child(inner)

	# Level name
	var name_lbl := Label.new()
	name_lbl.text = "%d.  %s" % [index + 1, level_loader.get_level_name(index)]
	name_lbl.add_theme_font_size_override("font_size", 14)
	var name_color := Color(1.0, 1.0, 1.0) if unlocked else Color(0.45, 0.45, 0.45)
	name_lbl.add_theme_color_override("font_color", name_color)
	name_lbl.clip_text = true
	inner.add_child(name_lbl)

	# Best time + grade
	var info_row := HBoxContainer.new()
	info_row.add_theme_constant_override("separation", 8)
	inner.add_child(info_row)

	var time_lbl := Label.new()
	var grade_str := ""
	if time_trial:
		var bt := time_trial.get_best_time(index)
		time_lbl.text = time_trial.format_time(bt)
		grade_str = time_trial.get_best_grade(index)
	else:
		time_lbl.text = "---"
	time_lbl.add_theme_font_size_override("font_size", 13)
	time_lbl.add_theme_color_override("font_color", Color(0.7, 0.85, 1.0))
	info_row.add_child(time_lbl)

	if grade_str != "":
		var grade_lbl := Label.new()
		grade_lbl.text = "[%s]" % grade_str
		grade_lbl.add_theme_font_size_override("font_size", 13)
		if time_trial:
			grade_lbl.add_theme_color_override("font_color", time_trial.get_grade_color(grade_str))
		info_row.add_child(grade_lbl)

	# Play / Locked button
	var btn := Button.new()
	btn.text = "▶  PLAY" if unlocked else "🔒  LOCKED"
	btn.disabled = not unlocked
	btn.custom_minimum_size = Vector2(110, 30)
	if unlocked:
		var captured := index
		btn.pressed.connect(func():
			level_select_layer.queue_free()
			level_select_layer = null
			load_level(captured)
		)
	inner.add_child(btn)

	return panel


# ============================================================
# INPUT
# ============================================================

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("level_select"):
		if level_select_layer:
			level_select_layer.queue_free()
			level_select_layer = null
		elif not level_complete_layer:
			_show_level_select()


# ============================================================
# UI UPDATE
# ============================================================

func _update_ui() -> void:
	if gold_label:
		gold_label.text = "Gold: %d/%d" % [collected_gold, total_gold]
	if deaths_label:
		deaths_label.text = "Deaths: %d" % deaths
	if timer_label:
		if time_trial:
			timer_label.text = time_trial.format_time(level_time)
		else:
			timer_label.text = "%.2fs" % level_time
	if dashes_label and player:
		dashes_label.text = "Dashes: %d" % player.dash_count
	if assist_label and player:
		assist_label.visible = player.assist_mode
	if best_time_label and time_trial:
		var bt := time_trial.get_best_time(current_level)
		best_time_label.text = "Best: " + time_trial.format_time(bt)


# ============================================================
# SCREEN SHAKE
# ============================================================

func _screen_shake(intensity: float, duration: float) -> void:
	if camera:
		var tween := create_tween()
		for i in range(int(duration * 60)):
			var offset := Vector2(
				randf_range(-intensity, intensity),
				randf_range(-intensity, intensity)
			)
			intensity *= 0.9
			tween.tween_property(camera, "offset", offset, 1.0 / 60.0)
		tween.tween_property(camera, "offset", Vector2.ZERO, 1.0 / 60.0)
