# MOMENTUM: FRACTURED — Game Design Document

**Genre:** Roguelite Action Platformer  
**Inspirations:** Dead Cells, Hades, Katana ZERO, Hollow Knight  
**Platform:** PC (Windows/Mac/Linux) + Steam  
**Target:** Players who love tight combat, momentum-based movement, and meaningful meta-progression  
**Aesthetic:** Tokyo Noir — traditional Japanese architecture meets modern urban decay

---

## Core Vision

**"Every death is a lesson. Every run is revenge."**

MOMENTUM: FRACTURED is a combat-focused roguelite that marries Dead Cells' satisfying melee combat with M0M3NTUM's momentum-based platforming. Set in a fractured Tokyo where timelines collapse into each other, you play as Runners — agents who slip between realities, getting stronger with each death until you can stabilize the Core and save the city.

### Pillars
1. **Momentum Combat** — Movement IS combat. Dash-strikes, grapple slams, wallrun kicks
2. **Meaningful Runs** — Every death grants permanent progression (cells, blueprints, unlocks)
3. **Skill Expression** — High skill ceiling (parry system, combo chains, speedrun potential)
4. **Tokyo Noir Atmosphere** — Warm lanterns, cherry blossoms, abandoned shrines, NOT neon cyberpunk

---

## Setting & Story

### The Fracture Event

**Year 2088. Tokyo.**  
A quantum experiment at the Tokyo Institute shattered reality into overlapping "echoes" — parallel timelines bleeding into each other. The city exists in fragments: a shrine from 1600 sits next to a subway from 2050, cherry trees bloom in ruined skyscrapers.

**The Core** — center of the fracture — is collapsing. If it fails completely, all timelines cease to exist.

**You are a Runner** — rare individuals who can navigate timeline echoes without disintegrating. Your mission: reach the Core, stabilize it, and prevent total collapse.

### The Timeline Mechanic

Death isn't permanent. When you die, you shift to another timeline echo and try again. But each timeline is slightly different — different room layouts, enemy placements, loot. The Core remembers your progress across timelines (meta-progression), letting you get stronger with every attempt.

**Narrative Structure:**
- **Early runs:** You don't know what the Core is or why it matters
- **Mid-game:** Discover you're one of many Runners; most have failed
- **Late-game:** Uncover what caused the Fracture (corporate greed? government weapon? divine punishment?)
- **Ending:** Multiple endings based on how you stabilize the Core (destroy it? merge timelines? preserve fragments?)

---

## Gameplay Loop

### Run Structure (Dead Cells Inspired)

1. **Hub (The Refuge)**
   - Safe zone between runs
   - Spend cells on permanent upgrades
   - Unlock blueprints at the Forge
   - Choose starting biome (unlocked via progression)
   - Switch characters (unlocked after certain runs)

2. **Biome Run**
   - 8-12 interconnected rooms (hand-crafted, procedurally arranged)
   - Fight enemies, avoid hazards, collect cells
   - Find scrolls (temporary buffs: +damage, +health, etc)
   - Discover blueprints (permanent weapon/ability unlocks)
   - Boss fight at biome exit

3. **Death / Victory**
   - **Death:** Return to Hub with cells collected (spent on meta-progression)
   - **Victory:** Enter next biome (checkpoints unlock shortcuts for future runs)

4. **Endgame Loop**
   - Reach the Core (final biome)
   - Boss rush gauntlet
   - Stabilize the Core (ending choice)

---

## Combat System

### Core Mechanics (Dead Cells Style)

**Melee Combat:**
- **Primary weapon** (sword, katana, naginata, etc) — combos, charge attacks
- **Secondary weapon** (daggers, kunai, shuriken) — quick ranged poke
- **Skills** (dash-strike, shadow clone, grapple slam) — cooldown-based abilities

**Defensive Options:**
- **Dodge roll** — i-frames, directional (8-way)
- **Parry** — timing-based, rewards perfect timing with stun + riposte
- **Block** (some weapons) — reduces damage, no i-frames

**Movement-Combat Integration:**
- **Dash-Strike** — Dash through enemy = damage + knockback
- **Grapple Slam** — Grapple to ceiling → drop attack
- **Wallrun Kick** — Wallrun → kick off wall into enemy
- **Air Juggle** — Launcher attack → follow-up combo in air

### Damage Types

**Physical** (red) — Most melee weapons  
**Energy** (blue) — Tech weapons (laser blade, plasma gun)  
**Temporal** (purple) — Timeline-warping attacks (shadow clone explosion, time-stop)

Enemies have resistances/weaknesses. **No rock-paper-scissors** — player choice matters, but all types viable.

---

## Characters (Unlock Order)

