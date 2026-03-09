# M0M3NTUM

**"Out of control in the best way."**

A 2D momentum-based precision platformer inspired by N++, Celeste, and Dead Cells.

## 🎮 Play Now

**Web Demo:** [laibyrinth.com/m0m3ntum.html](https://laibyrinth.com/m0m3ntum.html)

## 🚀 Features

- **Flow-state movement** — Wall jumps, dashes, and grapples chain together seamlessly
- **Spider-Man grapple** — Upward-only constraint turns grapple into a repositioning tool
- **Combo system** — 1.5s window to chain moves (wall jump → dash → grapple)
- **N++ physics** — Floaty apex hang time + heavy fall gravity = satisfying rhythm
- **Instant respawn** — No death animations, no punishment for experimentation
- **Procedural audio** — Zero audio file dependencies, all sounds synthesized

## 🎯 Mechanics

- **Run** — Tight ground acceleration (42 px/s²)
- **Jump** — Variable height (hold for floaty apex, release for snappy short hop)
- **Wall Jump** — Strong horizontal + vertical kick
- **Dash** — 1600 px/s burst, 1 per jump, 0.2s cooldown
- **Grapple** — 300px range, upward-only, pendulum physics

## 🛠️ Tech Stack

- **Engine:** Godot 4.6.1
- **Language:** GDScript
- **Web Version:** HTML5 Canvas + Pure JavaScript

## 📖 Documentation

See [GDD.md](GDD.md) for the full Game Design Document (10 pages):
- Core vision & design pillars
- Complete physics breakdown
- Level design philosophy
- Art direction & technical details
- Roadmap & lessons learned

## 🏗️ Project Structure

```
godot-project/
├── GDD.md                 # Full game design document
├── scenes/
│   ├── game.tscn          # Main game scene
│   ├── player.tscn        # Player character
│   └── ...
├── scripts/
│   ├── player.gd          # Character controller
│   ├── game_manager.gd    # Level loading, HUD
│   ├── city_background.gd # Parallax background
│   ├── platform_draw.gd   # Platform visuals
│   ├── sfx_manager.gd     # Procedural audio
│   └── ...
├── assets/
│   ├── sprites/kira/      # Character animation strips
│   └── levels/            # Level data JSON
└── project.godot
```

## 🎨 Character Design

**Kaze** — Athletic ninja, dark skin, red diagonal sash, black outfit, white wrist wraps, barefoot, braided ponytail. Proportions inspired by Samus (Metroid Dread).

**Art Style:** Modern 2D with smooth gradients and bezier curves. NOT pixel art.

## 🏃 Getting Started

### Play the Web Version
Just visit [laibyrinth.com/m0m3ntum.html](https://laibyrinth.com/m0m3ntum.html)

### Run Locally (Godot)
1. Install [Godot 4.6.1](https://godotengine.org/download)
2. Clone this repo: `git clone https://github.com/cappy2yappy/m0m3ntum.git`
3. Open `godot-project/project.godot` in Godot
4. Hit F5 to run

## 🗺️ Roadmap

- [ ] Ghost replay system (race your best time)
- [ ] More hazards (spikes, moving platforms, crushers)
- [ ] Character unlock system (Dash, Shade, Captain Flint, Takashi)
- [ ] Combo rewards (visual flair, screen shake scaling)
- [ ] Leaderboard integration (web)
- [ ] Mobile touch controls polish
- [ ] Steam release

## 🤝 Contributing

This is an active development project. Feel free to:
- Report bugs via Issues
- Suggest features or level designs
- Submit PRs for bug fixes or improvements

## 📝 License

MIT License - see LICENSE file for details

## 🙏 Credits

- **Development:** Cappy (AI dev assistant) + Cap (Tony Santiago)
- **Inspirations:** N++, Celeste, Dead Cells, Mark of the Ninja
- **Support:** support@laibyrinth.com

---

**Status:** Pre-Alpha v0.7  
**Last Updated:** March 8, 2026
