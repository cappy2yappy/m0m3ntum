# M0M3NTUM — Game Design Document

**Genre:** 2D Momentum-Based Precision Platformer  
**Inspirations:** N++, Celeste, Dead Cells, Mark of the Ninja  
**Platform:** Web (HTML5) + Desktop (Godot 4.6)  
**Target:** Players who love flow-state movement and mastery curves  

---

## Core Vision

**"Out of control in the best way."**

M0M3NTUM is about the feeling you get when movement becomes second nature — when wall jumps, dashes, and grapples chain together into an unbroken flow. Every mechanic rewards forward momentum. Death is instant, respawn is instant. No friction between you and the next attempt.

### Pillars
1. **Flow State** — Mechanics encourage continuous motion, not stop-and-go gameplay
2. **Mastery** — Easy to learn, endless skill ceiling (combo system rewards optimization)
3. **Instant Feedback** — No death animations, no long respawns, no punishment for experimentation

---

## Character

### Kaze (Playable Character)
- **Design:** Athletic ninja, dark skin, red diagonal sash (shoulder to hip), black outfit, white wrist wraps, barefoot, braided ponytail
- **Proportions:** Samus Dread-inspired — tall, athletic build (~1/5 screen height)
- **Personality (implied through movement):** Precise, fluid, always in motion

**Art Style:** Modern 2D with smooth gradients and bezier curves. NOT pixel art. Think Metroid Dread meets Celeste's color palette.

---

## Core Mechanics

### Movement
- **Run:** Ground movement with tight acceleration (42 px/s²)
- **Jump:** Variable height (hold for floaty apex, release for snappy short hop)
- **Wall Slide:** Automatically triggers on wall contact while airborne
- **Wall Jump:** Strong horizontal + vertical kick (510 px/s horizontal, -600 px/s vertical)
- **Crouch:** Instant single-frame snap (cosmetic, no gameplay effect yet)

### Advanced Mechanics

#### Dash
- **Speed:** 1600 px/s
- **Duration:** 0.12 seconds (~7 frames)
- **Air Dashes:** 1 per jump (resets on landing or wall touch)
- **Cooldown:** 0.2 seconds
- **Direction:** 8-way (arrow keys or WASD input)

**Design Note:** Dash is a burst tool, not a crutch. Limited to 1 air dash forces players to use it strategically.

#### Grapple Hook (Spider-Man Rule)
- **Range:** 300 pixels
- **Constraint:** Can ONLY grapple ABOVE the player (y < player_center.y)
- **Behavior:** 
  - Fires toward mouse/touch position
  - Snaps to nearest platform edge within range
  - If aim is below player, redirects upward automatically
  - Release to detach
- **Physics:** Pendulum swing maintains momentum

**Design Note:** Upward-only constraint turns grapple into a repositioning tool, not a safety net. Encourages using it to maintain air time, not escape falls.

#### Combo System
- **Trigger Actions:** Wall jump, dash, grapple
- **Window:** 1.5 seconds between actions
- **Reset:** Touching ground resets combo counter
- **Feedback:** 
  - Floating text popups on each action
  - Decay bar shows remaining combo window
  - No gameplay effect (yet) — purely for score/mastery tracking

---

## Physics Constants

All values tuned after analyzing N++, Celeste, and Dead Cells:

```gdscript
# Gravity Multipliers
GRAVITY = 1980.0 px/s²
HOLD_JUMP_GRAVITY_MULT = 0.28    # Very floaty on jump hold (N++ style)
FALL_GRAVITY_MULT = 1.8          # Heavy fall for snappy rhythm
JUMP_RELEASE_GRAVITY_MULT = 2.2  # Quick short hop on release
APEX_GRAVITY_MULT = 0.25         # Big apex hang time (N++ key feel)
APEX_VELOCITY_THRESHOLD = 120.0  # Wide apex window

# Movement
MAX_MOVE_SPEED = 420.0 px/s
MOVE_ACCEL = 42.0 px/s²
AIR_ACCEL = 30.0 px/s²
GROUND_FRICTION = 0.70           # Per-frame multiplier
AIR_FRICTION = 0.97              # Preserve air momentum

# Jump
JUMP_IMPULSE = -630.0 px/s
WALL_JUMP_IMPULSE_Y = -600.0 px/s
WALL_JUMP_FORCE_X = 510.0 px/s
WALL_SLIDE_SPEED = 60.0 px/s

# Forgiveness (Celeste-level generosity)
COYOTE_TIME = 0.2 seconds        # Jump after leaving ledge
JUMP_BUFFER_TIME = 0.2 seconds   # Jump input before landing
```

**Key Insight from N++:** The floaty apex (0.25 gravity mult) combined with heavy fall gravity (1.8x) creates that signature "out of control" flow feeling. Players spend more time at peak height, making it easier to line up precise wall jumps or grapples.

---

## Level Design Philosophy

### Flow Over Puzzle
Levels are designed as **momentum courses**, not obstacle gauntlets. The optimal path should feel like a speedrun even on first attempt.

### Guiding Principles
1. **Never punish forward motion** — No dead ends, no backtracking required
2. **Grapple points are waypoints** — Place them to guide the natural arc of movement
3. **Rhythm over reaction** — Hazards should be predictable (saws, lasers), not random
4. **Multiple paths** — Let players choose: safe route vs. risky combo route

### Current Levels (10 total)
1. **AWAKENING** — Tutorial: run, jump, wall jump
2. **SAW GAUNTLET** — Rotating hazards, timing practice
3. **LASER MAZE** — Vertical movement, wall jumps
4. **CHAOS MIXTURE** — Combines saws + lasers
5. **VERTICAL ASCENT** — Wall climb challenge
6. **GRAPPLE INTRO** — First grapple points
7. **MOMENTUM CHAIN** — Combo tutorial (wall jump → dash → grapple)
8. **DASH AND GRAPPLE** — Advanced combo challenge
9. **THE ASCENT** — Vertical gauntlet with all mechanics
10. **FINAL GAUNTLET** — Everything at once

