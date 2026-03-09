extends CharacterBody2D

const KiraAnimations = preload("res://scripts/kira_animations.gd")
const SFXManagerScript = preload("res://scripts/sfx_manager.gd")

# ============================================================
# M0M3NTUM — Player Controller
# N++ Inspired Additive Velocity Physics System
# Ported from HTML prototype v4
# ============================================================

# PHYSICS CONSTANTS — tuned after N++/Celeste/Dead Cells analysis
# N++ key insight: floaty apex + strong wall jump = flow state
# Celeste: snappy dash, forgiving coyote, never punish forward momentum
const GRAVITY := 1980.0
const HOLD_JUMP_GRAVITY_MULT := 0.28     # N++: very floaty on hold (was 0.35)
const FALL_GRAVITY_MULT := 1.8           # heavier fall = snappier rhythm (was 1.6)
const JUMP_RELEASE_GRAVITY_MULT := 2.2   # quick short hop on release (was 2.0)
const APEX_GRAVITY_MULT := 0.25          # N++: big apex hang time (was 0.4)
const APEX_VELOCITY_THRESHOLD := 120.0   # wider apex window (was 90)
const MAX_FALL_SPEED := 900.0
const MAX_MOVE_SPEED := 420.0            # slightly faster run (was 390)
const MOVE_ACCEL := 42.0                 # snappier ground accel (was 36)
const AIR_ACCEL := 30.0                  # keep air a bit floaty (was 33)
const GROUND_FRICTION := 0.70            # slightly more slide (was 0.72)
const AIR_FRICTION := 0.97               # preserve air momentum longer (was 0.96)

# N++ ADDITIVE JUMP
const JUMP_IMPULSE := -570.0      # lowered per Cap feedback (was -630, too high)
const JUMP_MIN_VELOCITY := -780.0
const MAX_UPWARD_SPEED := -1080.0
const WALL_JUMP_IMPULSE_Y := -600.0  # stronger wall jump (was -540) — N++ key feel
const WALL_JUMP_FORCE_X := 510.0     # more horizontal kick (was 480)
const WALL_SLIDE_SPEED := 60.0       # slower wall slide = more control (was 72)

# Dash — Dead Cells style: fast burst, short window
const DASH_SPEED := 1600.0         # slightly faster burst (was 1500)
const DASH_DURATION := 0.12        # slightly shorter (was 0.133) — snappier
const MAX_AIR_DASHES := 1          # 1 air dash = more skillful (was 2)
const DASH_COOLDOWN := 0.2         # shorter cooldown (was 0.25)

# Forgiveness — Celeste-level generosity
const COYOTE_TIME := 0.2           # slightly more coyote (was 0.167)
const JUMP_BUFFER_TIME := 0.2      # more buffer window (was 0.167)

# Grapple
const GRAPPLE_MAX_LENGTH := 300.0
const GRAPPLE_SPEED := 25.0

# Assist mode
const ASSIST_HITBOX_SHRINK := 4.0
const ASSIST_HAZARD_SPEED_MULT := 0.6

# State
var facing_dir := 1
var is_touching_wall := 0
var coyote_timer := 0.0
var jump_buffer_timer := 0.0
var dash_buffer_timer := 0.0
var dash_cooldown_timer := 0.0
var dash_timer := 0.0
var dash_count := MAX_AIR_DASHES
var is_dashing := false
var is_grappling := false
var grapple_point := Vector2.ZERO
var grapple_length := 0.0
var assist_mode := false
var is_dead := false

# SFX
var sfx: Node = null

# Animation
var scarf_points: Array[Vector2] = []
var trail_positions: Array[Vector2] = []
var animated_sprite: AnimatedSprite2D = null
var _current_anim := ""
var _was_on_floor := false   # track landing for combo reset

# Signals
signal died
signal collected_gold
signal combo_triggered(action: String)
signal combo_reset

func _ready() -> void:
	# Initialize scarf physics points
	for i in range(8):
		scarf_points.append(global_position + Vector2(-i * 4, 0))
	
	# Set up SFX
	sfx = SFXManagerScript.new()
	sfx.name = "SFX"
	add_child(sfx)

	# Set up KIRA AnimatedSprite2D
	animated_sprite = get_node_or_null("AnimatedSprite2D")
	if animated_sprite:
		animated_sprite.sprite_frames = KiraAnimations.build_sprite_frames()
		_play_anim("idle")
	else:
		push_warning("Player: AnimatedSprite2D node not found — falling back to procedural rendering")

