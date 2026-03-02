"""
Optional voice mode for LocalAI — toggle push-to-talk via mlx-whisper + sounddevice.

Install:
    pip install mlx-whisper sounddevice

Usage in chat:
    v  → start recording  (indicator shows, timer runs)
    v  → stop  + transcribe + send
    q  → cancel recording

Backend: mlx-whisper (Whisper via MLX, Apple Silicon, 100% offline)
"""

VOICE_AVAILABLE = False

try:
    import mlx_whisper
    import sounddevice as sd
    import numpy as np
    VOICE_AVAILABLE = True
except ImportError:
    pass

import threading

WHISPER_MODEL = "mlx-community/whisper-base-mlx"
SAMPLE_RATE   = 16000

# ── Internal state ────────────────────────────────────────────────
_stream    = None
_frames    = []
_recording = False
_lock      = threading.Lock()


def check_available() -> bool:
    return VOICE_AVAILABLE


def is_recording() -> bool:
    return _recording


def start() -> bool:
    """Start background recording. Returns True if started OK."""
    global _stream, _frames, _recording
    if not VOICE_AVAILABLE:
        return False
    with _lock:
        _frames = []
        _recording = True
    try:
        _stream = sd.InputStream(
            samplerate=SAMPLE_RATE,
            channels=1,
            dtype="float32",
            callback=_cb,
        )
        _stream.start()
        return True
    except Exception:
        _recording = False
        return False


def stop() -> str:
    """Stop recording and return transcribed text (blocking)."""
    global _stream, _recording
    with _lock:
        _recording = False
    if _stream:
        try:
            _stream.stop()
            _stream.close()
        except Exception:
            pass
        _stream = None

    with _lock:
        frames = list(_frames)

    if not frames or not VOICE_AVAILABLE:
        return ""
    try:
        audio = np.concatenate(frames).flatten()
        result = mlx_whisper.transcribe(audio, path_or_hf_repo=WHISPER_MODEL)
        return result.get("text", "").strip()
    except Exception:
        return ""


def cancel() -> None:
    """Stop recording, discard audio."""
    global _stream, _recording, _frames
    with _lock:
        _recording = False
        _frames = []
    if _stream:
        try:
            _stream.stop()
            _stream.close()
        except Exception:
            pass
        _stream = None


def _cb(indata, frame_count, time_info, status):
    """sounddevice callback — runs in audio thread."""
    with _lock:
        if _recording:
            _frames.append(indata.copy())


def push_to_talk(prompt_fn=None) -> str:
    """Blocking push-to-talk: records until user presses Enter, then transcribes."""
    if not VOICE_AVAILABLE:
        return ""
    if prompt_fn:
        prompt_fn("  \033[1m\033[38;5;196m●\033[0m REC  press Enter to stop …")
    if not start():
        if prompt_fn:
            prompt_fn("  \033[33m⚠  Failed to start microphone\033[0m")
        return ""
    try:
        input()
    except (EOFError, KeyboardInterrupt):
        cancel()
        return ""
    text = stop()
    return text


def install_instructions() -> str:
    return (
        "Voice mode requires additional packages.\n"
        "Install with:\n\n"
        "    pip install mlx-whisper sounddevice\n\n"
        "Or re-run setup:\n\n"
        "    bash setup.sh --voice"
    )
