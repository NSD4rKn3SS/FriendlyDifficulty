# Friendly Difficulty 26.3 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace the 1.18 Friendly Difficulty datapack with a Java 26.3 pack where hostiles ignore players until provoked, with Dialog settings for Explosions and World Damage, plus a Forgejo zip workflow.

**Architecture:** Scoreboard-gated tick loop clears player targets on calm `#friendlydifficulty:affected` mobs (preserving mob in-fighting), provokes individual mobs via `player_hurt_entity`, applies explosion/world-damage modes from `fd.global`, and exposes settings through a datapack Dialog on the pause screen.

**Tech Stack:** Minecraft Java 26.3 datapack (format 121.0), mcfunction + JSON dialog/advancement/tags, Python 3 structural validator, Forgejo Actions (`self-hosted`).

## Global Constraints

- Target Minecraft Java Edition **26.3**; data pack format **121.0** (`min_format` / `max_format` 121.0; include `pack_format` 121 if required for loaders).
- Namespace: **`friendlydifficulty`**. Use singular 26.3 folders: `function/`, `advancement/`, `tags/entity_type/`, `tags/damage_type/`, `tags/function/`, `dialog/`.
- Defaults: `$enabled=0`, `$explosions=1` (Reduced), `$world_damage=2` (Full); provoke timer **600** ticks (~30s).
- Calm mobs must **not** share one team (in-fighting required). Clear **player** targets only.
- No Fabric/NeoForge mod in v1. No Gradle. CI only zips `pack.mcmeta` + `data/`.
- Never commit Minecraft game files. Branch: `cursor/friendlydifficulty-status-3632` (or current feature branch).
- Structural tests live in `tests/validate_pack.py`; run with `python3 tests/validate_pack.py`.

---

## File Structure

| Path | Responsibility |
|---|---|
| `pack.mcmeta` | 26.3 pack metadata |
| `data/minecraft/tags/function/load.json` | `#minecraft:load` → setup |
| `data/minecraft/tags/function/tick.json` | `#minecraft:tick` → tick |
| `data/minecraft/tags/dialog/pause_screen_additions.json` | Pause button |
| `data/minecraft/tags/dialog/quick_actions.json` | Quick Actions |
| `data/friendlydifficulty/function/setup/load.mcfunction` | Scoreboards, defaults, tellraw |
| `data/friendlydifficulty/function/setup/tick.mcfunction` | Gate on `$enabled`; call subsystems |
| `data/friendlydifficulty/function/combat/*.mcfunction` | Calm clear, provoke, timer |
| `data/friendlydifficulty/function/explosions/apply.mcfunction` | Off/Reduced/Full blasts |
| `data/friendlydifficulty/function/world_damage/apply.mcfunction` | Hazard mitigation |
| `data/friendlydifficulty/function/options/*.mcfunction` | Dialog open + apply settings |
| `data/friendlydifficulty/advancement/provoke.json` | `player_hurt_entity` |
| `data/friendlydifficulty/dialog/settings.json` | Settings GUI |
| `data/friendlydifficulty/tags/entity_type/affected.json` | Hostiles/bosses |
| `data/friendlydifficulty/tags/damage_type/world_hazards.json` | Env/accident damage |
| `tests/validate_pack.py` | Structural validator |
| `.forgejo/workflows/build.yml` | Zip + upload artifact |
| `README.md`, `MODLOG.md` | Install + journal |

Remove obsolete `data/**/functions/` and `tags/entity_types/` trees from the 1.18 pack as part of scaffolding.

---

### Task 1: Scaffold 26.3 pack + structural validator

**Files:**
- Create: `pack.mcmeta`
- Create: `data/minecraft/tags/function/load.json`
- Create: `data/minecraft/tags/function/tick.json`
- Create: `data/friendlydifficulty/function/setup/load.mcfunction`
- Create: `data/friendlydifficulty/function/setup/tick.mcfunction`
- Create: `data/friendlydifficulty/tags/entity_type/affected.json`
- Create: `tests/validate_pack.py`
- Delete: entire `data/friendlydifficulty/functions/` tree and `data/minecraft/tags/functions/` tree; delete `data/friendlydifficulty/tags/entity_types/`

**Interfaces:**
- Consumes: none
- Produces: load calls `friendlydifficulty:setup/load`; tick calls `friendlydifficulty:setup/tick`; `#friendlydifficulty:affected` entity type tag; validator exit 0 when structure OK

- [ ] **Step 1: Write the failing validator**

Create `tests/validate_pack.py`:

```python
#!/usr/bin/env python3
"""Structural checks for Friendly Difficulty 26.3 datapack."""
from __future__ import annotations

import json
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
errors: list[str] = []


def err(msg: str) -> None:
    errors.append(msg)


def load_json(path: Path):
    try:
        with path.open(encoding="utf-8") as f:
            return json.load(f)
    except Exception as exc:  # noqa: BLE001
        err(f"{path.relative_to(ROOT)}: invalid JSON ({exc})")
        return None


def main() -> int:
    mcmeta = ROOT / "pack.mcmeta"
    if not mcmeta.is_file():
        err("missing pack.mcmeta")
    else:
        data = load_json(mcmeta)
        if data is not None:
            pack = data.get("pack", {})
            fmt = pack.get("pack_format")
            min_f = pack.get("min_format")
            max_f = pack.get("max_format")
            ok_fmt = fmt in (121, 121.0, [121, 0]) or min_f in (121, 121.0, [121, 0])
            if not ok_fmt:
                err("pack.mcmeta must declare format 121.0 (pack_format and/or min_format)")
            if max_f not in (121, 121.0, [121, 0], None) and max_f != min_f:
                # allow max_format matching min
                if max_f not in (121, 121.0, [121, 0]):
                    err("pack.mcmeta max_format should be 121.0 for the 26.3 target")

    # Legacy plural paths must be gone
    for legacy in (
        ROOT / "data/friendlydifficulty/functions",
        ROOT / "data/minecraft/tags/functions",
        ROOT / "data/friendlydifficulty/tags/entity_types",
    ):
        if legacy.exists():
            err(f"legacy path still present: {legacy.relative_to(ROOT)}")

    required = [
        "data/minecraft/tags/function/load.json",
        "data/minecraft/tags/function/tick.json",
        "data/friendlydifficulty/function/setup/load.mcfunction",
        "data/friendlydifficulty/function/setup/tick.mcfunction",
        "data/friendlydifficulty/tags/entity_type/affected.json",
    ]
    for rel in required:
        if not (ROOT / rel).is_file():
            err(f"missing {rel}")

    load = load_json(ROOT / "data/minecraft/tags/function/load.json")
    if load and "friendlydifficulty:setup/load" not in load.get("values", []):
        err("load.json must include friendlydifficulty:setup/load")

    tick = load_json(ROOT / "data/minecraft/tags/function/tick.json")
    if tick and "friendlydifficulty:setup/tick" not in tick.get("values", []):
        err("tick.json must include friendlydifficulty:setup/tick")

    affected = load_json(ROOT / "data/friendlydifficulty/tags/entity_type/affected.json")
    if affected is not None:
        values = affected.get("values", [])
        for mob in ("minecraft:zombie", "minecraft:skeleton", "minecraft:creeper", "minecraft:warden", "minecraft:wither"):
            if mob not in values:
                err(f"affected.json missing {mob}")

    if errors:
        print("FAIL")
        for e in errors:
            print(f"  - {e}")
        return 1
    print("PASS")
    return 0


if __name__ == "__main__":
    sys.exit(main())
```

- [ ] **Step 2: Run validator (expect FAIL)**

Run: `python3 tests/validate_pack.py`  
Expected: `FAIL` with missing modern paths / legacy paths present.

- [ ] **Step 3: Scaffold pack files**

`pack.mcmeta`:

```json
{
  "pack": {
    "description": "Friendly Difficulty — between Peaceful and Easy (Java 26.3)",
    "pack_format": 121,
    "min_format": [121, 0],
    "max_format": [121, 0]
  }
}
```

`data/minecraft/tags/function/load.json`:

```json
{
  "values": ["friendlydifficulty:setup/load"]
}
```

`data/minecraft/tags/function/tick.json`:

```json
{
  "values": ["friendlydifficulty:setup/tick"]
}
```

`data/friendlydifficulty/function/setup/load.mcfunction`:

```mcfunction
# Friendly Difficulty load — scoreboards created in Task 2; placeholder OK
tellraw @a {"text":"[Friendly Difficulty] 26.3 scaffold loaded","color":"green"}
```

`data/friendlydifficulty/function/setup/tick.mcfunction`:

```mcfunction
# Tick body filled in later tasks
```