func _physics_process(delta: float) -> void:
	if is_dead:
		return
	
	# Toggle assist mode
	if Input.is_action_just_pressed("assist_mode"):
		assist_mode = !assist_mode
	
	# Timers
	coyote_timer = max(0.0, coyote_timer - delta)
	jump_buffer_timer = max(0.0, jump_buffer_timer - delta)
	dash_buffer_timer = max(0.0, dash_buffer_timer - delta)
	dash_cooldown_timer = max(0.0, dash_cooldown_timer - delta)
	
	# Dash
	if is_dashing:
		dash_timer -= delta
		if dash_timer <= 0:
			is_dashing = false
			velocity.x = facing_dir * MAX_MOVE_SPEED
			dash_cooldown_timer = DASH_COOLDOWN
		else:
			# During dash, only move horizontally
			velocity.x = DASH_SPEED * facing_dir
			velocity.y = 0
			_update_trail()
			move_and_slide()
			_check_wall_touch()
			_update_scarf(delta)
			return
	
	# Movement
	var input_dir := 0.0
	if Input.is_action_pressed("move_left"):
		input_dir = -1.0
		facing_dir = -1
	elif Input.is_action_pressed("move_right"):
		input_dir = 1.0
		facing_dir = 1
	
	if input_dir != 0:
		var accel = MOVE_ACCEL if is_on_floor() else AIR_ACCEL
		velocity.x = clamp(velocity.x + input_dir * accel, -MAX_MOVE_SPEED, MAX_MOVE_SPEED)
	else:
		var friction = GROUND_FRICTION if is_on_floor() else AIR_FRICTION
		velocity.x *= friction
		if abs(velocity.x) < 10:
			velocity.x = 0
	
	# Coyote time
	var _on_floor_now := is_on_floor()
	if _on_floor_now:
		coyote_timer = COYOTE_TIME
		dash_count = MAX_AIR_DASHES
		if not _was_on_floor:
			emit_signal("combo_reset")   # only on landing, not every frame
	_was_on_floor = _on_floor_now
	
	# Jump buffer
	if Input.is_action_just_pressed("jump"):
		jump_buffer_timer = JUMP_BUFFER_TIME
	
	# Dash buffer
	if Input.is_action_just_pressed("dash"):
		dash_buffer_timer = JUMP_BUFFER_TIME
	
	# ======== JUMP — N++ ADDITIVE VELOCITY ========
	if jump_buffer_timer > 0:
		if coyote_timer > 0:
			# ADDITIVE: add impulse to current velocity
			velocity.y += JUMP_IMPULSE
			if velocity.y < MAX_UPWARD_SPEED:
				velocity.y = MAX_UPWARD_SPEED
			if velocity.y > JUMP_MIN_VELOCITY:
				velocity.y = JUMP_MIN_VELOCITY
			coyote_timer = 0
			jump_buffer_timer = 0
			_spawn_jump_particles()
		elif is_touching_wall != 0:
			# Wall jump — additive
			velocity.y += WALL_JUMP_IMPULSE_Y
			if velocity.y < MAX_UPWARD_SPEED:
				velocity.y = MAX_UPWARD_SPEED
			velocity.x = WALL_JUMP_FORCE_X * -is_touching_wall
			facing_dir = -is_touching_wall
			is_touching_wall = 0
			jump_buffer_timer = 0
			_spawn_wall_jump_particles()
			emit_signal("combo_triggered", "WALL JUMP")
	
	# Dash initiation
	if dash_buffer_timer > 0 and dash_cooldown_timer <= 0:
		if is_on_floor() or dash_count > 0:
			if not is_on_floor():
				dash_count -= 1
			is_dashing = true
			dash_timer = DASH_DURATION
			dash_buffer_timer = 0
			velocity.y = 0
			velocity.x = DASH_SPEED * facing_dir
			_spawn_dash_particles()
			emit_signal("combo_triggered", "DASH")
	
	# ======== GRAVITY — N++ SYSTEM ========
	if is_grappling:
		_process_grapple(delta)
	else:
		var gravity_mult := 1.0
		if velocity.y < 0 and Input.is_action_pressed("jump"):
			# ASCENDING + HOLDING JUMP = reduced gravity (the N++ magic)
			gravity_mult = HOLD_JUMP_GRAVITY_MULT
		elif velocity.y < 0 and not Input.is_action_pressed("jump"):
			# ASCENDING + RELEASED = snappy short hop
			gravity_mult = JUMP_RELEASE_GRAVITY_MULT
		elif abs(velocity.y) < APEX_VELOCITY_THRESHOLD:
			# AT APEX = hang time
			gravity_mult = APEX_GRAVITY_MULT
		elif velocity.y > 0:
			# FALLING = heavier
			gravity_mult = FALL_GRAVITY_MULT
		
		velocity.y += GRAVITY * gravity_mult * delta
	
	# Wall slide
	if is_touching_wall != 0 and velocity.y > 0 and not is_on_floor():
		velocity.y = min(velocity.y, WALL_SLIDE_SPEED)
	
	# Max fall speed
	velocity.y = min(velocity.y, MAX_FALL_SPEED)
	
	# Move
	move_and_slide()
	_check_wall_touch()
	_update_trail()
	_update_scarf(delta)
	_update_animation()
	queue_redraw()

