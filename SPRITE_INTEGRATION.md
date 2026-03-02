# KIRA Sprite Integration — M0M3NTUM

## Summary
KIRA sprite sheets integrated into the Godot project using AnimatedSprite2D.

---

## Source Sheets

| File | Size | Layout | Content |
|------|------|--------|---------|
| kira-sheet-1-animated.png | 1024x1024 | 6 cols × 5 rows | Primary animations (170×204 px/frame) |
| kira-sheet-2-poses.png | 1024x1024 | Irregular | Alternative pose variants |
| kira-sheet-3-reference.png | 1024x1024 | Single poses | Labeled reference (Idle/Run/Jump/Crouch/Dash/AttackA/B/Defend/WallSlide/HitReact) |
| kira-sheet-4-grid.png | 1024x1024 | 3 cols × 4 rows | Clean grid poses (341×256 px/frame) |

All sheets copied to: `assets/sprites/kira/`

---

## Sliced Frames

Individual frames extracted via Python/Pillow from sheet-1 and sheet-4:

| Animation | Source Sheet | Frames | Row/Col Origin | FPS | Loops |
|-----------|-------------|--------|----------------|-----|-------|
| idle | sheet-1 | 5 | row 0, col 0 | 8 | yes |
| run | sheet-1 | 6 | row 1, col 0 | 12 | yes |
| jump | sheet-1 | 3 | row 2, col 0 | 10 | no |
| crouch | sheet-1 | 3 | row 2, col 3 | 8 | no |
| dash | sheet-1 | 3 | row 3, col 0 | 16 | no |
| wall_slide | sheet-1 | 2 | row 3, col 4 | 6 | yes |
| attack | sheet-1 | 5 | row 4, col 0 | 14 | no |
| hit_react | sheet-4 | 2 | row 1, col 2 | 10 | no |
| death | sheet-4 | 2 | row 3, col 1 | 8 | no |

Frame files saved to: `assets/sprites/kira/[animation_name]/frame_N.png`

---

## Files Modified / Created

### New Files
- `scripts/kira_animations.gd` — Animation constants, frame metadata, and `build_sprite_frames()` static helper
- `assets/sprites/kira/` — All sprite assets directory
- `SPRITE_INTEGRATION.md` — This file

### Modified Files
- `scenes/player.tscn` — Added `AnimatedSprite2D` node (replaces `Sprite2D`), scaled to 0.35x to fit character collision
- `scripts/player.gd` — Added:
  - `const KiraAnimations` preload
  - `animated_sprite` node reference + `_current_anim` state var
  - `_ready()`: loads SpriteFrames via `KiraAnimations.build_sprite_frames()`
  - `_play_anim(anim)`: deduped animation player
  - `_update_animation()`: state-based animation selection (called each physics frame)
  - `die()`: plays death animation before hiding
  - `respawn()`: resets to idle
  - `_draw()`: skips procedural body drawing when sprite is active (keeps dash trail)

---

## How It Works

The `KiraAnimations.build_sprite_frames()` static function builds a `SpriteFrames` resource at runtime by defining `AtlasTexture` regions on the sprite sheets. This avoids needing a `.tres` file and keeps everything in code.

```gdscript
# In player.gd _ready():
animated_sprite.sprite_frames = KiraAnimations.build_sprite_frames()
```

Animation is driven by game state in `_update_animation()`:
```
dead → death
dashing → dash  
wall sliding → wall_slide
airborne → jump
moving fast → run
else → idle
```

Attack and hit_react are triggered externally (call `_play_anim("attack")` from combat logic).

---

## Known Issues / TODOs

1. **Frame alignment**: Scale is set to `0.35` in the scene — may need per-animation fine-tuning once viewed in editor. The source frames are 170×204px, characters appear to be ~120×180px within each cell (with whitespace).

2. **Crouch detection**: The `crouch` animation checks for `"crouch"` InputMap action. If that action doesn't exist, it silently skips. Add `ProjectSettings > Input Map > crouch` mapped to `S` or `Down`.

3. **Attack / hit_react triggers**: These aren't auto-triggered yet — combat system needs to call `_play_anim("attack")` and `_play_anim("hit_react")` from the appropriate game events.

4. **Sheet-2 not sliced**: `kira-sheet-2-poses.png` contains pose variants (appears to be run variants + weapon poses + wall/jump variants). Not yet sliced — layout appears to be irregular rows of 3-6 sprites each. Can be integrated later for additional animation variety.

5. **Death has 2 frames**: Sheet-4 only provided 2 usable poses for death. Consider adding more frames or a longer death sequence later.

6. **Sprite offset**: Character pivot is at feet in the original code (`oy = -28`). The AnimatedSprite2D is positioned at `Vector2(0, -28)` to match — verify this looks correct in the editor.

---

## Adjusting Sprite Scale

If the character looks too big or small, adjust scale in `player.tscn`:
```
[node name="AnimatedSprite2D" ...]
scale = Vector2(0.35, 0.35)  # Change this value
```

Or adjust the scale per-animation in `kira_animations.gd` if needed.
