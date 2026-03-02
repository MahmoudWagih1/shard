import json
import os
from datetime import datetime
from typing import Any, Dict, List

LOG_DIR = os.path.expanduser("~/.localai/logs")

_enabled = False


def set_logging(enabled: bool) -> None:
    global _enabled
    _enabled = enabled


def log_interaction(
    query: str,
    steps: List[Dict[str, Any]],
    final_answer: str,
    total_steps: int,
) -> str:
    """Write one turn to session log if logging is enabled, otherwise no-op."""
    if not _enabled:
        return ""
    try:
        os.makedirs(LOG_DIR, exist_ok=True)
        today = datetime.now().strftime("%Y-%m-%d_%H%M%S")
        path = os.path.join(LOG_DIR, f"{today}.jsonl")
        entry = {
            "ts": datetime.now().isoformat(),
            "query": query,
            "answer": final_answer,
        }
        with open(path, "a") as f:
            f.write(json.dumps(entry, ensure_ascii=False) + "\n")
        return path
    except Exception:
        return ""


def list_logs() -> list:
    """Return list of log file paths, newest first."""
    if not os.path.isdir(LOG_DIR):
        return []
    files = [os.path.join(LOG_DIR, f) for f in os.listdir(LOG_DIR) if f.endswith(".jsonl")]
    files.sort(reverse=True)
    return files


def delete_all_logs() -> int:
    """Delete all session logs. Returns count of deleted files."""
    files = list_logs()
    for f in files:
        try:
            os.remove(f)
        except OSError:
            pass
    return len(files)
