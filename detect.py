"""Hardware detection for LocalAI — stdlib only, runs before venv setup."""

import json
import os
import platform
import re
import shutil
import subprocess
import sys


def _sysctl(key: str) -> str:
    try:
        return subprocess.check_output(
            ["sysctl", "-n", key], text=True, stderr=subprocess.DEVNULL
        ).strip()
    except Exception:
        return ""


def detect() -> dict:
    """Return hardware info as a dict. Uses stdlib only."""
    chip = _sysctl("machdep.cpu.brand_string") or _sysctl("hw.model") or "Unknown"

    mem_str = _sysctl("hw.memsize")
    try:
        ram_gb = int(mem_str) / (1024 ** 3)
    except (ValueError, TypeError):
        ram_gb = 0.0

    macos = platform.mac_ver()[0]
    try:
        macos_major = int(macos.split(".")[0])
    except Exception:
        macos_major = 0

    home = os.path.expanduser("~")
    try:
        disk_free_gb = shutil.disk_usage(home).free / (1024 ** 3)
    except Exception:
        disk_free_gb = 0.0

    # Future-proof: match M1, M2, …, M5, M10, etc.
    chip_gen = ""
    m = re.search(r"M(\d+)\s", chip) or re.search(r"M(\d+)$", chip) or re.search(r"M(\d+)", chip)
    if m:
        chip_gen = f"M{m.group(1)}"

    chip_tier = ""
    for t in ("Ultra", "Max", "Pro"):
        if t in chip:
            chip_tier = t
            break

    is_apple_silicon = platform.machine() == "arm64" and ("Apple" in chip or bool(chip_gen))
    swap_risk = ram_gb < 24

    return {
        "chip":             chip,
        "chip_gen":         chip_gen,
        "chip_tier":        chip_tier,
        "ram_gb":           round(ram_gb, 1),
        "ram_gb_int":       int(ram_gb),
        "macos":            macos,
        "macos_major":      macos_major,
        "disk_free_gb":     round(disk_free_gb, 1),
        "swap_risk":        swap_risk,
        "is_apple_silicon": is_apple_silicon,
    }


def tier(ram_gb: float) -> str:
    """Map RAM to model tier name. Works for M1–M5+ and 8–512 GB."""
    if ram_gb >= 96:  return "max"
    if ram_gb >= 64:  return "full"
    if ram_gb >= 32:  return "balanced"
    if ram_gb >= 16:  return "standard"
    if ram_gb >= 8:   return "minimal"
    return "micro"


_TIER_LABELS = {
    "micro":    "Micro    · <8 GB  — Phi-4 mini, Gemma 3 4B (tiny models only)",
    "minimal":  "Minimal  · 8 GB   — Dolphin 8B, Mistral 7B, Qwen3-8B",
    "standard": "Standard · 16 GB  — Gemma 12B, Qwen3-14B, Qwen3-32B 3bit (incl. M5)",
    "balanced": "Balanced · 32 GB  — Qwen3-32B 4bit, Mistral-24B, Huihui-27B",
    "full":     "Full     · 64 GB  — Llama 3.3 70B 4bit, large models",
    "max":      "Max      · 96 GB+ — Multiple large models simultaneously",
}


def report(info: dict) -> str:
    """Human-readable hardware report for setup.sh output."""
    t = tier(info["ram_gb"])
    lines = [
        f"  Chip    : {info['chip']}",
        f"  RAM     : {info['ram_gb_int']} GB unified memory",
        f"  macOS   : {info['macos']}",
        f"  Disk    : {info['disk_free_gb']:.0f} GB free",
        f"  Tier    : {_TIER_LABELS[t]}",
    ]
    if info["swap_risk"]:
        lines.append("  Warning : Low RAM — large models may trigger swap and throttle")
    if not info["is_apple_silicon"]:
        lines.append("  Warning : Not Apple Silicon — MLX requires M1 or later")
    return "\n".join(lines)


if __name__ == "__main__":
    info = detect()
    if "--json" in sys.argv:
        print(json.dumps(info, indent=2))
    else:
        print(report(info))