---

## Visual Design

### Art Direction
- **Style:** Modern 2D (smooth gradients, bezier limbs, anime-style face)
- **Palette:** Warm red/amber (`#cc2222` sash, `#e8442a` UI accent)
- **Background:** Procedural night city
  - 3-layer parallax (far/mid/near buildings)
  - Glowing windows, blinking antenna lights
  - Fog at ground level
- **Platforms:** Stylized rooftop ledges
  - Dark stone texture with grain/crack lines
  - Amber-lit top edge
  - Torch brackets with flicker glow
  - Animated ember particles

### Animation
- **Frame Rate:** 12-24fps playback (game runs at 60fps)
- **Animations:** idle, run, jump, fall, dash, wall_slide, crouch, land
- **Frame Size:** 128×160 per frame, scaled to fit hitbox

**Current Implementation:** Canvas-drawn procedural character (bezier limbs, radial skin gradients). Sprite strips exist but are placeholders from AI generation — need proper Aseprite cleanup/redraw.

---

## Audio Design (Procedural)

All sounds generated via `AudioStreamGenerator` (no audio file dependencies):

- **Jump:** Quick chirp (200-400Hz sweep)
- **Wall Jump:** Higher pitch + noise burst
- **Dash:** Bass thump (80Hz) + whoosh noise
- **Land:** Impact based on fall velocity
- **Grapple Fire:** High-pitched zing (600Hz sweep)
- **Grapple Release:** Snap sound
- **Gold Collect:** Pleasant chime
- **Death:** Descending tone

---

## Technical Stack

### Web Version (HTML5 Prototype)
- **Canvas 2D API** for rendering
- **Pure JavaScript** physics (60fps fixed timestep)
- **Deployment:** `laibyrinth.com/m0m3ntum.html`

### Desktop Version (Primary Build)
- **Engine:** Godot 4.6.1
- **Language:** GDScript
- **Resolution:** 800×500 canvas (4:2.5 aspect ratio)
- **Camera:** 1.5x zoom, smooth follow

### Key Scripts
- `player.gd` — Character controller, physics, animation state machine
- `game_manager.gd` — Level loading, HUD, combo tracking
- `kira_animations.gd` — Sprite frame loader
- `city_background.gd` — Procedural parallax background
- `platform_draw.gd` — Stylized platform visuals
- `sfx_manager.gd` — Procedural audio synthesis

---

## Progression & Replayability

### Progression
- Linear level sequence (1-10)
- Each level unlocks on completion
- Best times saved to localStorage (HTML) / user preferences (Godot)

### Mastery Hooks
- **Time Trials:** Beat developer times
- **Combo Challenges:** Complete levels with X+ combo chain
- **Gold Collection:** Optional pickups (cosmetic/score only)
- **Ghost Replays:** Race against your best time (planned)

---

## Current Status

### Completed
- ✅ Core movement (run, jump, wall jump, dash, grapple)
- ✅ Physics tuned to N++/Celeste feel
- ✅ Combo system (tracking, UI, reset logic)
- ✅ 10 levels with hazards (saws, lasers)
- ✅ Procedural SFX
- ✅ Parallax city background
- ✅ HTML + Godot prototypes in sync
- ✅ Grapple upward-only constraint
- ✅ Crouch animation fixed (1-frame snap)
- ✅ Sprite artifact cleanup (gray backgrounds removed)

### In Progress
- 🔄 Aseprite sprite cleanup (AI-generated placeholders → hand-polished frames)
- 🔄 GitHub repo setup for collaborative development
- 🔄 Level design iteration (flow polish, grapple point placement)

### Next Up
- [ ] Ghost replay system (race your best time)
- [ ] More hazards (spikes, moving platforms, crushers)
- [ ] Character unlock system (Dash, Shade, Captain Flint, Takashi from GDD)
- [ ] Combo rewards (visual flair, screen shake intensity scaling)
- [ ] Leaderboard integration (web version)
- [ ] Mobile touch controls polish
- [ ] Godot export to macOS/Windows/Linux
- [ ] Steam page setup

---

## Design Lessons Learned

### What Works
- **Apex hang time** — Players intuitively time wall jumps better with the floaty peak
- **Upward grapple constraint** — Removed cheese strats, made grapple a repositioning tool
- **1 air dash** — Forced more skillful play than 2 dashes
- **Instant respawn** — No death animation = no frustration, just retry
- **Combo window 1.5s** — Long enough to chain moves, tight enough to feel skilled

### What Doesn't Work
- **Multi-frame crouch animation** — Godot 4.6 non-looping animations glitch on state transitions
- **Grapple in any direction** — Made levels feel broken/cheesable
- **2 air dashes** — Too forgiving, removed skill expression
- **Land animation interrupt** — Caused input drops, removed for responsiveness

---

## Monetization (Future)

### Web Version
- Free to play at `laibyrinth.com/m0m3ntum.html`
- Optional cosmetic skins (character colors, dash trails)
- "Buy me a coffee" link

### Desktop Version
- **Steam:** $4.99
- **itch.io:** Pay-what-you-want ($3 suggested)
- Includes all future content updates

---

## Contact & Links

- **Live Demo:** [laibyrinth.com/m0m3ntum.html](https://laibyrinth.com/m0m3ntum.html)
- **Developer:** Cappy (AI dev assistant) + Cap (Tony Santiago)
- **Support:** support@laibyrinth.com

---

**Last Updated:** March 8, 2026  
**Version:** 0.7 (Pre-Alpha)
