extends CharacterBody2D

const KiraAnimations = preload("res://scripts/kira_animations.gd")

# ============================================================
# M0M3NTUM — Player Controller
# N++ Inspired Additive Velocity Physics System
# Ported from HTML prototype v4
# ============================================================

# PHYSICS CONSTANTS — Godot px/s velocity system
# HTML prototype used px/frame at 60fps — multiply by 60 for px/s equivalents
# GRAVITY applied as: velocity.y += GRAVITY * mult * delta  (NO * 60 factor)
const GRAVITY := 1980.0           # 0.55 px/frame² × 60² = 1980 px/s²
const HOLD_JUMP_GRAVITY_MULT := 0.35
const FALL_GRAVITY_MULT := 1.6
const JUMP_RELEASE_GRAVITY_MULT := 2.0
const APEX_GRAVITY_MULT := 0.4
const APEX_VELOCITY_THRESHOLD := 90.0   # 1.5 px/frame × 60
const MAX_FALL_SPEED := 840.0           # 14 px/frame × 60
const MAX_MOVE_SPEED := 390.0           # 6.5 px/frame × 60
const MOVE_ACCEL := 36.0               # 0.6 × 60
const AIR_ACCEL := 33.0                # 0.55 × 60
const GROUND_FRICTION := 0.72          # per-frame multiplier — unchanged
const AIR_FRICTION := 0.96             # per-frame multiplier — unchanged

# N++ ADDITIVE JUMP
const JUMP_IMPULSE := -600.0      # -10 px/frame × 60
const JUMP_MIN_VELOCITY := -780.0  # -13 × 60
const MAX_UPWARD_SPEED := -1080.0  # -18 × 60
const WALL_JUMP_IMPULSE_Y := -540.0 # -9 × 60
const WALL_JUMP_FORCE_X := 480.0   # 8 × 60
const WALL_SLIDE_SPEED := 72.0     # 1.2 × 60

# Dash
const DASH_SPEED := 1500.0         # feels good — fast but controllable
const DASH_DURATION := 0.133      # ~8 frames at 60fps
const MAX_AIR_DASHES := 2
const DASH_COOLDOWN := 0.25

# Forgiveness
const COYOTE_TIME := 0.167        # ~10 frames
const JUMP_BUFFER_TIME := 0.167

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

# Animation
var scarf_points: Array[Vector2] = []
var trail_positions: Array[Vector2] = []
var animated_sprite: AnimatedSprite2D = null
var _current_anim := ""

# Signals
signal died
signal collected_gold