`data/friendlydifficulty/tags/entity_type/affected.json` — include at least: blaze, bogged, breeze, cave_spider, creeper, drowned, elder_guardian, ender_dragon, enderman, endermite, evoker, ghast, guardian, hoglin, husk, magma_cube, phantom, piglin, piglin_brute, pillager, ravager, shulker, silverfish, skeleton, slime, spider, stray, vex, vindicator, warden, witch, wither, wither_skeleton, zoglin, zombie, zombie_villager, zombified_piglin, creeper already listed, plus `minecraft:warden`, `minecraft:wither`, `minecraft:ender_dragon`, `minecraft:bogged`, `minecraft:breeze`.

Delete legacy plural directories/files listed above (including old options/weakness mcfunctions).

- [ ] **Step 4: Run validator (expect PASS)**

Run: `python3 tests/validate_pack.py`  
Expected: `PASS`

- [ ] **Step 5: Commit**

```bash
git add -A pack.mcmeta data tests/validate_pack.py
git commit -m "feat: scaffold Friendly Difficulty for Java 26.3"
```

---

### Task 2: Scoreboards, enable gate, Easy baseline

**Files:**
- Modify: `data/friendlydifficulty/function/setup/load.mcfunction`
- Modify: `data/friendlydifficulty/function/setup/tick.mcfunction`
- Create: `data/friendlydifficulty/function/options/enable.mcfunction`
- Create: `data/friendlydifficulty/function/options/disable.mcfunction`
- Modify: `tests/validate_pack.py` (assert scoreboard objective names appear in load)

**Interfaces:**
- Consumes: Task 1 load/tick entrypoints
- Produces: objectives `fd.global`, `fd.provoke`; fake players `$enabled`, `$explosions`, `$world_damage`, `$const_provoke` (600); tick no-ops unless `$enabled` matches 1

- [ ] **Step 1: Extend validator checks**

Append to `main()` in `tests/validate_pack.py`:

```python
    load_fn = ROOT / "data/friendlydifficulty/function/setup/load.mcfunction"
    if load_fn.is_file():
        text = load_fn.read_text(encoding="utf-8")
        for needle in (
            "scoreboard objectives add fd.global",
            "scoreboard objectives add fd.provoke",
            "scoreboard players set $enabled fd.global",
            "scoreboard players set $explosions fd.global",
            "scoreboard players set $world_damage fd.global",
            "scoreboard players set $const_provoke fd.global 600",
        ):
            if needle not in text:
                err(f"setup/load.mcfunction missing: {needle}")

    tick_fn = ROOT / "data/friendlydifficulty/function/setup/tick.mcfunction"
    if tick_fn.is_file():
        text = tick_fn.read_text(encoding="utf-8")
        if "scoreboard players get $enabled fd.global" not in text and "score $enabled fd.global matches 1" not in text:
            err("setup/tick.mcfunction must gate on $enabled fd.global matches 1")
```

- [ ] **Step 2: Run validator (expect FAIL)**

Run: `python3 tests/validate_pack.py`  
Expected: FAIL on missing scoreboard lines.

- [ ] **Step 3: Implement load/tick/enable/disable**

Replace `setup/load.mcfunction`:

```mcfunction
scoreboard objectives add fd.global dummy
scoreboard objectives add fd.provoke dummy

# Defaults only if never set
execute unless score $enabled fd.global = $enabled fd.global run scoreboard players set $enabled fd.global 0
execute unless score $explosions fd.global = $explosions fd.global run scoreboard players set $explosions fd.global 1
execute unless score $world_damage fd.global = $world_damage fd.global run scoreboard players set $world_damage fd.global 2
scoreboard players set $const_provoke fd.global 600

tellraw @a [{"text":"[Friendly Difficulty] ","color":"green"},{"text":"loaded · ","color":"gray"},{"text":"[Settings]","color":"aqua","clickEvent":{"action":"run_command","value":"/function friendlydifficulty:options/open"}}]
```

`options/enable.mcfunction`:

```mcfunction
scoreboard players set $enabled fd.global 1
difficulty easy
tellraw @s {"text":"Friendly Difficulty enabled (world set to Easy).","color":"green"}
```

`options/disable.mcfunction`:

```mcfunction
scoreboard players set $enabled fd.global 0
tellraw @s {"text":"Friendly Difficulty disabled.","color":"yellow"}
```

Replace `setup/tick.mcfunction`:

```mcfunction
execute unless score $enabled fd.global matches 1 run return 0
# Subsystems added in later tasks
```

Note: `options/open` is created in Task 5; for Task 2 either create a stub `options/open.mcfunction` containing `tellraw @s {"text":"Settings UI coming soon"}` or point tellraw at enable/disable. Prefer stub `options/open.mcfunction`:

```mcfunction
tellraw @s {"text":"Settings UI coming in Dialog task","color":"gray"}
```

