#!/usr/bin/env bash
set -euo pipefail

LOCALAI_DIR="$HOME/.localai"
VENV_DIR="$LOCALAI_DIR/venv"
BIN_DIR="$HOME/bin"
ZSHRC="$HOME/.zshrc"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MARKER_START="# >>> localai-commands >>>"
MARKER_END="# <<< localai-commands <<<"

# Parse optional flags
VOICE_OPT=0
for arg in "$@"; do
    case "$arg" in
        --voice) VOICE_OPT=1 ;;
    esac
done

# ── Colors (for bash output) ──────────────────────────────────────
CY='\033[38;5;51m'
GR='\033[90m'
BD='\033[1m'
YL='\033[38;5;226m'
RD='\033[38;5;196m'
RS='\033[0m'

echo
echo -e "${BD}${CY}  L O C A L A I  ·  S E T U P${RS}"
echo -e "${GR}  Offline LLM for Apple Silicon${RS}"
echo

# ── 0) Hardware detection ─────────────────────────────────────────
echo -e "${CY}[0/5]${RS} Detecting hardware..."

if ! command -v python3 >/dev/null 2>&1; then
    echo -e "${RD}  ✗ python3 not found. Install Python 3 first.${RS}"
    exit 1
fi

# Run detect.py from the project root (stdlib only, no venv needed)
HW_REPORT="$(python3 "$SCRIPT_DIR/detect.py" 2>/dev/null || true)"
HW_JSON="$(python3 "$SCRIPT_DIR/detect.py" --json 2>/dev/null || echo '{}')"

RAM_GB=$(echo "$HW_JSON" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('ram_gb_int',16))" 2>/dev/null || echo "16")
CHIP=$(echo "$HW_JSON"   | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('chip','Apple Silicon'))" 2>/dev/null || echo "Apple Silicon")
IS_AS=$(echo "$HW_JSON"  | python3 -c "import sys,json; d=json.load(sys.stdin); print('yes' if d.get('is_apple_silicon') else 'no')" 2>/dev/null || echo "yes")

echo
echo -e "${HW_REPORT}"
echo

if [ "$IS_AS" != "yes" ]; then
    echo -e "${RD}  ✗ MLX requires Apple Silicon (M1 or later). Exiting.${RS}"
    exit 1
fi

# ── 1) Create virtual environment ────────────────────────────────
echo -e "${CY}[1/5]${RS} Setting up Python venv..."
if [ -d "$VENV_DIR" ]; then
    echo -e "${GR}      Venv exists: $VENV_DIR${RS}"
else
    mkdir -p "$LOCALAI_DIR"
    python3 -m venv "$VENV_DIR"
    echo -e "${GR}      Created: $VENV_DIR${RS}"
fi

# ── 2) Install core dependencies ──────────────────────────────────
echo -e "${CY}[2/5]${RS} Installing dependencies..."
"$VENV_DIR/bin/pip" install --upgrade pip setuptools wheel -q
"$VENV_DIR/bin/pip" install --upgrade mlx-lm psutil -q
echo -e "${GR}      mlx-lm, psutil installed.${RS}"

# ── 3) Model selection ───────────────────────────────────────────
echo -e "${CY}[3/5]${RS} Model selection"
echo
echo -e "  ${GR}Your machine: ${BD}${CHIP}${RS}${GR} · ${BD}${RAM_GB} GB${RS}${GR} RAM${RS}"
echo

# Define models with: key | id | label | min_ram | profile
# Format: "key|model_id|label|min_ram|profile"
# All IDs verified against HuggingFace (March 2026)
# huihui models use original HF safetensors — mlx-lm quantizes on first load (slow, cached after)
declare -a MODEL_LIST=(
    "dolphin|mlx-community/Dolphin3.0-Llama3.1-8B-4bit|Dolphin 3.0 · Llama 3.1 8B · 4bit|8|safe"
    "q14|mlx-community/Qwen3-14B-4bit|Qwen 3 · 14B · 4bit|10|safe"
    "q32_3|mlx-community/Qwen3-32B-3bit|Qwen 3 · 32B · 3bit|14|safe"
    "q32|mlx-community/Qwen3-32B-4bit|Qwen 3 · 32B · 4bit|20|safe"
    "hui27|huihui-ai/Huihui-Qwen3.5-27B-abliterated|Huihui · Qwen3.5 27B · abliterated|16|unfiltered"
    "hui35|huihui-ai/Huihui-Qwen3.5-35B-A3B-abliterated|Huihui · Qwen3.5 35B-A3B · abliterated · MoE|20|unfiltered"
)

# Show available models filtered by RAM
echo -e "  ${BD}Available for your machine (${RAM_GB} GB RAM):${RS}"
echo

