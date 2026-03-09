extends Node

# ============================================================
# kira_animations.gd
# Loads Kira animations from strip PNGs (sliced from labeled sheet)
# Frame size: 128×160px per frame
# ============================================================

const FRAME_W := 128
const FRAME_H := 160

# name -> { strip path, frame_count, fps, loop }
# Frame counts and fps tuned for smooth 60fps gameplay feel
const ANIMATIONS := {
	"idle":       { "path": "res://assets/sprites/kira/idle/strip.png",       "count": 8,  "fps": 8,  "loop": true  },
	"run":        { "path": "res://assets/sprites/kira/run/strip.png",        "count": 12, "fps": 18, "loop": true  },
	"jump":       { "path": "res://assets/sprites/kira/jump/strip.png",       "count": 6,  "fps": 12, "loop": true  },
	"fall":       { "path": "res://assets/sprites/kira/fall/strip.png",       "count": 3,  "fps": 10, "loop": true  },
	"dash":       { "path": "res://assets/sprites/kira/dash/strip.png",       "count": 5,  "fps": 20, "loop": true  },
	"wall_slide": { "path": "res://assets/sprites/kira/wall_slide/strip.png", "count": 2,  "fps": 8,  "loop": true  },
	"crouch":     { "path": "res://assets/sprites/kira/crouch/strip.png",     "count": 1,  "fps": 1,  "loop": true  },
	"land":       { "path": "res://assets/sprites/kira/land/strip.png",       "count": 3,  "fps": 20, "loop": true  },
}

static func build_sprite_frames() -> SpriteFrames:
	var sf := SpriteFrames.new()

	for anim_name in ANIMATIONS:
		var info = ANIMATIONS[anim_name]
		var strip_tex = load(info["path"]) as Texture2D

		if sf.has_animation(anim_name):
			sf.remove_animation(anim_name)
		sf.add_animation(anim_name)
		sf.set_animation_speed(anim_name, info["fps"])
		sf.set_animation_loop(anim_name, info["loop"])

		if not strip_tex:
			push_warning("KiraAnimations: Missing strip — %s" % info["path"])
			continue

		var img := strip_tex.get_image()
		var count: int = info["count"]
		# Derive actual frame count from strip width if possible
		var actual_count := img.get_width() / FRAME_W
		if actual_count > 0 and actual_count != count:
			push_warning("KiraAnimations: %s strip has %d frames but config says %d — using actual" % [anim_name, actual_count, count])
			count = actual_count

		for i in range(count):
			var region := Rect2i(i * FRAME_W, 0, FRAME_W, FRAME_H)
			var frame_img := img.get_region(region)
			var frame_tex := ImageTexture.create_from_image(frame_img)
			sf.add_frame(anim_name, frame_tex)

	return sf