- [ ] **Step 4: Run validator (expect PASS)**

Run: `python3 tests/validate_pack.py`  
Expected: `PASS`

- [ ] **Step 5: Commit**

```bash
git add data/friendlydifficulty/function tests/validate_pack.py
git commit -m "feat: add enable gate and scoreboard defaults"
```

---

### Task 3: Calm AI + single-mob provoke + 30s calm-down

**Files:**
- Create: `data/friendlydifficulty/function/combat/tick.mcfunction`
- Create: `data/friendlydifficulty/function/combat/as_calm.mcfunction`
- Create: `data/friendlydifficulty/function/combat/clear_player_target.mcfunction`
- Create: `data/friendlydifficulty/function/combat/provoke.mcfunction`
- Create: `data/friendlydifficulty/function/combat/timer.mcfunction`
- Create: `data/friendlydifficulty/advancement/provoke.json`
- Create: `data/friendlydifficulty/function/combat/on_player_hurt_entity.mcfunction`
- Modify: `data/friendlydifficulty/function/setup/tick.mcfunction`
- Modify: `tests/validate_pack.py`

**Interfaces:**
- Consumes: `$enabled`, `$const_provoke`, `#friendlydifficulty:affected`
- Produces: tag `fd.provoked`; score `fd.provoke` countdown; advancement `friendlydifficulty:provoke`

- [ ] **Step 1: Extend validator**

```python
    for rel in (
        "data/friendlydifficulty/function/combat/tick.mcfunction",
        "data/friendlydifficulty/function/combat/as_calm.mcfunction",
        "data/friendlydifficulty/function/combat/clear_player_target.mcfunction",
        "data/friendlydifficulty/function/combat/provoke.mcfunction",
        "data/friendlydifficulty/function/combat/timer.mcfunction",
        "data/friendlydifficulty/function/combat/on_player_hurt_entity.mcfunction",
        "data/friendlydifficulty/advancement/provoke.json",
    ):
        if not (ROOT / rel).is_file():
            err(f"missing {rel}")

    tick_fn = ROOT / "data/friendlydifficulty/function/setup/tick.mcfunction"
    if tick_fn.is_file() and "friendlydifficulty:combat/tick" not in tick_fn.read_text(encoding="utf-8"):
        err("setup/tick.mcfunction must call friendlydifficulty:combat/tick")

    adv = load_json(ROOT / "data/friendlydifficulty/advancement/provoke.json")
    if adv is not None:
        if adv.get("rewards", {}).get("function") != "friendlydifficulty:combat/on_player_hurt_entity":
            err("provoke advancement must reward combat/on_player_hurt_entity")
```

- [ ] **Step 2: Run validator (expect FAIL)**

- [ ] **Step 3: Implement combat functions**

`combat/tick.mcfunction`:

```mcfunction
execute as @e[type=#friendlydifficulty:affected,tag=!fd.provoked] run function friendlydifficulty:combat/as_calm
execute as @e[type=#friendlydifficulty:affected,tag=fd.provoked] run function friendlydifficulty:combat/timer
```

`combat/as_calm.mcfunction`:

```mcfunction
tag @s add fd.self
execute on target if entity @s[type=player] as @e[tag=fd.self,limit=1] run function friendlydifficulty:combat/clear_player_target
tag @s remove fd.self

# Calm creepers: defuse if ignited near players
execute if entity @s[type=minecraft:creeper] if data entity @s {ignited:1b} on target if entity @s[type=player] as @e[type=minecraft:creeper,tag=!fd.provoked,limit=1,sort=nearest] run data modify entity @s ignited set value 0b
```

`combat/clear_player_target.mcfunction`:

```mcfunction
data remove entity @s Brain.memories."minecraft:attack_target"
data remove entity @s AngryAt
data modify entity @s AngerTime set value 0
execute if entity @s[type=minecraft:creeper] run data modify entity @s ignited set value 0b
execute if entity @s[type=minecraft:creeper] run data modify entity @s Fuse set value 30
```

`combat/provoke.mcfunction` (executed as the mob):

```mcfunction
tag @s add fd.provoked
scoreboard players operation @s fd.provoke = $const_provoke fd.global
```

`combat/timer.mcfunction`:

```mcfunction
# Refresh if currently targeting a player (still fighting)
execute on target if entity @s[type=player] as @e[tag=fd.provoked,limit=1,sort=nearest] run scoreboard players operation @s fd.provoke = $const_provoke fd.global

# Safer refresh: if HurtTime shows recent damage while provoked, refresh
execute if data entity @s {HurtTime:10s} run scoreboard players operation @s fd.provoke = $const_provoke fd.global

scoreboard players remove @s fd.provoke 1
execute if score @s fd.provoke matches ..0 run tag @s remove fd.provoked
execute if score @s fd.provoke matches ..0 run scoreboard players reset @s fd.provoke
```