### 1. Kaze (Starter)
**Archetype:** Momentum Specialist  
**Starting Weapon:** Twin Daggers (fast combo, low damage)  
**Signature Ability:** Grapple Hook  
- **Level 1:** Grapple to surfaces (300px range, upward-only)
- **Level 2:** Grapple Pull (pull enemies toward you mid-combo)
- **Level 3:** Grapple Slam (grapple to ceiling → ground slam AoE)

**Passive:** Air Dash Reset (dash cooldown resets on wall touch)

**Playstyle:** High mobility, combo-focused, aerial dominance

---

### 2. Dash (Unlocks Run 5-8)
**Archetype:** Speed Demon  
**Starting Weapon:** Katana (medium speed, medium damage)  
**Signature Ability:** Wallrun  
- **Level 1:** Run horizontally on walls (3s duration)
- **Level 2:** Wallrun Dash (burst speed boost mid-run)
- **Level 3:** Ceiling Run (run on ceilings, inverted gravity)

**Passive:** Slide Kick (crouch while running = slide with i-frames)

**Playstyle:** Never stop moving, hit-and-run, speedrun king

---

### 3. Shade (Unlocks Run 12-15)
**Archetype:** Temporal Trickster  
**Starting Weapon:** Kusarigama (chain-sickle, medium range)  
**Signature Ability:** Shadow Clone  
- **Level 1:** Summon clone that mimics attacks (15s duration)
- **Level 2:** Clone Explosion (detonate clone for AoE damage)
- **Level 3:** Phantom Swap (teleport to clone position, reset cooldowns)

**Passive:** Phase Dash (dash through enemies, brief invulnerability)

**Playstyle:** Confusion tactics, burst damage, hard to master

---

### 4. Captain Flint (Unlocks Run 20-25)
**Archetype:** Ranged Bruiser  
**Starting Weapon:** Cannon Arm (slow, high damage, explosive)  
**Signature Ability:** Chain Hook  
- **Level 1:** Hookshot pull (yank enemy toward you, stun)
- **Level 2:** Multi-Hook (chain up to 3 enemies)
- **Level 3:** Hook Slam (pull + slam into ground, AoE shockwave)

**Passive:** Armor Plating (reduce damage taken, slower movement)

**Playstyle:** Tank/bruiser, zone control, boss killer

---

### 5. Takashi (Unlocks Run 30+)
**Archetype:** Glass Cannon  
**Starting Weapon:** Nodachi (slow, massive damage, long reach)  
**Signature Ability:** Dash-Strike Chain  
- **Level 1:** Dash-Strike (dash through enemy = damage + i-frames)
- **Level 2:** Combo Chain (3 dash-strikes in quick succession)
- **Level 3:** Execution Dash (if enemy below 30% HP, instant kill)

**Passive:** Glider (hold jump after apex = slow fall, reposition)

**Playstyle:** High risk/reward, boss shredder, execution finisher

---

## Biomes (6 Total)

### 1. Shibuya Crossing (Tutorial)
**Aesthetic:** Abandoned intersection, shattered billboards, overgrown vending machines  
**Enemies:** Echoes (basic humanoid), Drones (flying, ranged)  
**Hazards:** Broken traffic lights (electric arcs), collapsing platforms  
**Boss:** Echo Amalgam (merged timeline ghosts, phase through attacks)

---

### 2. Temple District
**Aesthetic:** Shrine rooftops, paper lanterns, bamboo groves, cherry blossoms  
**Enemies:** Shrine Guardians (armored, shield-bearers), Spirit Foxes (fast, evasive)  
**Hazards:** Swinging temple bells, flame braziers, bamboo spike traps  
**Boss:** Kitsune Matriarch (9-tailed fox, illusion clones)

---

### 3. Underground Metro
**Aesthetic:** Train tunnels, platform edges, flickering fluorescent lights, graffiti  
**Enemies:** Gangers (melee rushdown), Turrets (wall-mounted), Hounds (beast rushdown)  
**Hazards:** Electric rails, moving trains, platform gaps  
**Boss:** Steel Serpent (corrupted train, chase sequence + arena fight)

---

### 4. Rooftop Gardens
**Aesthetic:** Vertical ascent, traditional tile roofs, moss-covered stones, water features  
**Enemies:** Snipers (long-range), Ninjas (stealth, ambush), Golems (slow tanks)  
**Hazards:** Wind gusts (push player), crumbling roofs, falling tiles  
**Boss:** Sky Sentinel (giant stone golem, aerial combat)

---

### 5. Industrial Docks
**Aesthetic:** Cargo cranes, shipping containers, rusted metal, oil slicks  
**Enemies:** Mechs (heavy armor, ranged), Workers (tools as weapons), Sentry Bots  
**Hazards:** Crane hooks, conveyor belts, toxic spills, crushers  
**Boss:** Dockmaster Titan (mech suit, multi-phase fight)

