extends Node

# ============================================================
# kira_animations.gd
# Loads KIRA frames from individual PNGs (pre-sliced)
# ============================================================

const ANIM_IDLE       := "idle"
const ANIM_RUN        := "run"
const ANIM_JUMP       := "jump"
const ANIM_CROUCH     := "crouch"
const ANIM_DASH       := "dash"
const ANIM_WALL_SLIDE := "wall_slide"
const ANIM_ATTACK     := "attack"
const ANIM_HIT_REACT  := "hit_react"
const ANIM_DEATH      := "death"

# Animation definitions: name -> { path, frame_count, fps, loop }
const ANIMATIONS := {
	"idle":       { "path": "res://assets/sprites/kira/idle/",       "count": 5, "fps": 8,  "loop": true  },
	"run":        { "path": "res://assets/sprites/kira/run/",        "count": 6, "fps": 12, "loop": true  },
	"jump":       { "path": "res://assets/sprites/kira/jump/",       "count": 3, "fps": 10, "loop": false },
	"crouch":     { "path": "res://assets/sprites/kira/crouch/",     "count": 3, "fps": 8,  "loop": false },
	"dash":       { "path": "res://assets/sprites/kira/dash/",       "count": 3, "fps": 16, "loop": false },
	"wall_slide": { "path": "res://assets/sprites/kira/wall_slide/", "count": 2, "fps": 6,  "loop": true  },
	"attack":     { "path": "res://assets/sprites/kira/attack/",     "count": 5, "fps": 14, "loop": false },
	"hit_react":  { "path": "res://assets/sprites/kira/hit_react/",  "count": 2, "fps": 10, "loop": false },
	"death":      { "path": "res://assets/sprites/kira/death/",      "count": 2, "fps": 8,  "loop": false },
}

static func build_sprite_frames() -> SpriteFrames:
	var sf := SpriteFrames.new()
	
	for anim_name in ANIMATIONS:
		var info = ANIMATIONS[anim_name]
		
		if sf.has_animation(anim_name):
			sf.remove_animation(anim_name)
		sf.add_animation(anim_name)
		sf.set_animation_speed(anim_name, info["fps"])
		sf.set_animation_loop(anim_name, info["loop"])
		
		var loaded_any := false
		for i in range(info["count"]):
			var path = info["path"] + "frame_%d.png" % i
			var tex = load(path) as Texture2D
			if tex:
				sf.add_frame(anim_name, tex)
				loaded_any = true
			else:
				push_warning("KiraAnimations: Missing frame — %s" % path)
		
		if not loaded_any:
			push_warning("KiraAnimations: No frames loaded for '%s' — check asset paths" % anim_name)
	
	return sf
