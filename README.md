# localai

**Offline LLM chat for Apple Silicon. No cloud. No history. No bullshit.**

Run powerful open-source language models locally in your terminal — from MacBook Air M1 to M4 Max. One command to start, one to stop.

```
llm
```

---

## Install

**One command** (replace `YOUR_USERNAME` with the repo owner if you forked):

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/YOUR_USERNAME/localai/main/install.sh)
```

Then open a new terminal tab and run `llm`. First time you get a short wizard (model + personality); after that you just type `llm` and chat.

**Alternativt — git:**

```bash
git clone https://github.com/YOUR_USERNAME/localai.git
cd localai
bash setup.sh
```

**Alternativt — Homebrew** (when tap is available):

```bash
brew tap YOUR_USERNAME/localai && brew install localai
```

Setup detects your Mac (M1–M5, any RAM), suggests a model that fits, and installs the `llm` command in `~/bin/`. Restart the terminal or run `source ~/.zshrc` if `llm` is not found.

---

## Features

- **100% offline** — no network calls after model download
- **No chat history** — nothing is ever written to disk
- **Hardware-aware** — setup detects your chip and RAM, recommends what fits
- **Multiple models** — from compact 8B to abliterated 32B, matched to your machine
- **11 personalities** — from terse hacker to philosopher, configurable per session
- **Persistent config** — theme, personality and temperature survive restarts
- **Unfiltered mode** — explicit opt-in for uncensored models (`llm --unfiltered`)
- **Voice mode** — optional offline push-to-talk via mlx-whisper (`llm --voice`)
- **Pure CLI** — ANSI colors, streaming output, no GUI, no Electron

---

## Requirements

- **macOS 13 Ventura** or later
- **Apple Silicon** (M1, M2, M3, M4, M5 — any variant)
- **Python 3.10+**
- **8 GB unified memory** minimum (16 GB+ recommended)

---

## Models

| Key | Model | RAM needed | Notes |
|-----|-------|-----------|-------|
| `q14` | Qwen3.5-14B-Instruct 4bit | ~10 GB | Default for 16 GB machines |
| `q14_3` | Qwen3.5-14B-Instruct 3bit | ~8 GB | Fits 8 GB with care |
| `q32` | Qwen3-32B-Instruct 4bit | ~20 GB | Recommended for 32 GB |
| `q32_3` | Qwen3-32B-Instruct 3bit | ~14 GB | Fits 16 GB |
| `hui27` | Huihui-Qwen3.5-27B abliterated | ~16 GB | Unfiltered mode only |
| `hui32` | Huihui-Qwen3.5-32B abliterated | ~20 GB | Unfiltered mode only |
| `dolphin` | Dolphin 3.0 Llama 3.1 8B | ~5 GB | Fast fallback for 8 GB |
| `qwen25` | Qwen 2.5-14B Instruct | ~9 GB | Legacy / fallback |

Setup recommends the right pack for your machine automatically.

---

## Usage

```bash
llm                  # start with last used model and config
llm --unfiltered     # unlock abliterated models (confirmation required)
llm --voice          # enable push-to-talk voice input (mlx-whisper required)
llm-stop             # kill a running session
```

### In-chat commands

| Command | Action |
|---------|--------|
| `q` | Quit |
| `r` | Reset chat (clear context) |
| `s` | Settings (temp, personality, custom instructions) |
| `h` | Help |
| `rensa` / `clear` | Clear screen |
| `/theme` | Switch color theme |

---

## Voice Mode

Voice mode requires an optional install:

```bash
bash setup.sh --voice
```

This installs `mlx-whisper` and `sounddevice` (~500 MB). Everything runs offline.

Start with:
```bash
llm --voice
```

Hold a key to talk, release to transcribe. Output goes straight into the chat.

---

## Unfiltered Mode

Unfiltered mode unlocks abliterated models (huihui-27B, huihui-32B) that are not shown in standard mode.

```bash
llm --unfiltered
```

You will be prompted to confirm. No extra config needed.

---

## Privacy

- **No logging**: `agent.py` exists but logging is disabled by design
- **No telemetry**: zero network calls during chat
- **No history file**: conversation lives only in RAM, gone on exit
- **No model weights in this repo**: all models download from Hugging Face on first setup

---

## Config

Settings are saved to `~/.localai/config.json` (excluded from git):

```json
{
  "model": "q32",
  "theme": "neon",
  "personality": 3,
  "temp": 0.72
}
```

Wipe everything:
```bash
bash wipe_session.sh
```

---

## Project structure

```
localai/
├── install.sh       One-command install (curl) — clone/update + setup.sh
├── setup.sh         Install — venv, deps, hardware check, model download, voice opt-in
├── chat.py          Main app — model picker, chat loop, UI, themes, personalities
├── config.py        Persistent config (~/.localai/config.json)
├── voice.py         Optional voice mode (mlx-whisper, import-guarded)
├── detect.py        Hardware detection — chip, RAM, disk, swap risk (stdlib only)
├── agent.py         Logging stub (disabled for privacy)
├── llm.sh           ~/bin/llm wrapper source
├── llm-stop.sh      ~/bin/llm-stop wrapper source
├── wipe_session.sh  Safe session cleanup
└── docs/
    └── BREW_TAP.md  Homebrew tap formula sketch (optional)
```

---

## Hardware tiers

Setup auto-detects and recommends:

| RAM | Recommended pack | Notes |
|-----|-----------------|-------|
| 8 GB | Minimal: Dolphin 8B or Qwen3.5-14B 3bit | Swap risk with 14B |
| 16 GB | Standard: Qwen3.5-14B 4bit or Qwen3-32B 3bit | Good balance |
| 32 GB | Balanced: Qwen3-32B 4bit or Huihui-27B | Full quality |
| 64 GB | Full: Huihui-32B 4bit | Uncensored at full quality |
| 96 GB+ | Max: Qwen3-32B 8bit or MoE variants | No constraints |

---

## License

MIT — see [LICENSE](LICENSE)