---

### 6. The Fractured Core
**Aesthetic:** Reality-bending shrine, floating platforms, glitching geometry, temporal distortions  
**Enemies:** All previous types + Elite variants  
**Hazards:** Timeline tears (instant death), gravity shifts, phase floors  
**Boss Rush:** Fight all 5 previous bosses in gauntlet → Final Boss (The Architect)

---

## Meta-Progression

### Currencies

**Cells** (primary)
- Dropped by enemies (10-50 per elite)
- Spent at Hub on permanent upgrades
- Lost on death (but keep % based on mastery level)

**Blueprints** (unlocks)
- Found in secret rooms, dropped by bosses
- Unlock at Forge (spend cells to add to drop pool)
- Permanent unlock (never lost)

**Echo Fragments** (exploration)
- Hidden in biomes (5-10 per biome)
- Unlock lore entries + alternate paths
- 100% collection = secret ending

### Permanent Upgrades (Hub)

**Health Pool:** +20 HP per tier (max 200 → 500)  
**Damage Boost:** +10% per tier (max +100%)  
**Cell Retention:** Keep more cells on death (0% → 50%)  
**Starting Gold:** Begin runs with gold for shops (0 → 500)  
**Skill Slots:** Unlock additional ability slots (1 → 3)

### Character Progression

Each character has **3 skill trees** (unlock with cells):
- **Offensive** (damage, combo extensions)
- **Defensive** (health, dodge upgrades)
- **Utility** (movement speed, cooldown reduction)

Skills persist across runs once unlocked.

---

## Art Direction: Tokyo Noir

### Visual Principles

**NOT Neon Cyberpunk**
- No pink/cyan neon signs
- No holographic ads
- No synthwave aesthetics

**YES Tokyo Traditional Meets Modern**
- Warm amber lantern glow
- Cherry blossom pink accents
- Deep indigo night skies
- Aged wood + paper textures
- Moonlight through clouds
- Moss-covered stone

### Color Palette

