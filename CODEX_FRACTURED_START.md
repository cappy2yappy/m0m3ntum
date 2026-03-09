# Codex: FRACTURED Combat Prototype

**Mission:** Build combat prototype for MOMENTUM: FRACTURED roguelite.

---

## Phase 1: Project Setup (Week 1 Day 1)

### 1. Create New Project

```bash
cd ~/Documents/Playground
mkdir momentum-fractured
cd momentum-fractured
git init
git remote add origin https://github.com/cappy2yappy/m0m3ntum.git
```

### 2. Initialize Godot Project

Create `project.godot`:
```ini
config_version=5

[application]

config/name="MOMENTUM: FRACTURED"
config/version="0.1.0-alpha"
run/main_scene="res://scenes/combat_test.tscn"
config/features=PackedStringArray("4.6", "Forward Plus")
config/icon="res://icon.svg"

[display]

window/size/viewport_width=800
window/size/viewport_height=500
window/size/resizable=true
window/stretch/mode="viewport"

[input]

move_left={
"deadzone": 0.5,
"events": [Object(InputEventKey,"resource_local_to_scene":false,"resource_name":"","device":-1,"window_id":0,"alt_pressed":false,"shift_pressed":false,"ctrl_pressed":false,"meta_pressed":false,"pressed":false,"keycode":0,"physical_keycode":4194319,"key_label":0,"unicode":0,"location":0,"echo":false,"script":null)
, Object(InputEventKey,"resource_local_to_scene":false,"resource_name":"","device":-1,"window_id":0,"alt_pressed":false,"shift_pressed":false,"ctrl_pressed":false,"meta_pressed":false,"pressed":false,"keycode":0,"physical_keycode":65,"key_label":0,"unicode":97,"location":0,"echo":false,"script":null)
]
}
move_right={
"deadzone": 0.5,
"events": [Object(InputEventKey,"resource_local_to_scene":false,"resource_name":"","device":-1,"window_id":0,"alt_pressed":false,"shift_pressed":false,"ctrl_pressed":false,"meta_pressed":false,"pressed":false,"keycode":0,"physical_keycode":4194321,"key_label":0,"unicode":0,"location":0,"echo":false,"script":null)
, Object(InputEventKey,"resource_local_to_scene":false,"resource_name":"","device":-1,"window_id":0,"alt_pressed":false,"shift_pressed":false,"ctrl_pressed":false,"meta_pressed":false,"pressed":false,"keycode":0,"physical_keycode":68,"key_label":0,"unicode":100,"location":0,"echo":false,"script":null)
]
}
jump={
"deadzone": 0.5,
"events": [Object(InputEventKey,"resource_local_to_scene":false,"resource_name":"","device":-1,"window_id":0,"alt_pressed":false,"shift_pressed":false,"ctrl_pressed":false,"meta_pressed":false,"pressed":false,"keycode":0,"physical_keycode":32,"key_label":0,"unicode":32,"location":0,"echo":false,"script":null)
]
}
dodge={
"deadzone": 0.5,
"events": [Object(InputEventKey,"resource_local_to_scene":false,"resource_name":"","device":-1,"window_id":0,"alt_pressed":false,"shift_pressed":false,"ctrl_pressed":false,"meta_pressed":false,"pressed":false,"keycode":0,"physical_keycode":4194325,"key_label":0,"unicode":0,"location":0,"echo":false,"script":null)
]
}
attack={
"deadzone": 0.5,
"events": [Object(InputEventMouseButton,"resource_local_to_scene":false,"resource_name":"","device":-1,"window_id":0,"alt_pressed":false,"shift_pressed":false,"ctrl_pressed":false,"meta_pressed":false,"button_mask":1,"position":Vector2(0, 0),"global_position":Vector2(0, 0),"factor":1.0,"button_index":1,"canceled":false,"pressed":false,"double_click":false,"script":null)
]
}

[physics]

2d/default_gravity=1980.0
```

### 3. Port M0M3NTUM Physics

Copy these files from M0M3NTUM:
- `scripts/player.gd` → rename to `scripts/kaze_base.gd`
- Keep physics constants (GRAVITY, JUMP, DASH, etc)
- Remove grapple code (will add back later as ability upgrade)

**Modifications needed:**
- Remove AnimatedSprite2D dependency (use placeholder ColorRect first)
- Remove combo system (not needed yet)
- Remove level loading logic
- Keep: movement, wall jump, dash, basic physics

### 4. Create Combat System

**File: `scripts/combat/hitbox.gd`**
```gdscript
extends Area2D
class_name Hitbox

@export var damage: float = 10.0
@export var knockback: Vector2 = Vector2(200, -100)
@export var hit_stun: float = 0.2
@export var team: int = 0  # 0 = player, 1 = enemy

signal hit_landed(target: Node2D)

func _ready():
	area_entered.connect(_on_area_entered)

func _on_area_entered(area: Area2D):
	if area is Hurtbox and area.team != team:
		area.take_hit(damage, knockback, hit_stun)
		hit_landed.emit(area.owner)
```

**File: `scripts/combat/hurtbox.gd`**
```gdscript
extends Area2D
class_name Hurtbox

@export var health_component: Node
@export var team: int = 0

signal hit_received(damage: float, knockback: Vector2)

func take_hit(damage: float, knockback: Vector2, stun: float):
	hit_received.emit(damage, knockback)
	if health_component:
		health_component.take_damage(damage)
```