IDX=0
declare -a AVAILABLE_MODELS=()
for entry in "${MODEL_LIST[@]}"; do
    IFS='|' read -r mkey mid mlabel mram mprofile <<< "$entry"
    if [ "$mram" -le "$RAM_GB" ]; then
        IDX=$((IDX + 1))
        AVAILABLE_MODELS+=("$entry")
        REC=""
        PROF_TAG=""
        if [ "$mprofile" = "unfiltered" ]; then
            PROF_TAG=" ${YL}[unfiltered]${RS}"
        fi
        # Recommend based on tier
        if [ "$mram" -le 8 ] && [ "$RAM_GB" -le 12 ]; then REC=" ${CY}← recommended${RS}"; fi
        if [ "$mram" -le 14 ] && [ "$RAM_GB" -ge 16 ] && [ "$RAM_GB" -le 24 ]; then REC=" ${CY}← recommended${RS}"; fi
        if [ "$mram" -le 20 ] && [ "$RAM_GB" -ge 32 ] && [ "$RAM_GB" -le 48 ]; then REC=" ${CY}← recommended${RS}"; fi
        if [ "$mram" -le 20 ] && [ "$RAM_GB" -ge 64 ]; then REC=" ${CY}← fits${RS}"; fi
        echo -e "  ${CY}${IDX}${RS}  ${BD}${mlabel}${RS}  ${GR}(min ${mram} GB)${RS}${PROF_TAG}${REC}"
    fi
done

echo
echo -e "  ${GR}Options:${RS}"
echo -e "  ${CY}r${RS}  Recommended set (auto-pick based on RAM)"
echo -e "  ${CY}a${RS}  All models that fit your machine"
echo -e "  ${CY}1-${IDX}${RS}  Pick specific model numbers (comma-separated)"
echo -e "  ${CY}n${RS}  Skip model download (download on first use)"
echo
printf "  Your choice: "
read -r MODEL_CHOICE

# Build list of models to download
MODELS_TO_DL=()
case "${MODEL_CHOICE,,}" in
    r|rec|recommended)
        # Auto-pick based on RAM
        for entry in "${AVAILABLE_MODELS[@]}"; do
            IFS='|' read -r mkey mid mlabel mram mprofile <<< "$entry"
            if [ "$mprofile" = "safe" ]; then
                # Pick the largest safe model that fits comfortably
                if [ "$mram" -le "$((RAM_GB - 4))" ]; then
                    MODELS_TO_DL=("$mid")  # overwrite each time → ends up being largest
                fi
            fi
        done
        ;;
    a|all)
        for entry in "${AVAILABLE_MODELS[@]}"; do
            IFS='|' read -r mkey mid mlabel mram mprofile <<< "$entry"
            MODELS_TO_DL+=("$mid")
        done
        ;;
    n|no|skip)
        echo -e "${GR}  Skipping model download. Models will be downloaded on first use.${RS}"
        MODELS_TO_DL=()
        ;;
    *)
        # Parse comma-separated numbers
        IFS=',' read -ra NUMS <<< "$MODEL_CHOICE"
        for num in "${NUMS[@]}"; do
            num="${num// /}"  # trim spaces
            if [[ "$num" =~ ^[0-9]+$ ]] && [ "$num" -ge 1 ] && [ "$num" -le "${#AVAILABLE_MODELS[@]}" ]; then
                entry="${AVAILABLE_MODELS[$((num - 1))]}"
                IFS='|' read -r mkey mid mlabel mram mprofile <<< "$entry"
                MODELS_TO_DL+=("$mid")
            fi
        done
        ;;
esac

# Download selected models
if [ "${#MODELS_TO_DL[@]}" -gt 0 ]; then
    echo
    echo -e "${GR}  Downloading ${#MODELS_TO_DL[@]} model(s). This may take a while (several GB)...${RS}"
    for mid in "${MODELS_TO_DL[@]}"; do
        echo -e "  ${CY}↓${RS} ${mid}"
        "$VENV_DIR/bin/python" - <<PY
from mlx_lm import load
print(f"    Downloading {repr('${mid}')} ...")
try:
    load('${mid}')
    print("    Done.")
except Exception as e:
    print(f"    Warning: {e}")
    print("    This model may not be available yet. Skipping.")
PY
    done
fi

# ── 4) Voice mode (optional) ──────────────────────────────────────
echo -e "${CY}[4/5]${RS} Voice mode (optional)"

INSTALL_VOICE=0
if [ "$VOICE_OPT" -eq 1 ]; then
    INSTALL_VOICE=1
