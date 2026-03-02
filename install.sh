#!/usr/bin/env bash
# localai — one-command install (curl or run from repo)
# Usage: bash <(curl -fsSL https://raw.githubusercontent.com/YOUR_USERNAME/localai/main/install.sh)
set -euo pipefail

REPO_URL="${LOCALAI_REPO_URL:-https://github.com/magido87/shard.git}"
LOCALAI_DIR="${HOME}/.localai"
BRANCH="${LOCALAI_BRANCH:-master}"

CY='\033[38;5;51m'; GR='\033[90m'; BD='\033[1m'
YL='\033[38;5;226m'; RD='\033[38;5;196m'; RS='\033[0m'
OK="${CY}✓${RS}"; FAIL="${RD}✗${RS}"

echo
echo -e "  ${BD}${CY}localai${RS}  ${GR}— offline LLM for Mac${RS}"
echo
echo -e "  ${GR}Vi installerar localai så att du kan skriva ${CY}llm${GR} i vilken terminal som helst.${RS}"
echo

# ── macOS + Apple Silicon ─────────────────────────────────────────
if [[ "$(uname -s)" != "Darwin" ]]; then
    echo -e "  ${FAIL} localai kräver macOS.${RS}"
    echo -e "  ${GR}Kör detta på en Mac.${RS}"
    exit 1
fi

ARCH="$(uname -m)"
if [[ "$ARCH" != "arm64" ]]; then
    echo -e "  ${FAIL} localai kräver Apple Silicon (M1, M2, M3, M4 eller senare).${RS}"
    echo -e "  ${GR}Den här maskinen rapporterar: ${ARCH}.${RS}"
    exit 1
fi

if ! command -v python3 >/dev/null 2>&1; then
    echo -e "  ${FAIL} python3 hittades inte.${RS}"
    echo -e "  ${GR}Installera Xcode Command Line Tools: ${CY}xcode-select --install${RS}"
    exit 1
fi

# ── Clone or update ~/.localai ────────────────────────────────────
if [[ -d "$LOCALAI_DIR" ]]; then
    if [[ -d "$LOCALAI_DIR/.git" ]]; then
        echo -e "  ${GR}Uppdaterar ${LOCALAI_DIR}…${RS}"
        (cd "$LOCALAI_DIR" && git pull --quiet 2>/dev/null || true)
        echo -e "  ${OK} Klar${RS}"
    else
        echo -e "  ${YL}${LOCALAI_DIR} finns men är inte ett git-repo.${RS}"
        echo -e "  ${GR}Vill du flytta den till ${LOCALAI_DIR}.bak och klona på nytt? [y/N]${RS} "
        read -r answer
        if [[ "${answer,,}" == "y" || "${answer,,}" == "yes" ]]; then
            mv "$LOCALAI_DIR" "${LOCALAI_DIR}.bak"
            echo -e "  ${OK} Klonar till ${LOCALAI_DIR}…${RS}"
            git clone --depth 1 --branch "$BRANCH" "$REPO_URL" "$LOCALAI_DIR"
        else
            echo -e "  ${GR}Avbryter. Kör ${CY}bash ${LOCALAI_DIR}/setup.sh${GR} manuellt om du vill.${RS}"
            exit 0
        fi
    fi
else
    echo -e "  ${GR}Klonar till ${LOCALAI_DIR}…${RS}"
    git clone --depth 1 --branch "$BRANCH" "$REPO_URL" "$LOCALAI_DIR"
    echo -e "  ${OK} Klonat${RS}"
fi

SETUP="$LOCALAI_DIR/setup.sh"
if [[ ! -f "$SETUP" ]]; then
    echo -e "  ${FAIL} setup.sh hittades inte i ${LOCALAI_DIR}.${RS}"
    exit 1
fi

# ── Run setup ─────────────────────────────────────────────────────
echo
bash "$SETUP" "$@"
echo
echo -e "  ${OK} ${BD}Öppna ny flik, skriv ${CY}llm${RS} ${BD}och börja skriva. Inget mer.${RS}"
echo
