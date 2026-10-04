# Friendly Difficulty (Java 26.3)

Vanilla **datapack** for Minecraft Java Edition **26.3** (data pack format **121.0**). Hostile mobs spawn and can fight each other, but **ignore players** until you provoke a specific mob. Tunable explosions and environmental damage sit between Peaceful and Easy.

## Install

1. Download the latest **`FriendlyDifficulty-<branch>.zip`** from Forgejo Actions (artifact name: `friendlydifficulty`), or build locally (see [Development](#development)).
2. Copy or extract the pack into your world’s datapacks folder:

   ```
   saves/<world>/datapacks/FriendlyDifficulty/
   ```

   The folder must contain `pack.mcmeta` and `data/` at its root (not nested inside another folder).

3. In-game, run **`/reload`** (or rejoin the world). You should see a chat line: `[Friendly Difficulty] loaded · [Settings]`.

**Requirements:** Minecraft Java **26.3** with data pack format **121.0**. Older or newer versions are not supported by this release.

## Enable and settings

Friendly Difficulty starts **disabled** until you turn it on.

- Open the **pause menu** (Esc) and use the **Friendly Difficulty** dialog entry, or use the quick-actions dialog if your client shows it. The pause entry is available to everyone; **Apply** runs a server function and may require a permission level that allows `/function` (operators, cheats enabled, or singleplayer).
- You can also run: `/function friendlydifficulty:options/open`

### Settings

| Setting | Meaning | Default |
|--------|---------|---------|
| **Enabled** | Turns the pack on or off. When off, vanilla behavior is unchanged. | Off |
| **Explosions** | **Off** — blasts neutralized (e.g. creeper radius 0). **Reduced** — smaller blasts than vanilla Easy. **Full** — vanilla explosion power. | Reduced |
| **World Damage** | **Off** — environmental/accident damage (fall, fire, lava, drowning, powder snow / **freeze**, etc.) canceled for players. **Reduced** — mitigated. **Full** — vanilla. | Full |

When **Enabled** is on, the pack keeps the world on **Easy** difficulty so spawning and hunger behave like a normal Easy world (not Peaceful).

Settings are stored in scoreboards on the server and persist across reloads.

## Provoke rules

- **Calm mobs** do not target, shoot, fuse, or cast at players.
- **Damaging a mob** (melee or your projectile) provokes **only that mob** for about **30 seconds** of calm-down time (no player↔that-mob combat refreshes the timer).
- After the timer expires, that mob returns to calm and ignores you again.
- **Mob vs mob:** Calm hostiles are **not** on a shared “peace team,” so zombies and other mobs can still fight each other.
- **Bosses** (Warden, Wither, etc.) listed in the pack follow the same provoke rules as ordinary hostiles.

## Future work: Fabric difficulty selector

Vanilla’s difficulty menu is fixed to Peaceful / Easy / Normal / Hard. A **Fabric** (or NeoForge) mod that adds a real **Friendly** row in the difficulty selector is **planned but not included** in this datapack. This repo ships datapack-only v1; scoreboard names (`fd.global`, etc.) are intended to stay compatible if a mod is added later.

## Development

Structural checks (no Minecraft required):

```bash
python3 tests/validate_pack.py
```

Package locally:

```bash
mkdir -p dist
zip -r dist/FriendlyDifficulty-local.zip pack.mcmeta data
```

CI (Forgejo Actions on a **self-hosted** runner) validates the pack, zips `pack.mcmeta` + `data`, and uploads artifact `friendlydifficulty`.

## License / upstream

Fork of [Scommander/FriendlyDifficulty](https://github.com/Scommander/FriendlyDifficulty), redesigned for 26.3. See repository history and `MODLOG.md` for port notes.
