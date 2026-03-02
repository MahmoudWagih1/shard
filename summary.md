# LocalAI — Sessionssammanfattning

## Vad vi gjort

### Fas 1 — Fundament
- Lade till `LICENSE` (MIT)
- Skapade `requirements.txt` (`mlx-lm>=0.22.0`, `psutil>=6.0.0`)
- Skapade `README.md` med full dokumentation
- Uppdaterade `.gitignore` (lade till `config.json`, `*.log`)
- Skapade `CONTRIBUTING.md`

### Fas 2 — Modeller + Hardware
- Skapade `detect.py` — stdlib-only hardware detection (chip, RAM, disk, swap-risk, macOS)
- Skapade `config.py` — persistent config via `~/.localai/config.json`
- Uppdaterade `MODELS` dict i `chat.py` från 3 till 8 modeller med `min_ram` och `profile`
- Verifierade alla HuggingFace-ID:n (hittade att `hui32` inte finns, ersatte med `hui35`)
- Uppdaterade `setup.sh` med interaktiv modellmeny och hardware-detection

### Fas 3 — Safe/Unfiltered
- Lade till `--unfiltered` flag med bekräftelseprompt ("Type yes")
- Dynamisk modellpicker filtrerar på profil — huihui-modeller syns bara i unfiltered mode

### Fas 4 — Persistent Config
- `config.py` sparar model, theme, personality, temp till `~/.localai/config.json`
- Laddas vid start, sparas vid quit/reset/settings-ändring

### Fas 5 — Voice Mode
- Skapade `voice.py` med toggle-API: `start()`, `stop()`, `cancel()`, `is_recording()`
- Import-guard — faller tyst om `mlx-whisper`/`sounddevice` saknas
- Lade till voice opt-in i `setup.sh`

### Fas 6 — UI Overhaul (senaste sessionen)
- **Banner-refactor** — ersatte `_banner_dolphin/qwen/qwen35/_banner_generic` med en enda
  dynamisk `_banner(key)` som läser från MODELS-dikt. Device detekteras alltid dynamiskt
  (`mx.device_info()`), ingen hårdkodad "M3" fallback (använder "Apple Silicon")
- **Model picker** — ny titel "SELECT YOUR LOCAL INTELLIGENCE CORE", chip-namn i header,
  RAM-bar per modell visar proportionell användning mot total RAM
- **UNLOCK screen** — unfiltered mode kräver nu att man skriver `UNLOCK` (ej "yes"),
  med en ritual-stilad box-UI i rött
- **Boot sequence animation** — animerade steg när modell laddas:
  Initializing Metal backend → Allocating unified memory → Loading weights →
  Optimizing kernels → AI core online
- **Statusbar** — efter varje AI-svar visas: Tokens | Latency | t/s | Temp | GPU
- **`v`-hotkey** — toggle voice mode i chatten utan att starta om
- **`push_to_talk`** — lade till funktion i `voice.py` (saknades, bröt import)

### Bugfixar
- **"Apple Apple M3"** — `device_name` returnerar redan "Apple M3", fixade med `.removeprefix("Apple ")`
- **Python 3.14 venv** — bröt scipy/whisper deps; återskapade venv på Python 3.12.12
- Deployade live-kopian: `cp ~/Projects/localai/*.py ~/.localai/`
- Lade till `alias llm-deploy` i `~/.zshrc`

### GitHub
- Pushade till `https://github.com/magido87/shard`
- Två commits: initial clone + banner bugfix

---

## Återstår (ej gjort)

- **Model comparison overlay** — tryck `i` på en modell i picker för Speed/Reasoning/Memory-diff
- **Quick-switch `m`** — byt modell utan att starta om (reload i runtime)
- **Expert mode** — toggle i settings: visa KV-cache, logits, raw prompt
- **Disk footprint** i setup — visa GB per modell + summa
- **Theme previews** i settings — visa ASCII-preview av neon/ocean/etc
- GitHub-polish: README-badge, star-länk i setup-avslut