func _ready() -> void:
	# Initialize scarf physics points
	for i in range(8):
		scarf_points.append(global_position + Vector2(-i * 4, 0))
	
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
	if is_on_floor():
		coyote_timer = COYOTE_TIME
		dash_count = MAX_AIR_DASHES
	
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
	if animated_sprite and _current_anim != anim:
		_current_anim = anim
		animated_sprite.play(anim)

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
		_play_anim("jump")
		return
	
	if Input.is_action_pressed("crouch") if InputMap.has_action("crouch") else false:
		_play_anim("crouch")
		return
	
	if abs(velocity.x) > 50:
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
	
	var skin = Color("#8B5E3C")      # dark brown skin
	var outfit = Color("#111111")     # black outfit
	var scarf_color = Color("#cc2244") # red scarf
	var hair = Color("#1a1a1a")       # near-black hair
	
	# Body offset (character center is at feet, collision is offset up)
	var oy = -28.0  # match collision shape center
	
	# Legs
	draw_rect(Rect2(-8, oy + 14, 6, 14), outfit)
	draw_rect(Rect2(2, oy + 14, 6, 14), outfit)
	
	# Torso
	draw_rect(Rect2(-10, oy - 6, 20, 22), outfit)
	
	# Arms
	var arm_swing = sin(Time.get_ticks_msec() * 0.008) * 3.0 if abs(velocity.x) > 50 else 0.0
	draw_rect(Rect2(-14, oy - 4 + arm_swing, 5, 16), skin)
	draw_rect(Rect2(9, oy - 4 - arm_swing, 5, 16), skin)
	
	# Head
	draw_circle(Vector2(0, oy - 14), 8.0, skin)
	
	# Eyes - white with dark pupils
	var eye_dir = facing_dir * 2.0
	draw_circle(Vector2(-3 + eye_dir, oy - 15), 2.0, Color.WHITE)
	draw_circle(Vector2(3 + eye_dir, oy - 15), 2.0, Color.WHITE)
	draw_circle(Vector2(-3 + eye_dir + facing_dir, oy - 15), 1.0, Color.BLACK)
	draw_circle(Vector2(3 + eye_dir + facing_dir, oy - 15), 1.0, Color.BLACK)
	
	# Ponytail
	var ponytail_base = Vector2(-facing_dir * 6, oy - 18)
	for i in range(5):
		var px = ponytail_base.x - facing_dir * i * 4
		var py = ponytail_base.y + i * 2 + sin(Time.get_ticks_msec() * 0.005 + i * 0.8) * 2
		draw_circle(Vector2(px, py), 3.0 - i * 0.3, hair)
	
	# Scarf (drawn from physics points)
	if scarf_points.size() > 1:
		for i in range(1, scarf_points.size()):
			var local_a = scarf_points[i - 1] - global_position
			var local_b = scarf_points[i] - global_position
			var width = 5.0 - i * 0.5
			draw_line(local_a, local_b, scarf_color, max(width, 1.0))
	
	# Dash trail
	if is_dashing:
		for i in range(trail_positions.size()):
			var local_pos = trail_positions[i] - global_position
			var alpha = float(i) / trail_positions.size() * 0.4
			draw_circle(local_pos + Vector2(0, oy), 10.0, Color(scarf_color, alpha))

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
	var player_center = global_position + Vector2(0, -28)
	var mouse_pos = get_global_mouse_position()
	var to_mouse = mouse_pos - player_center
	var dist_to_mouse = to_mouse.length()
	
	# Cap raycast to max grapple range
	var ray_end = player_center + to_mouse.normalized() * min(dist_to_mouse, GRAPPLE_MAX_LENGTH)
	
	# Raycast toward mouse — hit platforms (layer 1)
	var space = get_world_2d().direct_space_state
	var query = PhysicsRayQueryParameters2D.create(player_center, ray_end, 1)
	query.exclude = [self]
	var result = space.intersect_ray(query)
	
	if result and result.has("position"):
		var hit_pos: Vector2 = result["position"]
		var hit_dist = player_center.distance_to(hit_pos)
		if hit_dist > 20.0 and hit_dist <= GRAPPLE_MAX_LENGTH:
			is_grappling = true
			grapple_point = hit_pos
			grapple_length = hit_dist
			_spawn_grapple_particles(hit_pos)
			return
	
	# Fallback: nearest grapple_point anchor in range
	var nearest_dist := GRAPPLE_MAX_LENGTH
	var nearest_pos := Vector2.ZERO
	for gp in get_tree().get_nodes_in_group("grapple_points"):
		var d = player_center.distance_to(gp.global_position)
		if d < nearest_dist:
			nearest_dist = d
			nearest_pos = gp.global_position
	
	if nearest_pos != Vector2.ZERO:
		is_grappling = true
		grapple_point = nearest_pos
		grapple_length = nearest_dist
		_spawn_grapple_particles(nearest_pos)

func _spawn_jump_particles() -> void:
	_burst_particles(global_position + Vector2(0, 0), Color(0.7, 0.85, 1.0), 6, 80.0, 160.0)

func _spawn_wall_jump_particles() -> void:
	_burst_particles(global_position + Vector2(is_touching_wall * 12, -16), Color(0.9, 0.7, 1.0), 8, 100.0, 220.0)

func _spawn_dash_particles() -> void:
	# Warm red/amber trail matching Kaze's scarf color
	_burst_particles(global_position + Vector2(0, -28), Color(0.85, 0.25, 0.15), 12, 80.0, 220.0)

func _spawn_grapple_particles(pos: Vector2) -> void:
	_burst_particles(pos, Color(0.9, 0.3, 0.1), 6, 60.0, 140.0, 0.3)

func _spawn_death_particles() -> void:
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