func _play_anim(anim: String) -> void:
	if not animated_sprite:
		return
	# Fall back to idle if the animation doesn't exist in the sprite frames
	var target := anim
	if animated_sprite.sprite_frames and not animated_sprite.sprite_frames.has_animation(target):
		target = "idle"
	if _current_anim != target:
		_current_anim = target
		animated_sprite.visible = true
		animated_sprite.play(target)

func _update_animation() -> void:
	if not animated_sprite:
		return
	
	# Flip sprite based on facing direction
	animated_sprite.flip_h = (facing_dir == -1)
	
	# Priority: death > hit_react > dash > wall_slide > attack > jump > crouch > run > idle
	if is_dead:
		_play_anim("death")
		return
	
	if is_dashing:
		_play_anim("dash")
		return
	
	if is_touching_wall != 0 and velocity.y > 0 and not is_on_floor():
		_play_anim("wall_slide")
		return
	
	if not is_on_floor():
		if velocity.y < -30.0:
			_play_anim("jump")
		else:
			_play_anim("fall")
		return
	
	var crouch_held := Input.is_action_pressed("crouch") if InputMap.has_action("crouch") else false
	if crouch_held:
		_play_anim("crouch")   # instant snap, 1-frame loop — never disappears
		return
	
	if abs(velocity.x) > 50.0:
		_play_anim("run")
		return
	
	_play_anim("idle")

func _check_wall_touch() -> void:
	is_touching_wall = 0
	if is_on_wall():
		# Check which side
		for i in get_slide_collision_count():
			var collision = get_slide_collision(i)
			if collision.get_normal().x > 0.5:
				is_touching_wall = -1
			elif collision.get_normal().x < -0.5:
				is_touching_wall = 1

func _process_grapple(delta: float) -> void:
	var center = global_position + Vector2(0, -16)
	var to_anchor = center - grapple_point
	var dist = to_anchor.length()
	
	if dist > grapple_length:
		var dir = to_anchor.normalized()
		global_position -= dir * (dist - grapple_length)
		var dot_normal = velocity.dot(dir)
		if dot_normal > 0:
			velocity -= dir * dot_normal * 0.9
		
		if Input.is_action_pressed("move_left"):
			velocity.x -= 30.0
		if Input.is_action_pressed("move_right"):
			velocity.x += 30.0
	
	velocity.y += GRAVITY * 0.7 * delta
	velocity.y = min(velocity.y, MAX_FALL_SPEED * 0.8)
	
	if Input.is_action_just_pressed("jump"):
		is_grappling = false
		velocity.y = min(velocity.y, JUMP_MIN_VELOCITY * 0.7)

func _update_trail() -> void:
	if is_dashing:
		trail_positions.append(global_position)
		if trail_positions.size() > 5:
			trail_positions.pop_front()
	else:
		trail_positions.clear()