Fix timer refresh to use `fd.self` pattern (same as as_calm) instead of `sort=nearest` guessing — implementers must use:

```mcfunction
tag @s add fd.self
execute on target if entity @s[type=player] run scoreboard players operation @e[tag=fd.self,limit=1] fd.provoke = $const_provoke fd.global
tag @s remove fd.self
execute if data entity @s {HurtTime:10s} run scoreboard players operation @s fd.provoke = $const_provoke fd.global
scoreboard players remove @s fd.provoke 1
execute if score @s fd.provoke matches ..0 run tag @s remove fd.provoked
execute if score @s fd.provoke matches ..0 run scoreboard players reset @s fd.provoke
```

`advancement/provoke.json`:

```json
{
  "criteria": {
    "hit_affected": {
      "trigger": "minecraft:player_hurt_entity",
      "conditions": {
        "entity": [
          {
            "condition": "minecraft:entity_properties",
            "entity": "this",
            "predicate": {
              "type": "#friendlydifficulty:affected"
            }
          }
        ]
      }
    }
  },
  "rewards": {
    "function": "friendlydifficulty:combat/on_player_hurt_entity"
  }
}
```

`combat/on_player_hurt_entity.mcfunction`:

```mcfunction
advancement revoke @s only friendlydifficulty:provoke
execute unless score $enabled fd.global matches 1 run return 0
execute as @e[type=#friendlydifficulty:affected,distance=..12,nbt={HurtTime:10s},limit=1,sort=nearest] run function friendlydifficulty:combat/provoke
```

Update `setup/tick.mcfunction`:

```mcfunction
execute unless score $enabled fd.global matches 1 run return 0
function friendlydifficulty:combat/tick
```

- [ ] **Step 4: Run validator (expect PASS)**

- [ ] **Step 5: Commit**

```bash
git add data/friendlydifficulty/function/combat data/friendlydifficulty/advancement data/friendlydifficulty/function/setup/tick.mcfunction tests/validate_pack.py
git commit -m "feat: calm hostiles until individually provoked"
```

---

### Task 4: Explosions Off / Reduced / Full

**Files:**
- Create: `data/friendlydifficulty/function/explosions/apply.mcfunction`
- Modify: `data/friendlydifficulty/function/setup/tick.mcfunction`
- Modify: `tests/validate_pack.py`

**Interfaces:**
- Consumes: `$explosions` 0/1/2
- Produces: creeper `ExplosionRadius` 0 / 1 / 3; fireball `explosion_power` 0 / 0.5 / vanilla restore; ghast fireballs included via `minecraft:fireball`

- [ ] **Step 1: Extend validator for explosions/apply + tick call + radius literals**

```python
    exp = ROOT / "data/friendlydifficulty/function/explosions/apply.mcfunction"
    if not exp.is_file():
        err("missing explosions/apply.mcfunction")
    else:
        text = exp.read_text(encoding="utf-8")
        for needle in ("ExplosionRadius set value 0", "ExplosionRadius set value 1", "ExplosionRadius set value 3"):
            if needle not in text:
                err(f"explosions/apply.mcfunction missing `{needle}`")
    if "friendlydifficulty:explosions/apply" not in (ROOT / "data/friendlydifficulty/function/setup/tick.mcfunction").read_text(encoding="utf-8"):
        err("tick must call explosions/apply")
```

- [ ] **Step 2: Run validator (expect FAIL)**

- [ ] **Step 3: Implement**

`explosions/apply.mcfunction`:

```mcfunction
# Off
execute if score $explosions fd.global matches 0 as @e[type=minecraft:creeper] run data modify entity @s ExplosionRadius set value 0
execute if score $explosions fd.global matches 0 as @e[type=minecraft:fireball] run data modify entity @s explosion_power set value 0.0d
execute if score $explosions fd.global matches 0 as @e[type=minecraft:wither_skull] run data modify entity @s dangerous set value 0b

# Reduced
execute if score $explosions fd.global matches 1 as @e[type=minecraft:creeper] run data modify entity @s ExplosionRadius set value 1
execute if score $explosions fd.global matches 1 as @e[type=minecraft:fireball] run data modify entity @s explosion_power set value 0.5d

# Full — restore common defaults
execute if score $explosions fd.global matches 2 as @e[type=minecraft:creeper] run data modify entity @s ExplosionRadius set value 3
execute if score $explosions fd.global matches 2 as @e[type=minecraft:fireball] run data modify entity @s explosion_power set value 1.0d
```

