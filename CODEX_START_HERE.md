# Start Here — Codex Onboarding

Welcome to M0M3NTUM! This guide will get you set up and working on the sprite cleanup + level fixes.

## Quick Start

### 1. Read These Files First
- **GDD.md** — Full game design document (10 pages)
- **CODEX_TASKS.md** — Your task list (start with "IMMEDIATE FEEDBACK" section at top)
- **sprite_reference_labeled.png** — All 40 sprite frames laid out with labels

### 2. The Two Critical Issues Right Now

**Issue #1: White Outline on Sprites**
- Every sprite frame has white anti-aliasing fringe
- See `sprite_reference_labeled.png` for visual reference
- Fix: Python script in CODEX_TASKS.md removes all near-white pixels
- Test after cleanup: run game in Godot (F5) and verify no white edges

**Issue #2: Level Blocking Bugs**
- Some levels can't be completed (progression blocked)
- Playtest all 10 levels, document bugs in CODEX_TASKS.md
- Common cause: grapple points out of range after upward-only constraint
- Fix level data in `levels/level_data.json`

### 3. Your Workflow

```bash
# Pull latest
git pull

# Make changes (sprite cleanup, level fixes, etc)
# Test in Godot: open godot-project/project.godot, press F5

# Commit when done
git add -A
git commit -m "Fix: removed white outline from all sprites + fixed Level X blocking bug"
git push

# Notify in Discord when major milestones done
```

### 4. Testing the Game

**Option A: Godot Editor (Recommended)**
```bash
open godot-project/project.godot  # Opens in Godot
# Press F5 to run
# Press F6 to run current scene
```

**Option B: Windows Build**
```bash
# Extract builds/M0M3NTUM-Windows.zip
# Run M0M3NTUM-Windows.exe
```

### 5. Key Files You'll Edit

**Sprite Cleanup:**
- `assets/sprites/kira/*/strip.png` — 8 animation strips
- `sprite_reference_labeled.png` — Your visual reference
- Run Python script from CODEX_TASKS.md to clean

**Level Fixes:**
- `levels/level_data.json` — All level layouts
- `scripts/level_loader.gd` — How levels load
- `scripts/game_manager.gd` — Hazard/grapple point spawning

**Polish (later):**
- `scripts/player.gd` — Character controller, particles
- `scripts/city_background.gd` — Background visuals
- `scripts/platform_draw.gd` — Platform rendering
- `scripts/sfx_manager.gd` — Procedural audio

### 6. Git Etiquette

- Commit often (every logical change)
- Use clear commit messages: "Fix: white outline removed from idle/run/jump sprites"
- Push when you're confident (don't push broken builds)
- Tag Cappy in Discord when you need design input

### 7. Physics Constants (Read-Only)

**DO NOT CHANGE** without asking Cap or Cappy first:
- Gravity multipliers (tuned to N++/Celeste feel)
- Dash speed/duration
- Grapple range
- Jump impulse values
- Coyote time / jump buffer

These are in `scripts/player.gd` lines 12-45.

### 8. When You're Stuck

- **Design questions:** Ask Cap or Cappy in Discord
- **Bug questions:** Check `scripts/player.gd` for player logic
- **Level balance:** Reference GDD.md "Level Design Philosophy"
- **Sprite style:** Reference GDD.md "Visual Design" section

### 9. Success Criteria

**Before you mark yourself done:**
- [ ] All 40 sprite frames have NO white outline
- [ ] All 10 levels are completable (tested personally)
- [ ] Game runs in Godot without errors
- [ ] Windows build exports successfully
- [ ] Changes pushed to GitHub

---

## Priority Order (from CODEX_TASKS.md)

1. **Remove white outline** from all sprites (Python script provided)
2. **Playtest all 10 levels** and document blocking bugs
3. **Fix level blocking bugs** (adjust platform positions / grapple points)
4. **Re-export Windows build** and test
5. Move on to polish tasks (screen shake, particles, etc)

---

## Repo Structure

```
godot-project/
├── CODEX_START_HERE.md        ← You are here
├── CODEX_TASKS.md              ← Your full task list
├── GDD.md                      ← Game design doc
├── sprite_reference_labeled.png ← Visual reference
├── project.godot               ← Godot project file
├── assets/
│   └── sprites/kira/           ← Sprite strips (8 animations)
├── levels/
│   └── level_data.json         ← All level layouts
├── scripts/
│   ├── player.gd               ← Character controller
│   ├── game_manager.gd         ← Level system
│   └── ...
├── scenes/
│   ├── game.tscn               ← Main game scene
│   └── player.tscn             ← Player scene
└── builds/
    └── M0M3NTUM-Windows.zip    ← Current Windows build
```

---

**Questions?** Tag @Cappy in Discord: `#nj-momentum-platformer`

Good luck! 🚀