func _update_scarf(delta: float) -> void:
	# Verlet integration for scarf physics
	var anchor = global_position + Vector2(-facing_dir * 8, -20)
	if scarf_points.size() > 0:
		scarf_points[0] = anchor
	
	for i in range(1, scarf_points.size()):
		var point = scarf_points[i]
		var prev = scarf_points[i - 1]
		
		# Apply wind and gravity to scarf
		var wind = Vector2(-velocity.x * 0.3, -velocity.y * 0.15)
		wind += Vector2(sin(Time.get_ticks_msec() * 0.003 + i * 0.5) * 20, 10)
		point += wind * delta
		
		# Constrain distance
		var diff = point - prev
		var dist = diff.length()
		var max_dist = 6.0
		if dist > max_dist:
			point = prev + diff.normalized() * max_dist
		
		scarf_points[i] = point

func die() -> void:
	if is_dead:
		return
	is_dead = true
	if animated_sprite:
		_play_anim("death")
		animated_sprite.animation_finished.connect(_on_death_anim_done.bind(), CONNECT_ONE_SHOT)
	else:
		visible = false
	_spawn_death_particles()
	emit_signal("died")

func _on_death_anim_done() -> void:
	visible = false

func respawn(pos: Vector2) -> void:
	global_position = pos
	velocity = Vector2.ZERO
	is_dead = false
	visible = true
	is_dashing = false
	is_grappling = false
	dash_count = MAX_AIR_DASHES
	coyote_timer = 0
	jump_buffer_timer = 0
	_current_anim = ""
	if animated_sprite:
		_play_anim("idle")