Append to tick after combat:

```mcfunction
function friendlydifficulty:explosions/apply
```

- [ ] **Step 4: PASS validator**

- [ ] **Step 5: Commit**

```bash
git commit -am "feat: add Off/Reduced/Full explosion modes"
```

---

### Task 5: World Damage Off / Reduced / Full

**Files:**
- Create: `data/friendlydifficulty/tags/damage_type/world_hazards.json`
- Create: `data/friendlydifficulty/advancement/world_hazard_hit.json`
- Create: `data/friendlydifficulty/function/world_damage/on_hazard.mcfunction`
- Create: `data/friendlydifficulty/function/world_damage/apply.mcfunction`
- Modify: `data/friendlydifficulty/function/setup/tick.mcfunction`
- Modify: `tests/validate_pack.py`

**Interfaces:**
- Consumes: `$world_damage`, `#friendlydifficulty:world_hazards`
- Produces: Off = full heal of that hit + short resistance; Reduced = heal half (via `damage` inverse / `effect resistance`); Full = no mitigation

- [ ] **Step 1: Validator requires world_hazards tag listing fall, in_fire, on_fire, lava, drowning, in_wall, cactus, sweet_berry_bush, freeze, powder_snow**

```python
    haz = load_json(ROOT / "data/friendlydifficulty/tags/damage_type/world_hazards.json")
    if haz is None:
        err("missing world_hazards.json")
    else:
        values = set(haz.get("values", []))
        for dt in (
            "minecraft:fall",
            "minecraft:in_fire",
            "minecraft:on_fire",
            "minecraft:lava",
            "minecraft:drown",
            "minecraft:in_wall",
            "minecraft:cactus",
            "minecraft:sweet_berry_bush",
            "minecraft:freeze",
        ):
            if dt not in values:
                err(f"world_hazards missing {dt}")
    for rel in (
        "data/friendlydifficulty/advancement/world_hazard_hit.json",
        "data/friendlydifficulty/function/world_damage/on_hazard.mcfunction",
        "data/friendlydifficulty/function/world_damage/apply.mcfunction",
    ):
        if not (ROOT / rel).is_file():
            err(f"missing {rel}")
```

- [ ] **Step 2: FAIL validator**

- [ ] **Step 3: Implement**

`tags/damage_type/world_hazards.json`:

```json
{
  "values": [
    "minecraft:fall",
    "minecraft:in_fire",
    "minecraft:on_fire",
    "minecraft:lava",
    "minecraft:drown",
    "minecraft:in_wall",
    "minecraft:cactus",
    "minecraft:sweet_berry_bush",
    "minecraft:freeze",
    "minecraft:hot_floor",
    "minecraft:lightning_bolt",
    "minecraft:outside_border",
    "minecraft:campfire"
  ]
}
```

`advancement/world_hazard_hit.json`:

```json
{
  "criteria": {
    "hazard": {
      "trigger": "minecraft:entity_hurt_player",
      "conditions": {
        "damage": {
          "type": {
            "tags": [
              {"id": "friendlydifficulty:world_hazards", "expected": true}
            ]
          }
        }
      }
    }
  },
  "rewards": {
    "function": "friendlydifficulty:world_damage/on_hazard"
  }
}
```

`world_damage/on_hazard.mcfunction`:

```mcfunction
advancement revoke @s only friendlydifficulty:world_hazard_hit
execute unless score $enabled fd.global matches 1 run return 0
execute if score $world_damage fd.global matches 2 run return 0

# Off: negate — resistance + heal recent damage aggressively
execute if score $world_damage fd.global matches 0 run effect give @s minecraft:resistance 1 4 true
execute if score $world_damage fd.global matches 0 run effect give @s minecraft:instant_health 1 0 true

# Reduced: light resistance
execute if score $world_damage fd.global matches 1 run effect give @s minecraft:resistance 1 1 true
```

`world_damage/apply.mcfunction` (maintenance no-op hook for future attribute tuning):

```mcfunction
# Reserved: continuous mitigation helpers if needed
return 0
```

Tick may call `world_damage/apply` optionally; advancement is the primary path.

- [ ] **Step 4: PASS validator**

- [ ] **Step 5: Commit**

```bash
git commit -am "feat: add world damage Off/Reduced/Full handling"
```

---

