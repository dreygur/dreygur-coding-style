#!/usr/bin/env bash
# Alternative installer — no Node.js required.
# Prefer: npx skills add dreygur/dreygur-coding-style
set -euo pipefail

REPO_URL="https://github.com/dreygur/dreygur-coding-style"
SKILL_NAME="dreygur-coding-style"
DEST="${HOME}/.claude/skills/${SKILL_NAME}"

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; NC='\033[0m'
log()   { echo -e "${GREEN}[+]${NC} $*"; }
warn()  { echo -e "${YELLOW}[!]${NC} $*"; }
error() { echo -e "${RED}[-]${NC} $*" >&2; exit 1; }

command -v git &>/dev/null || error "git is required."

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

log "Downloading skill..."
git clone --depth=1 "$REPO_URL" "$TMP/repo" -q

log "Installing to ${DEST}..."
rm -rf "$DEST"
mkdir -p "$(dirname "$DEST")"
cp -r "$TMP/repo/skills/${SKILL_NAME}" "$DEST"

log "Done. Restart Claude Code for the skill to take effect."
log "To update: run this script again."
log "To remove: rm -rf \"${DEST}\""