func _draw() -> void:
	# Grapple rope (drawn in local space)
	if is_grappling:
		var center = Vector2(0, -28)
		var local_target = grapple_point - global_position
		# Glow
		draw_line(center, local_target, Color(0.85, 0.25, 0.1, 0.3), 8.0)
		# Main rope — dashed red cord
		draw_line(center, local_target, Color(0.75, 0.2, 0.1), 2.5)
		# Anchor point
		draw_circle(local_target, 5.0, Color(0.9, 0.35, 0.1))
		draw_circle(local_target, 2.5, Color(1.0, 0.6, 0.4))
	
	# Skip procedural drawing when using KIRA animated sprite
	if animated_sprite and animated_sprite.sprite_frames:
		# Only draw dash trail and scarf — sprite handles the body
		if is_dashing:
			var scarf_color = Color("#cc2244")
			for i in range(trail_positions.size()):
				var local_pos = trail_positions[i] - global_position
				var alpha = float(i) / trail_positions.size() * 0.4
				draw_circle(local_pos + Vector2(0, -28), 10.0, Color(scarf_color, alpha))
		return
	
	# ── MODERN 2D KIRA — Godot draw API version ─────────────
	var SKIN      := Color(0.545, 0.369, 0.235)   # warm dark brown
	var SKIN_HI   := Color(0.69, 0.47, 0.33)      # highlight
	var SKIN_SHD  := Color(0.42, 0.265, 0.14)     # shadow
	var HAIR      := Color(0.08, 0.06, 0.06)
	var OUTFIT    := Color(0.08, 0.08, 0.10)
	var OUTFIT_HI := Color(0.16, 0.16, 0.22)
	var SCARF     := Color(0.80, 0.13, 0.17)
	var SCARF_HI  := Color(0.95, 0.27, 0.33)
	var WRAPS     := Color(0.86, 0.83, 0.78)
	var WRAPS_SHD := Color(0.66, 0.63, 0.58)

	var oy := -56.0   # feet at 0, head at top  (hitbox is 56px tall centered at -28)
	var t  := Time.get_ticks_msec() * 0.001

	var is_running: bool = abs(velocity.x) > 50.0
	var is_rising  := velocity.y < -30.0 and not is_on_floor()
	var is_falling := velocity.y > 30.0 and not is_on_floor()
	var is_sliding := is_touching_wall != 0 and velocity.y > 0 and not is_on_floor()

	# Run cycle
	var ri := (Time.get_ticks_msec() / 50) % 8
	var RUN8 := [
		Vector4(-0.55, 0.55, 0.3, -0.3),
		Vector4(-0.75, 0.75, 0.5, -0.1),
		Vector4(-0.45, 0.45, 0.2, 0.2),
		Vector4(-0.15, 0.15, -0.1, 0.5),
		Vector4(0.55, -0.55, -0.3, 0.3),
		Vector4(0.75, -0.75, -0.5, 0.1),
		Vector4(0.45, -0.45, -0.2, -0.2),
		Vector4(0.15, -0.15, 0.1, -0.5),
	]
	var rp: Vector4 = RUN8[ri] if is_running else Vector4(0, 0, 0, 0)
	# rp.x=lA(arm), y=rA, z=lK(knee), w=rK
	var bob := sin(t * 12.0) * 1.5 if is_running else sin(t * 2.0) * 0.8
	var jump_tuck := -6.0 if is_rising else (5.0 if is_falling else 0.0)
	var body_lean := 8.0 if is_sliding else (-5.0 if is_rising else (12.0 if is_dashing else 0.0))

	# Coordinate helpers (all in local space, character faces right by default)
	# head top = oy, feet = 0
	var head_cy := oy + 12.0 + bob        # head center y
	var neck_y  := oy + 20.0 + bob
	var shldr_y := oy + 24.0 + bob
	var hip_y   := oy + 44.0 + bob
	var cx      := 0.0                    # center x

	# ── PONYTAIL ─────────────────────────────────────────────
	var pt_swing := -10.0 if is_rising else (12.0 if is_falling else (sin(t * 8.0) * 6.0 if is_running else sin(t * 3.0) * 2.0))
	var pt_base := Vector2(cx - facing_dir * 5.0, neck_y - 4.0)
	var pt_mid  := Vector2(pt_base.x - facing_dir * pt_swing * 0.3, pt_base.y + 6.0)
	var pt_tip  := Vector2(pt_base.x - facing_dir * pt_swing, pt_base.y + 16.0)
	# Draw as thick tapered line (3 circles fading)
	draw_line(pt_base, pt_mid, HAIR, 5.0)
	draw_line(pt_mid, pt_tip, HAIR, 3.5)
	draw_circle(pt_tip, 2.0, HAIR)
	# Red tie
	draw_circle(pt_base + Vector2(0, 1), 2.5, SCARF)

	# ── BACK ARM ─────────────────────────────────────────────
	var ba_ang: float = rp.y + jump_tuck * 0.015
	var elb_b  := Vector2(cx + 12.0 + sin(ba_ang) * 9.0, shldr_y + 5.0 + cos(ba_ang) * 8.0)
	var wri_b  := Vector2(cx + 12.0 + sin(ba_ang) * 16.0, shldr_y + 5.0 + cos(ba_ang) * 14.0)
	draw_line(Vector2(cx + 10.0, shldr_y + 4.0), elb_b, SKIN_SHD, 6.0)
	draw_line(elb_b, wri_b, SKIN_SHD, 5.0)
	draw_circle(wri_b, 4.0, WRAPS_SHD)  # back wrist wrap

	# ── BACK LEG ─────────────────────────────────────────────
	var bl_ang: float = rp.y * 0.9 + jump_tuck * 0.04
	var kn_b   := Vector2(cx + 6.0 + sin(bl_ang) * 10.0, hip_y + 4.0 + cos(bl_ang) * 4.0)
	var ft_b   := Vector2(cx + 6.0 + sin(bl_ang + rp.w) * 18.0, hip_y + 4.0 + cos(bl_ang + rp.w) * 16.0)
	draw_line(Vector2(cx + 5.0, hip_y + 2.0), kn_b, OUTFIT, 9.0)
	draw_line(kn_b, ft_b, OUTFIT, 7.0)
	draw_circle(ft_b, 4.5, WRAPS_SHD)  # back ankle
	draw_circle(Vector2(ft_b.x + facing_dir * 4.0, ft_b.y + 3.0), 5.0, Color(0.08, 0.07, 0.09))  # tabi

	# ── TORSO ────────────────────────────────────────────────
	# Main body shape (drawn as polygon for lean)
	var lean_off := body_lean * 0.15
	var torso_pts := PackedVector2Array([
		Vector2(cx - 10.0, shldr_y),
		Vector2(cx + 10.0 + lean_off, shldr_y),
		Vector2(cx + 9.0 + lean_off, hip_y),
		Vector2(cx - 9.0, hip_y),
	])
	draw_polygon(torso_pts, PackedColorArray([OUTFIT, OUTFIT_HI, OUTFIT, OUTFIT]))
	# Collar
	draw_line(Vector2(cx - 4.0, shldr_y), Vector2(cx + 4.0 + lean_off, shldr_y), OUTFIT_HI, 2.5)

	# DIAGONAL SASH — shoulder to hip
	var sash_wave := sin(t * 4.0) * 1.5
	var sash_start := Vector2(cx + 8.0 + lean_off, shldr_y + 2.0)
	var sash_end   := Vector2(cx - 8.0, hip_y - 2.0)
	var sash_mid   := Vector2(cx + sash_wave, (shldr_y + hip_y) * 0.5)
	# Draw as ribbon (two parallel curves)
	draw_line(sash_start, sash_mid, SCARF, 4.5)
	draw_line(sash_mid, sash_end, SCARF, 4.0)
	draw_line(Vector2(sash_start.x - 1.5, sash_start.y), sash_mid + Vector2(-1, 0), SCARF_HI, 2.0)
	# Knot at hip end
	draw_circle(sash_end, 4.0, SCARF)
	draw_circle(sash_end, 2.0, SCARF_HI)

	# ── HEAD ────────────────────────────────────────────────
	# Skull
	draw_circle(Vector2(cx, head_cy), 11.0, SKIN)
	# Highlight
	draw_circle(Vector2(cx - 3.0, head_cy - 4.0), 4.5, SKIN_HI)
	# Hair top
	var hair_pts := PackedVector2Array([
		Vector2(cx - 10.0, head_cy - 2.0),
		Vector2(cx - 8.0, head_cy - 12.0),
		Vector2(cx - 2.0, head_cy - 14.5),
		Vector2(cx + 3.0, head_cy - 14.0),
		Vector2(cx + 10.0, head_cy - 8.0),
		Vector2(cx + 10.0, head_cy - 2.0),
	])
	draw_polygon(hair_pts, PackedColorArray([HAIR, HAIR, HAIR, HAIR, HAIR, HAIR]))
	# Side hair L
	draw_circle(Vector2(cx - 10.0, head_cy + 2.0), 4.0, HAIR)
	draw_circle(Vector2(cx - 11.0, head_cy + 5.0), 3.0, HAIR)

	# Eyes (anime almond shape via ellipse approximation with circles)
	var is_glow := is_dashing
	var eye_col := SCARF if is_glow else Color(0.15, 0.10, 0.06)
	var white_col := SCARF_HI if is_glow else Color(1.0, 0.97, 0.93)
	# Left eye
	draw_circle(Vector2(cx - 4.0, head_cy - 0.5), 3.5, white_col)
	draw_circle(Vector2(cx - 3.5, head_cy - 0.5), 2.5, eye_col)
	draw_circle(Vector2(cx - 5.0, head_cy - 1.5), 1.0, Color.WHITE)  # specular
	draw_line(Vector2(cx - 7.5, head_cy - 3.5), Vector2(cx - 0.5, head_cy - 4.0), HAIR, 1.2)  # lash
	# Right eye
	draw_circle(Vector2(cx + 4.0, head_cy - 0.5), 3.5, white_col)
	draw_circle(Vector2(cx + 4.5, head_cy - 0.5), 2.5, eye_col)
	draw_circle(Vector2(cx + 2.5, head_cy - 1.5), 1.0, Color.WHITE)
	draw_line(Vector2(cx + 0.5, head_cy - 4.0), Vector2(cx + 7.5, head_cy - 3.5), HAIR, 1.2)

	# Nose
	draw_circle(Vector2(cx + 2.0 * facing_dir, head_cy + 4.0), 1.2, SKIN_SHD)
	# Mouth
	draw_line(Vector2(cx - 2.5, head_cy + 6.5), Vector2(cx + 2.5 * facing_dir + 1.0, head_cy + 6.0), SKIN_SHD, 1.0)

	# ── WAIST BELT ───────────────────────────────────────────
	draw_rect(Rect2(cx - 10.0, hip_y - 2.0, 20.0, 5.0), Color(0.07, 0.07, 0.09))
	draw_rect(Rect2(cx - 3.0, hip_y - 2.0, 6.0, 5.0), SCARF)  # belt clasp

	# ── FRONT LEG ────────────────────────────────────────────
	var fl_ang: float = rp.x * 0.9 + jump_tuck * 0.04
	var kn_f   := Vector2(cx - 5.0 + sin(fl_ang) * 10.0, hip_y + 4.0 + cos(fl_ang) * 4.0)
	var ft_f   := Vector2(cx - 5.0 + sin(fl_ang + rp.z) * 18.0, hip_y + 4.0 + cos(fl_ang + rp.z) * 16.0)
	draw_line(Vector2(cx - 5.0, hip_y + 2.0), kn_f, OUTFIT_HI, 9.0)
	draw_line(kn_f, ft_f, OUTFIT_HI, 7.5)
	draw_circle(ft_f, 5.0, WRAPS)  # front ankle wrap
	draw_circle(Vector2(ft_f.x + facing_dir * 5.0, ft_f.y + 3.0), 6.0, Color(0.10, 0.09, 0.11))  # tabi

	# ── FRONT ARM ────────────────────────────────────────────
	var fa_ang: float = rp.x + jump_tuck * 0.015
	var elb_f  := Vector2(cx - 12.0 + sin(fa_ang) * 9.0, shldr_y + 5.0 + cos(fa_ang) * 8.0)
	var wri_f  := Vector2(cx - 12.0 + sin(fa_ang) * 16.0, shldr_y + 5.0 + cos(fa_ang) * 14.0)
	draw_line(Vector2(cx - 10.0, shldr_y + 4.0), elb_f, SKIN, 6.5)
	draw_line(elb_f, wri_f, SKIN, 5.0)
	draw_circle(wri_f, 4.5, WRAPS)

	# ── SASH TAIL (flowing physics ribbon) ───────────────────
	if scarf_points.size() > 2:
		var pts_a: PackedVector2Array = []
		var pts_b: PackedVector2Array = []
		for i in range(scarf_points.size()):
			var lp := scarf_points[i] - global_position
			var perp := Vector2(-0.0, 1.0) * (2.5 - i * 0.25)
			pts_a.append(lp - perp)
			pts_b.append(lp + perp)
		# Fill ribbon
		for i in range(1, pts_a.size()):
			var life_frac := 1.0 - float(i) / pts_a.size()
			var col := Color(SCARF.r, SCARF.g, SCARF.b, life_frac * 0.85)
			draw_line(pts_a[i-1], pts_a[i], col, max(3.0 - i * 0.3, 0.5))

	# ── DASH TRAIL ────────────────────────────────────────────
	if is_dashing:
		for i in range(trail_positions.size()):
			var local_pos := trail_positions[i] - global_position
			var alpha := float(i) / trail_positions.size() * 0.35
			draw_circle(local_pos + Vector2(0, oy + 28.0), 12.0, Color(SCARF.r, SCARF.g, SCARF.b, alpha))