**File: `scripts/combat/health.gd`**
```gdscript
extends Node
class_name Health

@export var max_health: float = 100.0
var current_health: float

signal health_changed(current: float, max: float)
signal died

func _ready():
	current_health = max_health

func take_damage(amount: float):
	current_health -= amount
	health_changed.emit(current_health, max_health)
	if current_health <= 0:
		died.emit()

func heal(amount: float):
	current_health = min(current_health + amount, max_health)
	health_changed.emit(current_health, max_health)
```

---

## Phase 2: Kaze Combat Implementation

### Kaze Melee System

**File: `scripts/player/kaze_combat.gd`**

Extends `kaze_base.gd` (ported M0M3NTUM player)

**New features:**
1. **Light Attack Combo** (3 hits)
   - Click = slash forward
   - Click again within 0.5s = second slash
   - Third click = launcher (pops enemy up)

2. **Heavy Attack** (hold click)
   - Charge for 0.5s
   - Release = overhead slam (AoE)

3. **Dash-Strike**
   - Dash + Attack = dash through with sword extended
   - I-frames during dash
   - Damage all enemies in path

4. **Dodge Roll**
   - Shift key = roll in movement direction
   - I-frames (0.3s)
   - Cooldown 1s

**Pseudo-code structure:**
```gdscript
var combo_count: int = 0
var combo_timer: float = 0.0
var is_attacking: bool = false
var attack_cooldown: float = 0.0

func _process(delta):
	# Update combo timer
	if combo_timer > 0:
		combo_timer -= delta
		if combo_timer <= 0:
			combo_count = 0
	
	# Handle attack input
	if Input.is_action_just_pressed("attack") and not is_attacking:
		_perform_attack()

func _perform_attack():
	combo_count += 1
	combo_timer = 0.5  # Reset combo window
	is_attacking = true
	
	match combo_count:
		1: _light_attack_1()
		2: _light_attack_2()
		3: _launcher_attack()
		_: combo_count = 1; _light_attack_1()

func _light_attack_1():
	# Spawn hitbox in front of player
	# Animation: quick horizontal slash
	# Damage: 10
	# Duration: 0.2s
	pass

func _light_attack_2():
	# Second slash, slightly stronger
	# Damage: 12
	# Duration: 0.25s
	pass

func _launcher_attack():
	# Overhead slam, knocks enemy up
	# Damage: 15
	# Knockback: Vector2(0, -300)
	# Resets combo
	pass
```

---

## Phase 3: First Enemy (Echo)

**File: `scripts/enemies/echo.gd`**

**Behavior:**
- Patrol between two points
- When player in range (200px): charge attack
- Attack: melee lunge (30 damage)
- Health: 50 HP
- No special abilities (basic enemy)

**AI States:**
1. IDLE - standing still
2. PATROL - walking back and forth
3. ALERT - saw player, turning to face
4. CHARGE - running at player
5. ATTACK - melee lunge
6. HITSTUN - just got hit, can't act
7. DEAD - play death animation, despawn

**State Machine:**
```gdscript
enum State { IDLE, PATROL, ALERT, CHARGE, ATTACK, HITSTUN, DEAD }
var state: State = State.PATROL

func _physics_process(delta):
	match state:
		State.PATROL: _state_patrol(delta)
		State.ALERT: _state_alert(delta)
		State.CHARGE: _state_charge(delta)
		State.ATTACK: _state_attack(delta)
		State.HITSTUN: _state_hitstun(delta)
```

---

## Phase 4: Combat Test Scene

**File: `scenes/combat_test.tscn`**

**Setup:**
- Flat platform (800×20 px)
- Kaze spawn at (100, 400)
- 3 Echo enemies at (300, 400), (500, 400), (700, 400)
- Simple arena boundaries

**Goal:** Test combat feel
- Hit 3 enemies, confirm combo works
- Dodge their attacks
- Feel if combat is satisfying

---

## Success Criteria (Week 1)

- [ ] Kaze can run, jump, dash (M0M3NTUM physics)
- [ ] Kaze can perform 3-hit combo
- [ ] Kaze can dodge roll with i-frames
- [ ] Echo enemy patrols and attacks
- [ ] Echo takes damage and dies
- [ ] Hit feedback feels good (screen shake, particle burst)
- [ ] No bugs, runs at 60fps

---

## Commands to Run

```bash
# After creating all files
cd ~/Documents/Playground/momentum-fractured
git add -A
git commit -m "Initial commit: combat prototype setup

- Ported M0M3NTUM physics (Kaze base movement)
- Created combat system (Hitbox, Hurtbox, Health)
- Implemented Kaze 3-hit combo + dodge roll
- Created Echo enemy (basic AI + patrol)
- Combat test scene ready

Next: playtesting combat feel"

git push -u origin main
```

---

## Files to Create

```
momentum-fractured/
├── project.godot
├── scenes/
│   └── combat_test.tscn
├── scripts/
│   ├── player/
│   │   ├── kaze_base.gd         # Ported M0M3NTUM physics
│   │   └── kaze_combat.gd       # Combat system
│   ├── enemies/
│   │   └── echo.gd               # First enemy
│   └── combat/
│       ├── hitbox.gd
│       ├── hurtbox.gd
│       └── health.gd
└── README.md
```

---

## Deliverable (End of Week 1)

Record 30-second video:
- Kaze performs 3-hit combo on Echo
- Dodge roll through Echo's attack
- Kill Echo, confirm death

Post in Discord `#momentum-fractured` thread.

---

**Questions? Check:**
- FRACTURED_GDD.md for full game design
- M0M3NTUM code for physics reference
- Ask Cappy in Discord for design decisions
