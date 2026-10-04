# MODLOG — FriendlyDifficulty

## Intake
- **What this is:** Minecraft **datapack** (not Fabric/Forge/Quilt Java mod), namespace `friendlydifficulty`.
- **Idea (upstream):** "Peaceful, but with hostile mobs" — zero melee damage, neutralize projectiles/explosions, optional peaceful hunger.
- **Repo:** fork of `Scommander/FriendlyDifficulty` (`NSD4rKn3SS/FriendlyDifficulty`). Compare status: **identical to upstream** (0 ahead / 0 behind).
- **Last upstream activity:** 2022-01-01 (`v2.0` release for 1.18). Fork created 2025-09-14 with **no local commits of your own**.
- **Done means (for a revive):** pack loads on a chosen modern MC version, hostiles spawn but cannot hurt the player, options still toggle hunger, short in-game clip.

## Where you left off
Development never continued past the forked **finished v2.0** snapshot. Working tree is clean; there is no unfinished feature branch, no README (deleted in `a3f69d7`), and no `MODLOG` prior to this note.

Chronology:
1. `6f0f6c3`–`634627c` — GitHub template README
2. `6adbed9` — full datapack land (Scommander)
3. `a3f69d7` — README deleted
4. `2d18d5b` — `pack_format` set to **8** (1.18–1.18.1), shipped as release **v2.0**

## Layout check (correct for 1.18 datapacks)

| Piece | Status |
|---|---|
| `pack.mcmeta` `pack_format: 8` | OK for Java 1.18–1.18.1 |
| `#minecraft:load` → `friendlydifficulty:setup/schedule` | Wired |
| `#minecraft:tick` → `friendlydifficulty:setup/tick` | Wired |
| Scoreboards / options / weakness / projectile neutralize | Present |
| Entity type tags (`hostile`, `projectile`, `fireball`, `guardian`) | Present |

Entrypoints and function wiring are structurally sound for that era. This is a **complete 1.18 datapack**, not a half-built skeleton.

## Behavior summary (implemented)
- On load (+1s schedule): chat banner `[V1.0.0] Friendly Difficulty` + `[Options]` → hunger toggle (`$saturation` on `fd.global`).
- Every tick: untagged `#friendlydifficulty:hostile` → `weakness` (attack damage −100000, Weakness, creeper `ExplosionRadius:0`, guardian follow_range 0, evoker fangs warmup −20).
- Player projectiles tagged `from_player` via bow/crossbow/trident/splash scoreboards; non-player arrows/tridents/splash potions neutralized.
- Nearby fireballs / shulker bullets killed with FX.
- Default: saturation effect so hunger behaves like peaceful unless options set `$saturation` to 1.

## Gaps / leftovers inside the 1.18 code
1. **`#special case for wolf`** in `setup/tick.mcfunction` — comment only; never implemented (wolves are already in the hostile tag and get the generic weakness pass).
2. **Version string mismatch:** reload message says `V1.0.0` while GitHub release / intent is **v2.0**.
3. **Fireballs in `#hostile`:** `weakness` runs `attribute` + `effect` on fireball entities (odd targets; explode power also patched). Works enough for 1.18 style but is messy.
4. **Missing later mobs** (post-1.18): Warden, Frog-era n/a, Bogged, Breeze, etc. — expected for a frozen 1.18 pack.
5. **No lab / save backup / showcase** artifacts in this cloud workspace; no Minecraft install here to live-test.

## Modern Minecraft (if you resume on 1.21.x)
Not "set correctly" for current Java without a port. At minimum expect:
- Bump `pack_format` (e.g. **81** for 1.21.7–1.21.8; **88+** / `min_format`–`max_format` for 1.21.9+).
- 1.21 folder rename: `functions/` → `function/`, `tags/functions` → `tags/function`, `tags/entity_types` → `tags/entity_type`.
- Attribute IDs: `minecraft:generic.attack_damage` → `minecraft:attack_damage` (and similar for follow_range).
- Item/potion NBT → components (splash potion neutralize in `setup/tick` uses pre-1.20.5 `tag`/`Count`).
- Re-test Owner UUID / arrow damage fields; some entity data names moved.
- Expand hostile tag for 1.19–1.21 mobs you care about.

## Route (if continuing)
**Data/datapack only** — keep vanilla commands; no loader. Cheapest path: port the existing pack to one target MC version, then vertical-slice (zombie melee + skeleton arrow + creeper + hunger toggle) before adding new mobs.

## Next step options
A. **Port to a target version** (say 1.21.8) and verify in-game.  
B. **Stay on 1.18** and only polish leftovers (wolf comment, version string, README).  
C. **Leave as archive** of Scommander v2.0 — already complete for that version.

## Hard constraints for this workspace
- No Minecraft client/server installed → cannot run the oracle here.
- `um` CLI not on PATH in this environment; assessment is from pack structure + git/GitHub history.
