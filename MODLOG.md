# MODLOG — FriendlyDifficulty

## Current route: Java 26.3 datapack (format 121.0)

| Item | Detail |
|------|--------|
| **Form** | Vanilla datapack only (`friendlydifficulty` namespace). No Fabric/Forge loader in v1. |
| **Target** | Minecraft Java **26.3**, `pack.mcmeta` format **121.0** (`min_format` / `max_format`). |
| **Layout** | Singular folders: `function/`, `tags/function/`, `tags/entity_type/` (1.18 plural paths removed). |
| **CI** | `.forgejo/workflows/build.yml` — self-hosted runner, `validate_pack.py`, zip → artifact `friendlydifficulty`. |
| **Docs** | `README.md` — install, dialog settings, provoke rules; Fabric difficulty row deferred. |

### Settings defaults (`fd.global`)

| Score | Default | Values |
|-------|---------|--------|
| `$enabled` | **0** (off) | 0 off, 1 on |
| `$explosions` | **1** (Reduced) | 0 Off, 1 Reduced, 2 Full |
| `$world_damage` | **2** (Full) | 0 Off, 1 Reduced, 2 Full |
| Provoke duration | **600 ticks** (~30s) | Per-entity `fd.provoke` |

Dialog: pause screen + quick actions → `friendlydifficulty:settings`; Apply runs `options/apply` with macro args.

### Manual in-game test checklist (26.3)

Run on a **26.3** world after copying the pack to `saves/<world>/datapacks/` and `/reload`.

- [ ] **Load:** No format errors on reload; chat shows `[Friendly Difficulty] loaded · [Settings]`.
- [ ] **Enable:** Open pause **Friendly Difficulty** dialog; enable Friendly; world stays/sets **Easy**.
- [ ] **Calm ignore:** With Friendly on, walk near a zombie — it does not attack.
- [ ] **In-fighting:** Two zombies angered at each other (not at player) can still fight.
- [ ] **Provoke one:** Punch one zombie — only that zombie attacks; others stay calm.
- [ ] **Calm-down:** Stop fighting ~30s — that zombie ignores you again.
- [ ] **Skeleton:** Calm skeleton does not shoot; provoked skeleton shoots.
- [ ] **Explosions:** Toggle Off / Reduced / Full — creeper (and ghast if tested) outcomes match setting.
- [ ] **World damage:** Toggle Off / Reduced / Full — fall/lava/drowning (etc.) match setting.
- [ ] **Dialog persist:** Change settings, `/reload`, reopen dialog — values retained.
- [ ] **CI artifact:** Forgejo build produces zip with `pack.mcmeta` + `data/` at zip root.

### Deferred

- **Fabric / NeoForge:** Fifth **Friendly** row in vanilla difficulty selector (documented in README).

---

## Historical intake (1.18 upstream fork)

- **What this was:** Minecraft **datapack** (not Fabric/Forge/Quilt Java mod), namespace `friendlydifficulty`.
- **Idea (upstream):** "Peaceful, but with hostile mobs" — zero melee damage, neutralize projectiles/explosions, optional peaceful hunger.
- **Repo:** fork of `Scommander/FriendlyDifficulty` (`NSD4rKn3SS/FriendlyDifficulty`).
- **Last upstream activity:** 2022-01-01 (`v2.0` release for 1.18).

## Where the 1.18 fork left off

Development on the frozen **v2.0** snapshot stopped after fork. The 26.3 port (2026) replaces the 1.18 behavior with provoke-based combat, dialog settings, explosions/world damage tiers, and Forgejo packaging.

Chronology (legacy):
1. `6f0f6c3`–`634627c` — GitHub template README
2. `6adbed9` — full datapack land (Scommander)
3. `a3f69d7` — README deleted
4. `2d18d5b` — `pack_format` **8** (1.18–1.18.1), release **v2.0**

## Hard constraints for cloud / CI workspace

- No Minecraft client/server in CI → acceptance is `tests/validate_pack.py` + manual checklist above.
- In-game verification requires a local 26.3 install.