**Primary:**
- Deep indigo (#1a1a2e) — night sky
- Warm amber (#d4a056) — lanterns, fire
- Moss green (#3d5a3c) — overgrowth
- Aged wood (#4a3c2b) — structures

**Accents:**
- Cherry blossom pink (#ffb7c5)
- Shrine red (#c1272d) — torii gates
- Cool moonlight blue (#9fb4d1)
- Gold trim (#c9a961) — decorative

### Character Style (Metroid Dread Anime)

- Smooth anime proportions (NOT pixel art)
- Bezier curves + gradient shading
- Dramatic rim lighting
- Energy trail effects on movement
- Cloth/hair physics (flowing scarf, ponytail)

**Reference:** Your uploaded image — that exact style

---

## Technical Scope

### Engine: Godot 4.6

**Why Godot:**
- M0M3NTUM physics already tuned
- 2D optimized, fast iteration
- GDScript = Codex-friendly
- Free, open source, no licensing fees

### Project Structure

```
momentum-fractured/
├── scripts/
│   ├── player/
│   │   ├── kaze.gd
│   │   ├── dash.gd
│   │   ├── shade.gd
│   │   ├── flint.gd
│   │   └── takashi.gd
│   ├── combat/
│   │   ├── hitbox.gd
│   │   ├── damage.gd
│   │   ├── parry.gd
│   │   └── combo_tracker.gd
│   ├── enemies/
│   │   ├── echo.gd
│   │   ├── guardian.gd
│   │   └── ...
│   ├── biomes/
│   │   ├── room_loader.gd
│   │   ├── biome_manager.gd
│   │   └── proc_generation.gd
│   └── meta/
│       ├── cell_manager.gd
│       ├── blueprint_unlocks.gd
│       └── save_system.gd
├── assets/
│   ├── sprites/
│   │   ├── kaze/
│   │   ├── enemies/
│   │   └── environment/
│   ├── audio/ (procedural SFX)
│   └── tilesets/
└── scenes/
    ├── hub.tscn
    ├── biomes/
    └── ui/
```

### Room System (Dead Cells Approach)

**Hand-Crafted Rooms, Procedural Arrangement**
- Each biome has 30-50 hand-designed rooms
- Rooms tagged by type: combat, treasure, shop, secret, boss
- Generator arranges rooms based on difficulty curve
- Connections ensured via doorway nodes

**Room Template:**
```
Room_Shibuya_Combat_01:
- Width: 800px
- Height: 600px
- Entry points: [left, top]
- Exit points: [right, bottom]
- Enemy spawns: 3x Echo, 1x Drone
- Loot: 2x chest
```

---

## Development Roadmap

### Phase 1: M0M3NTUM Cleanup (1-2 Days)
- Codex: Sprite white outline removal
- Codex: Level blocking bug fixes
- Codex: Re-export Windows build
- **Deliverable:** M0M3NTUM v0.8 (fully playable)

### Phase 2: Combat Prototype (Week 1-2)
- Port M0M3NTUM physics to new project
- Implement basic melee combat (Kaze only)
- Add 1 enemy type (Echo)
- Dodge roll + parry system
- Health/damage/death
- **Deliverable:** Combat feels good in isolation

### Phase 3: First Biome (Week 3-4)
- Build Shibuya Crossing (8 rooms)
- 3 enemy types (Echo, Drone, Ganger)
- Boss fight (Echo Amalgam)
- Tutorial flow (teach movement + combat)
- **Deliverable:** Vertical slice (tutorial biome complete)

### Phase 4: Meta-Progression (Month 2)
- Build Hub (Refuge)
- Cell economy + permanent upgrades
- Blueprint unlock system
- Save/load system
- Character unlock (Dash)
- **Deliverable:** Roguelite loop functional

### Phase 5: Content Expansion (Months 3-6)
- Biomes 2-5 (Temple, Metro, Rooftops, Docks)
- Characters 3-5 (Shade, Flint, Takashi)
- 20+ weapon types
- 50+ ability upgrades
- **Deliverable:** Full game content

### Phase 6: Polish & Balance (Months 7-8)
- Particle effects, screen shake, juice
- Boss balance pass
- Difficulty curve tuning
- Speedrun mode + leaderboards
- **Deliverable:** Steam Early Access ready

---

## Success Metrics

### Core Loop (Must Feel Good)
- [ ] Combat feels impactful (hit feedback, enemy reactions)
- [ ] Movement feels fluid (dash, grapple, wallrun)
- [ ] Death feels fair (clear what killed you, instant retry)
- [ ] Progression feels meaningful (cells unlock real power)

### Content Goals
- [ ] 6 biomes × 10 rooms each = 60 rooms
- [ ] 5 playable characters (all unique playstyles)
- [ ] 30+ weapon types (melee + ranged)
- [ ] 50+ ability upgrades (skill trees)
- [ ] 12+ boss fights (2 per biome + final)

### Scope Target
- **6-10 hours** first playthrough
- **30+ hours** for 100% completion
- **Infinite replayability** (roguelite loop + speedruns)

---

## Monetization

### Pricing
- **Steam Early Access:** $14.99
- **Full Release:** $19.99
- **Launch discount:** 20% off ($15.99)

### Post-Launch Content (Free Updates)
- New biome (The Abyss) — 3 months post-launch
- New character (#6) — 6 months post-launch
- Daily/weekly challenges — ongoing
- Boss Rush mode — 1 month post-launch

### DLC (Optional, Year 2)
- **Character Pack** ($4.99) — 2 new characters
- **Biome Pack** ($6.99) — 2 new biomes + bosses
- **Soundtrack** ($2.99) — full OST

---

## Competitive Positioning

### vs Dead Cells
- **Advantage:** Momentum-based movement (more dynamic than Dead Cells' grounded combat)
- **Disadvantage:** Smaller scope (Dead Cells has 10+ biomes at maturity)

### vs Hades
- **Advantage:** Platformer focus (Hades is top-down brawler)
- **Disadvantage:** Less narrative depth (Hades has deep character relationships)

### vs Hollow Knight
- **Advantage:** Roguelite structure (faster runs, more replayability)
- **Disadvantage:** Not Metroidvania (Hollow Knight has interconnected exploration)

**Unique Selling Point:** Only roguelite that combines Dead Cells' combat with precision platforming movement. Tokyo Noir aesthetic is underserved in the genre.

---

## Risk Mitigation

### Technical Risks
- **Procedural generation bugs** → Extensive playtesting, room validation system
- **Combat balance** → Iterative tuning, community feedback via Early Access
- **Performance** → Godot 4.6 is well-optimized for 2D, use object pooling

### Scope Creep
- **Mitigation:** Phase-based development, vertical slice first
- **Kill switch:** If Month 3 vertical slice doesn't feel good, pivot or cut scope

### Market Saturation
- **Mitigation:** Tokyo Noir aesthetic differentiates from crowded cyberpunk/fantasy roguelites
- **Marketing:** Focus on movement mechanics as unique hook

---

## Next Steps (Immediate)

1. **Codex:** Finish M0M3NTUM cleanup (1-2 days)
2. **Cap:** Gather Tokyo aesthetic references (Pinterest, game screenshots)
3. **Cappy:** Finalize combat system design (weapon types, enemy behaviors)
4. **All:** Create combat prototype (Week 1-2)

---

**Last Updated:** March 9, 2026  
**Version:** 0.1 (Pre-Production)  
**Target Release:** Q4 2026 (Early Access)
