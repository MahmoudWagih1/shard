#!/usr/bin/env bash
# localai — one-command install
# Usage: bash <(curl -fsSL https://raw.githubusercontent.com/magido87/shard/master/install.sh)
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
echo -e "  ${GR}We'll set up localai so you can type ${CY}llm${GR} in any terminal.${RS}"
echo

# ── macOS + Apple Silicon ─────────────────────────────────────────
if [[ "$(uname -s)" != "Darwin" ]]; then
    echo -e "  ${FAIL} localai requires macOS."
    echo -e "  ${GR}Run this on a Mac.${RS}"
    exit 1
fi

ARCH="$(uname -m)"
if [[ "$ARCH" != "arm64" ]]; then
    echo -e "  ${FAIL} localai requires Apple Silicon (M1 or later)."
    echo -e "  ${GR}This machine reports: ${ARCH}.${RS}"
    exit 1
fi

if ! command -v python3 >/dev/null 2>&1; then
    echo -e "  ${FAIL} python3 not found."
    echo -e "  ${GR}Install Xcode Command Line Tools: ${CY}xcode-select --install${RS}"
    exit 1
fi

# ── Clone or update ~/.localai ────────────────────────────────────
if [[ -d "$LOCALAI_DIR" ]]; then
    if [[ -d "$LOCALAI_DIR/.git" ]]; then
        echo -ne "  ${GR}Updating ${LOCALAI_DIR}…${RS}"
        (cd "$LOCALAI_DIR" && git pull --quiet 2>/dev/null || true)
        echo -e "\r  ${OK} Updated                          "
    else
        echo -e "  ${YL}${LOCALAI_DIR} exists but is not a git repo.${RS}"
        echo -ne "  ${GR}Move it to ${LOCALAI_DIR}.bak and clone fresh? [y/N]: ${RS}"
        read -r answer
        if [[ "${answer,,}" == "y" || "${answer,,}" == "yes" ]]; then
            mv "$LOCALAI_DIR" "${LOCALAI_DIR}.bak"
            echo -ne "  ${GR}Cloning…${RS}"
            git clone --depth 1 --branch "$BRANCH" "$REPO_URL" "$LOCALAI_DIR"
            echo -e "\r  ${OK} Cloned              "
        else
            echo -e "  ${GR}Cancelled. Run ${CY}bash ${LOCALAI_DIR}/setup.sh${GR} manually.${RS}"
            exit 0
        fi
    fi
else
    echo -ne "  ${GR}Cloning…${RS}"
    git clone --depth 1 --branch "$BRANCH" "$REPO_URL" "$LOCALAI_DIR"
    echo -e "\r  ${OK} Cloned              "
fi

SETUP="$LOCALAI_DIR/setup.sh"
if [[ ! -f "$SETUP" ]]; then
    echo -e "  ${FAIL} setup.sh not found in ${LOCALAI_DIR}."
    exit 1
fi

# ── Run setup ─────────────────────────────────────────────────────
echo
bash "$SETUP" "$@"
