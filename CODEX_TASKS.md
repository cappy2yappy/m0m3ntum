# Codex Tasks — Sprite Cleanup & Level Polish

## Mission
Clean up all character sprites/animations and add tons of polish to the first 10 levels. Make the game feel tight, responsive, and satisfying.

---

## 🔥 IMMEDIATE FEEDBACK (March 9, 2026)

### Critical Issue #1: White Outline on All Sprites
**Reported by Cap after Windows build test.**

**Problem:** Every sprite has a weird white outline/fringe around it. This is anti-aliasing artifacts from the AI generation that weren't fully cleaned.

**Reference:** See `sprite_reference_labeled.png` in the repo root — all 40 frames laid out with labels (idle_0, run_5, jump_2, etc.)

**Fix Required:**
1. Open each strip in Aseprite (or Python/PIL)
2. Remove ALL white/light gray pixels (RGB > 240) on edges
3. Use alpha channel cleanup: any pixel with alpha < 255 that's near-white should be made fully transparent
4. Test in-game after each animation to verify no white fringe visible

**Python cleanup script template:**
```python
from PIL import Image
import numpy as np

def remove_white_outline(strip_path):
    img = Image.open(strip_path).convert("RGBA")
    arr = np.array(img)
    r, g, b, a = arr[:,:,0], arr[:,:,1], arr[:,:,2], arr[:,:,3]
    
    # Remove near-white fringe (R,G,B > 240, alpha < 255)
    white_fringe = (r > 240) & (g > 240) & (b > 240) & (a < 255)
    arr[white_fringe] = [0, 0, 0, 0]
    
    # Also remove very light pixels on edges (anti-alias remnants)
    light_pixels = (r > 220) & (g > 220) & (b > 220) & (a > 0) & (a < 200)
    arr[light_pixels] = [0, 0, 0, 0]
    
    cleaned = Image.fromarray(arr)
    cleaned.save(strip_path)
    print(f"Cleaned: {strip_path}")

# Run on all strips
for anim in ["idle", "run", "jump", "fall", "dash", "wall_slide", "crouch", "land"]:
    remove_white_outline(f"assets/sprites/kira/{anim}/strip.png")
```

### Critical Issue #2: Level Blocking Bugs
**Reported by Cap:** "There's still some things in the stages that don't allow you to proceed"

**Action Required:**
1. Playtest all 10 levels in order
2. Document which levels are broken and what's blocking
3. Common causes:
   - Grapple points out of range (upward-only constraint may have broken some)
   - Platforms placed too far apart
   - Required dash/combo not possible due to cooldowns
   - Missing grapple points that were assumed
4. Create a bug list in this file (add section below)
5. Fix each blocking issue and re-test

**To test:** Run the Windows build (builds/M0M3NTUM-Windows.exe) OR run in Godot editor (F5)

---

## 🐛 Level Blocking Bugs (To Be Documented by Codex)

### Template (fill this out as you test):
```
Level X: [LEVEL_NAME]
- Bug: [describe what blocks progression]
- Location: [platform coordinates or visual description]
- Cause: [grapple out of range / gap too wide / etc]
- Fix: [what needs to change]
- Status: [ ] Fixed / [ ] Testing / [x] Broken
```

### Level 1: AWAKENING
- Status: [ ] Needs testing

### Level 2: SAW GAUNTLET
- Status: [ ] Needs testing

### Level 3: LASER MAZE
- Status: [ ] Needs testing

### Level 4: CHAOS MIXTURE
- Status: [ ] Needs testing

### Level 5: VERTICAL ASCENT
- Status: [ ] Needs testing

### Level 6: GRAPPLE INTRO
- Status: [ ] Needs testing

### Level 7: MOMENTUM CHAIN
- Status: [ ] Needs testing

### Level 8: DASH AND GRAPPLE
- Status: [ ] Needs testing

### Level 9: THE ASCENT
- Status: [ ] Needs testing

### Level 10: FINAL GAUNTLET
- Status: [ ] Needs testing

---

## Priority 1: Sprite Cleanup

### Current Issues
- **WHITE OUTLINE/FRINGE** — ALL sprites have white anti-aliasing artifacts (see above for fix)
- **Source:** AI-generated sprite strips in `assets/sprites/kira/*/strip.png` have artifacts:
  - Inconsistent proportions between animations (jump/fall frames look bloated)
  - Isolated red scarf fragments in some frames
  - White streak artifacts in dash animation
  - Some frames have character at different vertical positions (causes visual "pop")

