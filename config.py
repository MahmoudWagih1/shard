"""Persistent config for LocalAI — ~/.localai/config.json"""

import json
from pathlib import Path

CONFIG_PATH = Path.home() / ".localai" / "config.json"

DEFAULTS: dict = {
    "model":       "dolphin",
    "theme":       "neon",
    "personality": 1,
    "temp":        0.72,
}


def load() -> dict:
    """Load config from disk; fall back to defaults for missing keys."""
    cfg = dict(DEFAULTS)
    try:
        if CONFIG_PATH.exists():
            data = json.loads(CONFIG_PATH.read_text())
            cfg.update({k: v for k, v in data.items() if k in DEFAULTS})
    except Exception:
        pass
    return cfg


def save(cfg: dict) -> None:
    """Write config to disk, silently ignoring errors."""
    try:
        CONFIG_PATH.parent.mkdir(parents=True, exist_ok=True)
        data = {k: cfg.get(k, DEFAULTS[k]) for k in DEFAULTS}
        CONFIG_PATH.write_text(json.dumps(data, indent=2))
    except Exception:
        pass
