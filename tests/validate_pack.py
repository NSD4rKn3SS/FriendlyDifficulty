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