### Tasks

#### 1. Aseprite Cleanup Pipeline
- Install Aseprite (or use existing at `~/Library/Application Support/Steam/steamapps/common/Aseprite/Aseprite.app/Contents/MacOS/aseprite`)
- Load each strip PNG into Aseprite
- **Frame size:** 128×160 per frame
- **Style:** Modern 2D (smooth gradients, NOT pixel art)
- **Character design:** Dark skin, red diagonal sash (shoulder to hip), black outfit, white wrist wraps, barefoot, braided ponytail

#### 2. Per-Animation Cleanup

**idle (8 frames)**
- Current: breathing cycle with ping-pong loop
- Fix: Ensure character stays at consistent vertical position across all frames
- Add: Subtle blink animation on frame 4
- Export: `assets/sprites/kira/idle/strip.png`

**run (12 frames)**
- Current: full run cycle
- Fix: Remove any isolated scarf fragments between frames
- Polish: Add squash on ground contact frames (2, 8), stretch on air frames (5, 11)
- Export: `assets/sprites/kira/run/strip.png`

**jump (6 frames)**
- Current: launch → ascend → apex
- Fix: Normalize proportions (currently too bloated)
- Polish: Add anticipation crouch on frame 0, stretch on frames 2-3
- Export: `assets/sprites/kira/jump/strip.png`

**fall (3 frames)**
- Current: descent frames
- Fix: Match proportions to jump/idle
- Polish: Add wind-blown ponytail effect
- Export: `assets/sprites/kira/fall/strip.png`

**dash (5 frames)**
- Current: dash burst with motion blur
- Fix: Remove white streak artifacts
- Polish: Add speed lines, more pronounced lean
- Export: `assets/sprites/kira/dash/strip.png`

**wall_slide (2 frames)**
- Current: clinging to wall
- Fix: Already cleaned (gray wall removed)
- Polish: Add friction spark particles in code
- Export: `assets/sprites/kira/wall_slide/strip.png`

**crouch (1 frame)**
- Current: single static frame
- Fix: N/A (already simplified)
- Polish: Consider adding a slight squash effect
- Export: `assets/sprites/kira/crouch/strip.png`

**land (3 frames)**
- Current: impact recovery
- Fix: Normalize proportions
- Polish: Add big squash on frame 0, bounce recovery on frames 1-2
- Export: `assets/sprites/kira/land/strip.png`

#### 3. Animation Timing Adjustments

Update `scripts/kira_animations.gd` frame counts and FPS:

```gdscript
# Current FPS values might not match cleaned frame counts
# Verify and adjust after Aseprite cleanup
"idle":       { fps: 12 }   # breathing rhythm
"run":        { fps: 18 }   # snappy run
"jump":       { fps: 12 }   # quick launch
"fall":       { fps: 8  }   # slower fall
"dash":       { fps: 24 }   # fast burst
"wall_slide": { fps: 6  }   # slow cycle
"crouch":     { fps: 1  }   # static
"land":       { fps: 20 }   # quick recovery
```

---

## Priority 2: Level Polish (Levels 1-10)

### Visual Polish

#### Screen Shake
- **Current:** Basic shake on dash/grapple
- **Add to:**
  - Wall jump (2px shake, 4 frames)
  - Land from high fall (velocity-based shake, 3-8px)
  - Death (8px shake, 10 frames)
- **File:** `scripts/game_manager.gd` - enhance `trigger_screen_shake()`

#### Particle Effects
- **Jump particles:** Already exist, tune color to match city ambient (more amber)
- **Wall jump particles:** Add brick/dust clouds at contact point
- **Dash trail:** Make it fade smoother, add motion blur
- **Grapple rope:** Add visible rope line from player to grapple point (currently invisible)
- **Death explosion:** Bigger burst, more particles, red→white fade
- **File:** `scripts/player.gd` - `_spawn_*_particles()` functions

#### Platform Visuals
- **Current:** `platform_draw.gd` draws rooftop style platforms
- **Add:**
  - Subtle parallax on distant platforms (slight offset based on camera)
  - Edge highlights on grapple-able platforms (pulse amber when in range)
  - Crack patterns on platforms near saws (visual danger cue)
