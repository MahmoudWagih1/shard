"""
Optional voice mode for LocalAI — push-to-talk via mlx-whisper + sounddevice.

Install voice dependencies:
    pip install mlx-whisper sounddevice

Activate:
    llm --voice

Architecture:
    push_to_talk() → records audio → transcribes with mlx-whisper → returns text
    The returned text is injected into the chat loop as the user's message.

STT backend: mlx-whisper (Whisper via MLX, Apple Silicon optimized, 100% offline)
Default model: whisper-tiny (≈150 MB) — change WHISPER_MODEL for better quality.
    tiny   ≈150 MB  fast, decent quality
    base   ≈290 MB  balanced (recommended)
    small  ≈970 MB  high quality, slower
"""

VOICE_AVAILABLE = False

try:
    import mlx_whisper
    import sounddevice as sd
    import numpy as np
    VOICE_AVAILABLE = True
except ImportError:
    pass

WHISPER_MODEL  = "mlx-community/whisper-base-mlx"  # change for better quality
SAMPLE_RATE    = 16000   # Whisper requires 16 kHz
RECORD_SECONDS = 8       # max recording length per push


def check_available() -> bool:
    """Return True if voice deps are installed."""
    return VOICE_AVAILABLE


def push_to_talk(prompt_fn=None) -> str:
    """
    Record audio and return transcribed text.

    Args:
        prompt_fn: optional callable(msg) to display status messages in terminal

    Returns:
        Transcribed string, or "" if recording failed or nothing was said.
    """
    if not VOICE_AVAILABLE:
        return ""

    def _msg(s: str):
        if prompt_fn:
            prompt_fn(s)

    _msg("  🎙  Recording … (press Enter to stop)")

    frames = []

    def _callback(indata, frame_count, time_info, status):
        frames.append(indata.copy())

    try:
        with sd.InputStream(
            samplerate=SAMPLE_RATE,
            channels=1,
            dtype="float32",
            callback=_callback,
        ):
            input()  # wait for Enter key

    except Exception as e:
        _msg(f"  ⚠  Recording error: {e}")
        return ""

    if not frames:
        return ""

    audio = np.concatenate(frames, axis=0).flatten()

    _msg("  ◈  Transcribing …")
    try:
        result = mlx_whisper.transcribe(
            audio,
            path_or_hf_repo=WHISPER_MODEL,
        )
        text = result.get("text", "").strip()
        return text
    except Exception as e:
        _msg(f"  ⚠  Transcription error: {e}")
        return ""


def install_instructions() -> str:
    return (
        "Voice mode requires additional packages.\n"
        "Install with:\n\n"
        "    pip install mlx-whisper sounddevice\n\n"
        "Or run setup.sh with the --voice flag:\n\n"
        "    bash setup.sh --voice"
    )