# ============================================================
# INPUT — Godot best practice: use _unhandled_input for game actions
# so UI elements can consume events first
# ============================================================
func _unhandled_input(event: InputEvent) -> void:
	if is_dead:
		return
	# Grapple: fire on press, release on release
	if event.is_action_pressed("grapple"):
		_try_fire_grapple()
	elif event.is_action_released("grapple"):
		is_grappling = false

# ============================================================
# GRAPPLE — raycast toward mouse, snap to nearest surface
# Godot best practice: use PhysicsDirectSpaceState2D for raycasts
# ============================================================
func _try_fire_grapple() -> void:
	var player_center := global_position + Vector2(0, -28)
	var mouse_pos := get_global_mouse_position()
	
	# ── SPIDER-MAN RULE: grapple only fires ABOVE the player ──
	# If mouse is at or below player center, clamp aim to horizontal
	var to_target := mouse_pos - player_center
	if to_target.y >= 0:
		# Redirect to directly above — refuse to grapple downward
		to_target = Vector2(to_target.x * 0.3, -GRAPPLE_MAX_LENGTH * 0.8)
	
	var dist_to_target: float = to_target.length()
	var capped_dist: float = dist_to_target if dist_to_target < GRAPPLE_MAX_LENGTH else GRAPPLE_MAX_LENGTH
	var ray_end: Vector2 = player_center + to_target.normalized() * capped_dist
	
	# Raycast toward target — hit platforms (layer 1)
	var space := get_world_2d().direct_space_state
	var query := PhysicsRayQueryParameters2D.create(player_center, ray_end, 1)
	query.exclude = [self]
	var result := space.intersect_ray(query)
	
	if result and result.has("position"):
		var hit_pos: Vector2 = result["position"]
		var hit_dist := player_center.distance_to(hit_pos)
		# Only attach if it's above the player
		if hit_dist > 20.0 and hit_dist <= GRAPPLE_MAX_LENGTH and hit_pos.y < player_center.y:
			is_grappling = true
			grapple_point = hit_pos
			grapple_length = hit_dist
			_spawn_grapple_particles(hit_pos)
			emit_signal("combo_triggered", "GRAPPLE")
			return
	
	# Fallback: nearest grapple_point anchor that is ABOVE the player
	var nearest_dist := GRAPPLE_MAX_LENGTH
	var nearest_pos := Vector2.ZERO
	for gp in get_tree().get_nodes_in_group("grapple_points"):
		if gp.global_position.y >= player_center.y:
			continue   # skip anchors at or below player
		var d := player_center.distance_to(gp.global_position)
		if d < nearest_dist:
			nearest_dist = d
			nearest_pos = gp.global_position
	
	if nearest_pos != Vector2.ZERO:
		is_grappling = true
		grapple_point = nearest_pos
		grapple_length = nearest_dist
		_spawn_grapple_particles(nearest_pos)
		emit_signal("combo_triggered", "GRAPPLE")

