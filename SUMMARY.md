# M0M3NTUM — MVP Build Summary

**Built:** 2026-02-27  
**Status:** Feature-complete MVP — all 5 systems implemented

---

## What Was Built

### 1. Time Trial System ✅
- `scripts/time_trial_manager.gd` — new script
- Saves best times per level to `user://momentum_records.cfg` (ConfigFile)
- Grades (S/A/B/C) calculated from time + deaths, also persisted
- HUD shows **current time** (formatted as `s.cs` or `m:ss.cs`) plus **Best: ---** label
- "**★ NEW BEST! ★**" label flashes with pulse animation for 2.8s when a new record is set

### 2. Ghost Replay System ✅
- `scripts/ghost_player.gd` — new script
- Records player `(x, y, facing)` every 3 frames during a run
- Ghost data saved alongside best times to `user://momentum_ghosts.cfg`
- On next attempt, a semi-transparent blue ghost (Node2D with `_draw`) replays the best-time path
- Ghost resets on each respawn and runs in sync with the player timer
- Ghost drawn at z_index -2 (always behind player)

### 3. Level Complete Screen ✅
- Triggered when all gold is collected (existing mechanic)
- Semi-transparent overlay with centered panel showing:
  - Level name
  - Big grade letter (S/A/B/C) color-coded (gold/green/blue/grey)
  - Current time, best time, deaths, gold collected
  - "✦ PERFECT RUN ✦" banner when deaths == 0
- Buttons: **RETRY**, **NEXT →** (or SELECT if last level), **☰ LEVELS**

### 4. Level Select Screen ✅
- Opens with `level_select` input action (previously just cycled levels) or via level complete screen
- Full-screen overlay with 3-column grid of level cards
- Each card shows: level number + name, best time, grade badge, PLAY button
- Levels beyond the first uncompleted level show "🔒 LOCKED"
- Close with ✕ BACK button or pressing `level_select` again

### 5. Juice / Feel Improvements ✅
- **Death particles:** 18-particle red burst + 8-particle dark red burst at player center on death
- **Gold collect particles:** 14-particle yellow sparkle burst when coin collected (in `gold.gd`)
- **Screen flash:** Full-screen red ColorRect overlay fades from 0.48 alpha in 0.22s on death
- **Jump/wall jump/dash particles:** Colored bursts on each movement action
- **"PERFECT RUN" text** shown in level complete screen when deaths == 0

---

## Files Changed / Created

| File | Status |
|------|--------|
| `scripts/time_trial_manager.gd` | **NEW** |
| `scripts/ghost_player.gd` | **NEW** |
| `scripts/game_manager.gd` | **REWRITTEN** (v2) |
| `scripts/player.gd` | Updated (particle methods added) |
| `scripts/gold.gd` | Updated (`_spawn_collect_particles()` added) |

---

## Known Gaps / Polish Needed

1. **No exit tile** — level complete still triggers on all-gold-collected, not reaching an exit marker. Add `exit` object to level_data.json if you want a physical exit.
2. **Ghost sync at non-60fps** — ghost tick counts process frames (not time-based), so at 30fps the ghost runs at half speed. Fix: use accumulated delta time for ghost tick instead of frame count.
3. **No transition animation** — level complete panel pops in instantly. A tween-in scale/fade would feel nicer.
4. **Level select layout** — uses default Godot theme. Custom styled boxes (colored borders, hover states) would look much better.
5. **Sound** — no audio at all. SFX for jump, death, gold collect, level complete would massively improve feel.
6. **Grade thresholds** — currently hardcoded (S = <30s + 0 deaths). Per-level thresholds based on expected completion time would be more fair.
7. **Ghost doesn't show on very first run** — by design (nothing to replay), but an on-screen hint "Complete a run to see your ghost!" would help.
8. **Particle cleanup** — particles created via `get_parent().add_child()` survive level restarts. They'll auto-free after lifetime but a level reload could briefly show stale particles. Low priority.
9. **Death timer reset** — currently a respawn resets `level_time = 0.0`. If you want a "total elapsed time" mode instead of per-attempt best, this needs revisiting.
