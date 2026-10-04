# Friendly Difficulty — Java 26.3 Design

**Status:** Approved in brainstorming (2026-10-04)  
**Target:** Minecraft Java Edition **26.3** (data pack format **121.0**)  
**Form:** Vanilla datapack (v1). Optional Fabric/NeoForge mod later for a real difficulty-selector row.

## Problem

Port and redesign [FriendlyDifficulty](https://github.com/Scommander/FriendlyDifficulty) from a 1.18 “zero damage forever” pack into a difficulty **between Peaceful and Easy**:

- Hostile mobs exist and can fight each other.
- They **fully ignore players** until **that specific mob** is provoked.
- The player can still take damage (world/accident hazards; provoked mobs).
- Explosions and world damage are tunable (Off / Reduced / Full).
- Settings use a real Dialog GUI; activation is available from the pause screen.

## Goals / Non-goals

### Goals (v1)

1. Datapack loads cleanly on **26.3** (`pack_format` / `min_format` / `max_format` = **121.0**).
2. Calm hostiles never target, shoot, fuse, or cast at players.
3. Damaging a mob provokes **only that mob** for ~30s of non-combat calm-down.
4. Mob in-fighting remains possible while calm.
5. Global settings: **Explosions**, **World Damage** (each Off / Reduced / Full).
6. Custom **Dialog** settings UI + pause-screen / quick-actions entry to enable Friendly.
7. Forgejo Action packages a datapack zip on push / `workflow_dispatch`.

### Non-goals (v1)

- Injecting a fifth row into the vanilla Difficulty dropdown (hardcoded; needs a mod).
- Per-player setting splits in multiplayer.
- Resource pack / custom textures.
- Hunger as a separate setting (baseline = Easy while Friendly is enabled).

### Later (explicitly deferred)

- **Phase B/C:** small Fabric or NeoForge mod that adds **Friendly** to the real difficulty selector, reusing the same scoreboard/storage contracts as this datapack.

## Player-facing behavior

| Topic | Decision |
|---|---|
| Provoke scope | Only the mob the player damaged |
| Unprovoked AI | Fully ignore players (no target / shoot / fuse / cast) |
| In-fighting | Allowed (calm mobs must **not** all share one team) |
| Calm-down | ~30s without player↔that-mob combat |
| Bosses / Warden / raids | Same rules as normal hostiles |
| Explosions | Off / Reduced / Full (global) |
| World Damage | Off / Reduced / Full — environmental/accident set (fall, fire/lava, drowning, suffocation, cactus/berries, freezing, powder snow, etc.) |
| Defaults | Friendly **disabled** until toggled; Explosions **Reduced**; World Damage **Full** |
| Vanilla difficulty while enabled | Force / keep **Easy** so spawning and hunger baseline work |

## Architecture

### Activation model

- Scoreboard flag `$enabled` on `fd.global` (0/1).
- When **disabled**: tick logic no-ops (no calm clearing, no explosion overrides).
- When **enabled**: apply combat model + settings; ensure world difficulty is Easy (via `/difficulty easy` from a privileged path or document that operators set Easy — prefer automatic set on enable if permission allows).

### Combat model (no shared calm-team)

Shared team-for-all-hostiles is rejected because it blocks in-fighting.

1. Entity type tag `#friendlydifficulty:affected` lists hostiles/bosses/projectiles-of-interest as needed.
2. Calm mobs: each tick, if their attack target is a player, clear that target only.
3. `player_hurt_entity` advancement → run function as the damaged entity → `fd.provoked` tag + set provoke timer (~600 ticks).
4. While provoked: do not clear player targets; vanilla combat applies (still subject to Explosions setting for blast size).
5. Timer refreshes if that mob hits or is hit by a player; at 0 → remove provoked, return to calm.
6. Creepers while calm: prevent fuse against players (clear fuse / deny player chase). Provoked creepers follow Explosions setting.
7. Projectiles: credit owner for provoke; calm ranged mobs should not keep a player as target.

### Settings storage

| Score (`fd.global`) | Values |
|---|---|
| `$enabled` | 0 off, 1 on |
| `$explosions` | 0 Off, 1 Reduced, 2 Full |
| `$world_damage` | 0 Off, 1 Reduced, 2 Full |
| Per-entity `fd.provoke` | remaining ticks |

### Explosions

- **Off:** neutralize blast (e.g. creeper radius 0, fireball explosion power 0, similar for ghast/wither skull as feasible).
- **Reduced:** smaller radius / power than vanilla Easy.
- **Full:** leave vanilla values (re-apply only when leaving Off/Reduced).

### World Damage

Apply only to players, for the environmental/accident damage set (not provoked melee/projectile from mobs):

- **Off:** cancel/negate those damage events (advancements / damage type tags / absorption pattern as appropriate for 26.3).
- **Reduced:** roughly half effect (scaled mitigation).
- **Full:** vanilla.

Exact 26.3 damage-type tag list is an implementation detail; must cover fall, fire/lava, drowning, suffocation, cactus, sweet berries, freezing, powder snow at minimum.

### Dialog GUI

- `data/friendlydifficulty/dialog/settings.json` — inputs for Enabled, Explosions, World Damage; submit runs a function (macros / triggers as required by 26.3 dialog rules).
- Tag into `#minecraft:pause_screen_additions` and `#minecraft:quick_actions`.
- Also openable via `/dialog show` wrapper function and reload tellraw.

Permission note: dialog `run_command` actions run at the clicking player’s permission level. Prefer `trigger` objectives for non-op players so settings remain usable in survival multiplayer.

## Pack layout (26.3)

```
pack.mcmeta                          # format 121.0
data/
  minecraft/tags/
    function/load.json
    function/tick.json
    dialog/pause_screen_additions.json
    dialog/quick_actions.json
  friendlydifficulty/
    function/
      setup/load.mcfunction
      setup/tick.mcfunction
      combat/...
      explosions/...
      world_damage/...
      options/...
    advancement/provoke.json
    dialog/settings.json
    predicate/...
    tags/entity_type/affected.json
    tags/damage_type/world_hazards.json
.forgejo/workflows/build.yml
README.md
MODLOG.md
```

Legacy plural folders (`functions/`, `entity_types/`) from the 1.18 pack are removed/replaced.

## Forgejo CI

Datapack packaging (not Gradle), modeled on the user’s self-hosted runner style:

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
      - name: Package datapack
        run: |
          mkdir -p dist
          REF="${GITHUB_REF_NAME:-manual}"
          REF_SAFE=$(echo "$REF" | tr '/' '-')
          zip -r "dist/FriendlyDifficulty-${REF_SAFE}.zip" pack.mcmeta data
      - uses: forgejo/upload-artifact@v4
        with:
          name: friendlydifficulty
          path: dist/*.zip
          if-no-files-found: error
          retention-days: 14
```

`pack.mcmeta` declares data pack **121.0** using the 26.3-required `min_format` / `max_format` fields (and legacy `pack_format` only if still required for that release).

No Java setup for v1. If a Fabric mod is added later, extend the workflow with Temurin 25 + Gradle jar upload beside the zip.

## Testing / acceptance

Without a Minecraft install in CI, acceptance is manual / local:

1. Pack shows no format errors on 26.3 `/reload`.
2. With Friendly enabled: zombie ignores player; two zombies can still fight if angered at each other.
3. Punching one zombie makes only that zombie hostile; after ~30s idle it calms.
4. Skeleton does not shoot while calm; shoots when provoked.
5. Explosions Off/Reduced/Full visibly change creeper/ghast outcomes.
6. World Damage Off/Reduced/Full affect fall/lava as designed.
7. Pause-screen Dialog opens and persists settings across reload.
8. Forgejo workflow produces a zip artifact on the self-hosted runner.

## Risks

| Risk | Mitigation |
|---|---|
| Some mobs use non-standard targeting (Enderman stare, Warden anger, Piglin) | Special-case functions per family; document gaps if a mob cannot be fully calmed |
| Dialog commands need elevated perms | Use `trigger` bridge for survival players |
| Forcing `/difficulty easy` may fail for non-ops | On enable, try set; if fail, tellraw instruct op/host |
| Reduced damage math feels wrong | Tune constants after first in-game pass |
| 26.3 command/NBT drift vs wiki | Verify against 26.3 changelog while implementing |

## Implementation phases (for planning skill)

1. Scaffold 26.3 pack (`pack.mcmeta`, singular folders, load/tick).
2. Combat calm + provoke advancement + timer.
3. Explosions setting.
4. World Damage setting + damage type tag.
5. Dialog GUI + pause/quick-actions tags.
6. README + MODLOG update.
7. Forgejo build workflow.
8. Manual test checklist in MODLOG.

## Open points resolved in brainstorming

- Provoke = A (single mob)
- Explosions = B (Off / Reduced / Full)
- Unprovoked = A (fully ignore)
- Calm-down = B (~30s)
- Bosses = A (same rules)
- World Damage scope = B (environmental / accident hazards)
- Approach = team-inspired provoke model **without** shared calm-team (in-fighting)
- GUI = Dialog; difficulty selector = pause-screen activation now, Fabric later