- **File:** `scripts/platform_draw.gd`

#### Hazard Polish
- **Saws:**
  - Add metallic glint on blade edge (rotating highlight)
  - Sparks on full rotation
  - Screen shake on player death (already exists, enhance)
- **Lasers:**
  - Pulsing glow intensity (sine wave)
  - Crackling particle emitter at laser source
  - Pre-fire warning flash (0.2s before laser activates)
- **File:** `scripts/game_manager.gd` - hazard drawing logic

### Audio Polish

#### New SFX (Procedural via `sfx_manager.gd`)
- **Wall slide:** Friction scrape (brown noise burst)
- **Combo trigger:** Rising chime (C→E→G notes, 0.1s each)
- **Combo reset:** Descending tone (sad trombone style)
- **Level complete:** Victory jingle (C→E→G→C progression)
- **Grapple swing:** Swoosh sound based on pendulum velocity
- **File:** `scripts/sfx_manager.gd` - add new `play_*()` functions

#### SFX Mixing
- Add volume falloff based on distance from player (z-axis simulation)
- Duck background ambience when dash/grapple sounds play
- **File:** `scripts/sfx_manager.gd`

### Level-Specific Polish

#### Level 1 (AWAKENING)
- **Goal:** Perfect tutorial feel
- Add text prompts: "Arrow keys to move", "Space to jump", "W to wall jump"
- Make first platform blink subtly (guide player's eye)
- Add golden particle trail showing optimal path

#### Level 2 (SAW GAUNTLET)
- Add saw blade shadows (depth cue)
- Pre-telegraph saw rotations (subtle arrow indicator)
- Victory screen shows "No deaths!" if completed first try

#### Level 3 (LASER MAZE)
- Add laser pre-fire warning (0.2s red flash before activation)
- Show laser patterns in minimap (top-right corner)
- Laser sound crescendo as it charges

#### Level 4 (CHAOS MIXTURE)
- Screen vignette darkens near hazards (danger proximity cue)
- Combo counter pulses when chain is active
- Death replay: ghost shows last 2 seconds before death

#### Level 5 (VERTICAL ASCENT)
- Camera looks ahead when wall jumping upward (anticipatory framing)
- Wall jump trail lingers longer (show your path)
- Top platform has glowing "goal" indicator

#### Level 6 (GRAPPLE INTRO)
- Grapple points pulse amber when in range (300px radius)
- First grapple point has arrow pointer
- Tutorial text: "Click to grapple" (if first grapple use)

#### Level 7 (MOMENTUM CHAIN)
- Combo counter front and center (move to screen center)
- Slow-mo on successful 3-move combo (0.7x speed, 0.5s)
- Level complete screen shows best combo chain

#### Level 8 (DASH AND GRAPPLE)
- Dash cooldown timer visible (radial indicator around player)
- Grapple rope renders as glowing red line
- Phantom trail shows last successful run (ghost replay)

#### Level 9 (THE ASCENT)
- Dynamic camera zoom based on speed (zoom out at high velocity)
- Checkpoint platforms glow blue (respawn here on death)
- Progress bar at top (% of level completed)

#### Level 10 (FINAL GAUNTLET)
- Everything from previous levels combined
- Boss music (placeholder: faster BPM in procedural audio)
- Victory fanfare on completion
- Stats screen: deaths, time, best combo, % of air time

---

## Priority 3: Animation State Machine Polish

### Current Issues
- State transitions can feel abrupt (crouch → run, land → jump)
- No animation blending (instant snap between states)

### Tasks

#### Add Transition Frames
- **crouch → idle:** Add 2-frame uncrouch transition
- **land → run:** Use frames 2-3 of land as blend into run
- **wall_slide → wall_jump:** Add 1-frame push-off anticipation

**File:** `scripts/player.gd` - `_update_animation()` function

#### Animation Priorities
Ensure state machine respects priority:
1. Death (highest)
2. Dash
3. Wall slide
4. Crouch
5. Land (only if just landed)
6. Jump/Fall (airborne)
7. Run (moving on ground)
8. Idle (stationary)

**File:** `scripts/player.gd` - reorder conditions in `_update_animation()`

---

## Priority 4: Camera Polish

### Current Behavior
- 1.5x zoom, smooth follow with lerp

### Enhancements

#### Dynamic Zoom
- Zoom out to 1.3x when moving fast (velocity > 500 px/s)
- Zoom in to 1.7x when wall sliding (emphasize precision)
- Smooth zoom transitions (0.2s lerp)

#### Look-Ahead
- Camera leads player when dashing (offset 50px in dash direction)
- Camera looks up when grappling (offset 80px above player)
- Camera centers on player when idle

**File:** `scripts/game_manager.gd` - camera update logic in `_process()`

---

## Priority 5: UI/HUD Polish

### Current HUD
- Level name (top-left)
- Timer (top-center)
- Combo counter (top-right)
- Death count

### Enhancements

#### Combo UI
- Make combo counter larger when active
- Add decay bar (1.5s window visual)
- Floating "+1 WALL JUMP" text on combo trigger
- Combo break sound + red flash

#### Timer
- Color-code timer: green (fast), yellow (average), red (slow)
- Ghost time shows best time for this level
- Split times show +/- vs best run

#### Death Counter
- Animate on increment (bounce effect)
- Show skull icon next to number
- Flash red on death

**File:** `scripts/game_manager.gd` - HUD drawing in `_process()`

---

## Priority 6: Testing & Iteration

### Playtest Each Level
After all polish is applied:
1. Complete each level 3 times
2. Verify all grapple points are reachable
3. Check for "cheese" routes (unintended skips)
4. Ensure combo system triggers correctly
5. Verify no visual glitches on state transitions

### Balance Pass
- Levels 1-3: Should feel easy (max 5 deaths on first try)
- Levels 4-6: Medium difficulty (5-15 deaths acceptable)
- Levels 7-9: Hard (15-30 deaths expected)
- Level 10: Gauntlet (30+ deaths, designed to test mastery)

---

## Tools & Resources

### Aseprite
- **Mac Path:** `~/Library/Application Support/Steam/steamapps/common/Aseprite/Aseprite.app/Contents/MacOS/aseprite`
- **CLI Export:** `aseprite -b input.ase --save-as output.png`
- **Frame size:** 128×160
- **Transparent background:** RGBA mode

### Godot Editor
- **Version:** 4.6.1
- **Project Path:** `/Users/cappy/.openclaw/workspace/projects/ninja-escape/godot-project/`
- **Test Run:** Open in Godot, press F5

### Reference Materials
- **GDD.md** - Full design document with physics constants
- **README.md** - Setup instructions
- **N++ (game)** - Reference for apex hang time, flow state
- **Celeste (game)** - Reference for screen shake, particle polish

---

## Success Criteria

### Sprites
- [ ] All 8 animations cleaned and consistent
- [ ] No visual artifacts (gray backgrounds, white streaks, scarf fragments)
- [ ] Consistent proportions across all animations
- [ ] Character stays at consistent vertical position in animations
- [ ] Smooth transitions between animation states

### Level Polish
- [ ] Every level has unique visual identity
- [ ] Screen shake feels impactful but not disorienting
- [ ] Particles add juice without cluttering screen
- [ ] Hazards have clear visual tells (pre-fire warnings, danger proximity)
- [ ] Grapple rope is visible and satisfying

### Audio
- [ ] 5+ new procedural SFX added
- [ ] Sound mixing doesn't clip or distort
- [ ] Audio cues match visual feedback timing

### Camera
- [ ] Dynamic zoom feels natural, not jarring
- [ ] Look-ahead guides player's eye during fast movement
- [ ] Camera never clips through platforms or goes off-screen

### Feel
- [ ] Game feels snappy, responsive, tight
- [ ] Every action has satisfying feedback (visual + audio)
- [ ] Levels flow smoothly with clear optimal paths
- [ ] Deaths feel fair (clear what killed you, instant respawn)

---

## Deliverables

When complete, commit all changes to the GitHub repo:

```bash
git add -A
git commit -m "Polish pass: cleaned sprites, enhanced animations, added visual/audio feedback to all 10 levels"
git push
```

Then post in Discord:
- Screenshot of before/after sprite comparison (idle animation)
- Short video clip showing level polish (screen shake, particles, camera)
- Playtime stats (deaths per level, completion time)

---

**Estimated Time:** 6-10 hours of focused work

**Priority Order:** Sprites → Level 1-3 polish → Audio → Levels 4-10 → Camera → Final testing