func _spawn_jump_particles() -> void:
	if sfx: sfx.play_jump()
	_burst_particles(global_position + Vector2(0, 0), Color(0.7, 0.85, 1.0), 6, 80.0, 160.0)

func _spawn_wall_jump_particles() -> void:
	if sfx: sfx.play_wall_jump()
	_burst_particles(global_position + Vector2(is_touching_wall * 12, -16), Color(0.9, 0.7, 1.0), 8, 100.0, 220.0)

func _spawn_dash_particles() -> void:
	if sfx: sfx.play_dash()
	_burst_particles(global_position + Vector2(0, -28), Color(0.85, 0.25, 0.15), 12, 80.0, 220.0)

func _spawn_grapple_particles(pos: Vector2) -> void:
	if sfx: sfx.play_grapple_fire()
	_burst_particles(pos, Color(0.9, 0.3, 0.1), 6, 60.0, 140.0, 0.3)

func _spawn_death_particles() -> void:
	if sfx: sfx.play_death()
	# Red burst at center-of-mass
	_burst_particles(global_position + Vector2(0, -24), Color(1.0, 0.1, 0.1), 18, 120.0, 320.0, 0.7)
	# Secondary dark particles
	_burst_particles(global_position + Vector2(0, -20), Color(0.6, 0.0, 0.0), 8, 60.0, 140.0, 0.5)

func _burst_particles(pos: Vector2, color: Color, amount: int,
		vel_min: float, vel_max: float, lifetime: float = 0.45) -> void:
	if not is_inside_tree():
		return
	var p := CPUParticles2D.new()
	get_parent().add_child(p)
	p.global_position = pos
	p.emitting = true
	p.one_shot = true
	p.explosiveness = 0.95
	p.amount = amount
	p.lifetime = lifetime
	p.initial_velocity_min = vel_min
	p.initial_velocity_max = vel_max
	p.direction = Vector2(0.0, -1.0)
	p.spread = 180.0
	p.gravity = Vector2(0.0, 280.0)
	p.scale_amount_min = 2.5
	p.scale_amount_max = 5.0
	p.color = color
	# Auto-cleanup after lifetime + small buffer
	get_tree().create_timer(lifetime + 0.5).timeout.connect(p.queue_free)