### Task 6: Dialog settings GUI + pause/quick actions

**Files:**
- Create: `data/friendlydifficulty/dialog/settings.json`
- Create: `data/minecraft/tags/dialog/pause_screen_additions.json`
- Create: `data/minecraft/tags/dialog/quick_actions.json`
- Create: `data/friendlydifficulty/function/options/open.mcfunction`
- Create: `data/friendlydifficulty/function/options/apply.mcfunction`
- Create: `data/friendlydifficulty/function/options/trigger_tick.mcfunction`
- Modify: `data/friendlydifficulty/function/setup/load.mcfunction` (trigger objective)
- Modify: `data/friendlydifficulty/function/setup/tick.mcfunction` (process triggers)
- Modify: `tests/validate_pack.py`

**Interfaces:**
- Consumes: dialog input keys `enabled`, `explosions`, `world_damage`
- Produces: `friendlydifficulty:settings` dialog; `fd.settings` trigger; `options/apply` macro function

- [ ] **Step 1: Validator requires dialog + tags + apply macro**

```python
    dlg = load_json(ROOT / "data/friendlydifficulty/dialog/settings.json")
    if dlg is None:
        err("missing dialog/settings.json")
    else:
        if dlg.get("type") not in ("minecraft:confirmation", "minecraft:multi_action", "confirmation", "multi_action"):
            err("settings dialog type must be confirmation or multi_action")
        keys = {i.get("key") for i in dlg.get("inputs", [])}
        for k in ("enabled", "explosions", "world_damage"):
            if k not in keys:
                err(f"dialog missing input key {k}")
    for rel in (
        "data/minecraft/tags/dialog/pause_screen_additions.json",
        "data/minecraft/tags/dialog/quick_actions.json",
        "data/friendlydifficulty/function/options/open.mcfunction",
        "data/friendlydifficulty/function/options/apply.mcfunction",
    ):
        if not (ROOT / rel).is_file():
            err(f"missing {rel}")
```

- [ ] **Step 2: FAIL validator**

- [ ] **Step 3: Implement dialog + apply**

`dialog/settings.json`:

```json
{
  "type": "minecraft:confirmation",
  "title": {"text": "Friendly Difficulty"},
  "external_title": {"text": "Friendly Difficulty"},
  "inputs": [
    {
      "type": "minecraft:boolean",
      "key": "enabled",
      "label": {"text": "Enabled"},
      "initial": false,
      "on_true": "1",
      "on_false": "0"
    },
    {
      "type": "minecraft:single_option",
      "key": "explosions",
      "label": {"text": "Explosions"},
      "options": [
        {"id": "0", "display": {"text": "Off"}},
        {"id": "1", "display": {"text": "Reduced"}, "initial": true},
        {"id": "2", "display": {"text": "Full"}}
      ]
    },
    {
      "type": "minecraft:single_option",
      "key": "world_damage",
      "label": {"text": "World Damage"},
      "options": [
        {"id": "0", "display": {"text": "Off"}},
        {"id": "1", "display": {"text": "Reduced"}},
        {"id": "2", "display": {"text": "Full"}, "initial": true}
      ]
    }
  ],
  "yes": {
    "label": {"text": "Apply"},
    "action": {
      "type": "dynamic/run_command",
      "template": "trigger fd.settings set 1"
    }
  },
  "no": {
    "label": {"text": "Cancel"}
  }
}
```

**Important:** `dynamic/run_command` with only a trigger does not pass input values. Use template that calls a macro function instead:

```json
"yes": {
  "label": {"text": "Apply"},
  "action": {
    "type": "dynamic/run_command",
    "template": "function friendlydifficulty:options/apply {enabled:$(enabled),explosions:$(explosions),world_damage:$(world_damage)}"
  }
}
```

`options/apply.mcfunction` (macro):

```mcfunction
$scoreboard players set $enabled fd.global $(enabled)
$scoreboard players set $explosions fd.global $(explosions)
$scoreboard players set $world_damage fd.global $(world_damage)
execute if score $enabled fd.global matches 1 run difficulty easy
tellraw @s {"text":"Friendly Difficulty settings applied.","color":"green"}
```

`options/open.mcfunction`:

```mcfunction
dialog show @s friendlydifficulty:settings
```

`pause_screen_additions.json` / `quick_actions.json`:

```json
{
  "values": ["friendlydifficulty:settings"]
}
```

Add to load: `scoreboard objectives add fd.settings trigger` and enable triggers for players in tick:

`options/trigger_tick.mcfunction`:

```mcfunction
scoreboard players enable @a fd.settings
execute as @a[scores={fd.settings=1..}] run function friendlydifficulty:options/open
execute as @a[scores={fd.settings=1..}] run scoreboard players set @s fd.settings 0
```

Call `options/trigger_tick` from setup/tick **even when disabled** so players can open settings (move enable gate to after trigger processing, or call trigger_tick before the `return 0`).

Final `setup/tick.mcfunction` shape:

```mcfunction
function friendlydifficulty:options/trigger_tick
execute unless score $enabled fd.global matches 1 run return 0
function friendlydifficulty:combat/tick
function friendlydifficulty:explosions/apply
function friendlydifficulty:world_damage/apply
```

- [ ] **Step 4: PASS validator**

- [ ] **Step 5: Commit**

```bash
git commit -am "feat: add Dialog settings on pause screen and quick actions"
```

---

### Task 7: Forgejo workflow, README, MODLOG

**Files:**
- Create: `.forgejo/workflows/build.yml`
- Create: `README.md`
- Modify: `MODLOG.md`
- Modify: `tests/validate_pack.py` (require workflow + README)

**Interfaces:**
- Consumes: pack root files
- Produces: `dist/FriendlyDifficulty-<ref>.zip` artifact named `friendlydifficulty`

- [ ] **Step 1: Validator checks**

```python
    if not (ROOT / ".forgejo/workflows/build.yml").is_file():
        err("missing .forgejo/workflows/build.yml")
    else:
        wf = (ROOT / ".forgejo/workflows/build.yml").read_text(encoding="utf-8")
        for needle in ("runs-on: self-hosted", "forgejo/upload-artifact@v4", "FriendlyDifficulty-"):
            if needle not in wf:
                err(f"workflow missing `{needle}`")
    if not (ROOT / "README.md").is_file():
        err("missing README.md")
```

- [ ] **Step 2: FAIL then implement workflow**

`.forgejo/workflows/build.yml`:

```yaml
name: Build

on:
  push:
  workflow_dispatch:

jobs:
  build:
    runs-on: self-hosted
    steps:
      - uses: actions/checkout@v7

      - name: Validate pack structure
        run: python3 tests/validate_pack.py

      - name: Package datapack
        run: |
          mkdir -p dist
          REF="${GITHUB_REF_NAME:-manual}"
          REF_SAFE=$(echo "$REF" | tr '/' '-')
          zip -r "dist/FriendlyDifficulty-${REF_SAFE}.zip" pack.mcmeta data

      - name: Upload datapack zip
        uses: forgejo/upload-artifact@v4
        with:
          name: friendlydifficulty
          path: dist/*.zip
          if-no-files-found: error
          retention-days: 14
```

`README.md` must document: Java 26.3 install path (`saves/<world>/datapacks/`), enable via pause **Friendly Difficulty** dialog, settings meanings, provoke rules, and that a Fabric difficulty-selector entry is future work.

Update `MODLOG.md` with route (datapack 26.3), settings defaults, and manual in-game test checklist from the spec.

- [ ] **Step 3: Run `python3 tests/validate_pack.py` → PASS**

- [ ] **Step 4: Dry-run package locally**

```bash
mkdir -p dist && zip -r dist/FriendlyDifficulty-local.zip pack.mcmeta data && unzip -l dist/FriendlyDifficulty-local.zip | head
```

Expected: zip lists `pack.mcmeta` and `data/...` entries.

- [ ] **Step 5: Commit**

```bash
git add .forgejo/workflows/build.yml README.md MODLOG.md tests/validate_pack.py
git commit -m "ci: Forgejo datapack zip workflow and docs"
```

---

## Spec coverage checklist

| Spec requirement | Task |
|---|---|
| Format 121.0 / 26.3 folders | 1 |
| Enable gate + Easy baseline | 2 |
| Ignore until provoked (single mob) | 3 |
| ~30s calm-down | 3 |
| Mob in-fighting (no shared calm team) | 3 |
| Bosses same rules | 1 (`affected` includes bosses) + 3 |
| Explosions Off/Reduced/Full | 4 |
| World Damage environmental set | 5 |
| Dialog + pause/quick actions | 6 |
| Forgejo zip CI | 7 |
| Fabric difficulty row | Deferred (documented in README) |

## Plan self-review notes

- No TBD placeholders in steps; validator is the automated test oracle (no Minecraft in CI).
- Macro apply uses `$(enabled)` / `$(explosions)` / `$(world_damage)` consistently.
- Tick order: triggers → enable gate → combat → explosions → world_damage.