else
    echo
    echo -e "  ${GR}Voice mode adds offline push-to-talk speech-to-text.${RS}"
    echo -e "  ${GR}Requires ~500 MB extra (mlx-whisper + sounddevice).${RS}"
    echo
    printf "  Install voice support? [y/N] "
    read -r VOICE_ANSWER
    if [[ "${VOICE_ANSWER,,}" == "y" || "${VOICE_ANSWER,,}" == "yes" ]]; then
        INSTALL_VOICE=1
    fi
fi

if [ "$INSTALL_VOICE" -eq 1 ]; then
    echo -e "${GR}  Installing mlx-whisper and sounddevice...${RS}"
    "$VENV_DIR/bin/pip" install --upgrade mlx-whisper sounddevice -q
    echo -e "${GR}  Voice mode installed. Use: llm --voice${RS}"
else
    echo -e "${GR}  Skipped. Install later with: bash setup.sh --voice${RS}"
fi

# ── 5) Write command wrappers + zshrc ─────────────────────────────
echo -e "${CY}[5/5]${RS} Installing command wrappers..."
mkdir -p "$BIN_DIR"

cat > "$BIN_DIR/llm" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail

LOCALAI_DIR="$HOME/.localai"
VENV_PY="$LOCALAI_DIR/venv/bin/python"
CHAT_APP="$LOCALAI_DIR/chat.py"

if [ ! -x "$VENV_PY" ]; then
    echo "Missing Python venv: $VENV_PY"
    echo "Run: ~/.localai/setup.sh"
    exit 1
fi

if [ ! -f "$CHAT_APP" ]; then
    echo "Missing chat app: $CHAT_APP"
    exit 1
fi

exec "$VENV_PY" "$CHAT_APP" "$@"
EOF

cat > "$BIN_DIR/llm-stop" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail

PID_FILE="$HOME/.localai/llm.pid"

if [ ! -f "$PID_FILE" ]; then
    echo "No active LLM session found."
    exit 0
fi

pid="$(cat "$PID_FILE" 2>/dev/null || true)"
if [ -z "${pid:-}" ]; then
    rm -f "$PID_FILE"
    echo "Removed empty PID file."
    exit 0
fi

if ! kill -0 "$pid" 2>/dev/null; then
    rm -f "$PID_FILE"
    echo "Removed stale PID file ($pid not running)."
    exit 0
fi

cmd="$(ps -p "$pid" -o command= 2>/dev/null || true)"
if ! printf '%s' "$cmd" | grep -q ".localai/chat.py"; then
    echo "PID $pid is not .localai/chat.py. Refusing to kill unrelated process."
    echo "Command: ${cmd:-unknown}"
    exit 1
fi

kill "$pid" 2>/dev/null || true

for _ in 1 2 3 4 5; do
    if ! kill -0 "$pid" 2>/dev/null; then
        break
    fi
    sleep 0.2
done

if kill -0 "$pid" 2>/dev/null; then
    kill -9 "$pid" 2>/dev/null || true
fi

rm -f "$PID_FILE"
echo "Stopped LLM session (PID $pid)."
EOF

chmod +x "$BIN_DIR/llm" "$BIN_DIR/llm-stop"

# ── zshrc injection (idempotent) ──────────────────────────────────
touch "$ZSHRC"
tmp="$(mktemp)"
awk -v s="$MARKER_START" -v e="$MARKER_END" '
    $0 == s { skip=1; next }
    $0 == e { skip=0; next }
    !skip { print }
' "$ZSHRC" > "$tmp"
mv "$tmp" "$ZSHRC"

{
    echo
    echo "$MARKER_START"
    echo 'llm() {'
    echo '  "$HOME/bin/llm" "$@"'
    echo '}'
    echo
    echo 'llm-stop() {'
    echo '  "$HOME/bin/llm-stop" "$@"'
    echo '}'
    echo
    echo 'alias llmstop="llm-stop"'
    echo "$MARKER_END"
} >> "$ZSHRC"

# ── Done ─────────────────────────────────────────────────────────
echo
echo -e "${CY}  ╔══════════════════════════════════════╗${RS}"
echo -e "${CY}  ║  ${BD}Setup complete.${RS}${CY}                      ║${RS}"
echo -e "${CY}  ╚══════════════════════════════════════╝${RS}"
echo
echo -e "  ${GR}Open a new terminal tab, then run:${RS}"
echo -e "  ${CY}  llm${RS}"
echo -e "  ${GR}Unfiltered mode:${RS} ${CY}llm --unfiltered${RS}"
if [ "$INSTALL_VOICE" -eq 1 ]; then
    echo -e "  ${GR}Voice mode:${RS}      ${CY}llm --voice${RS}"
fi
echo -e "  ${GR}Stop session:${RS}    ${CY}llm-stop${RS}"
echo
