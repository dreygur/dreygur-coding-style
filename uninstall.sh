#!/usr/bin/env bash
set -euo pipefail

SKILL_NAME="dreygur-coding-style"
DEST="${HOME}/.claude/skills/${SKILL_NAME}"

GREEN='\033[0;32m'; NC='\033[0m'
log() { echo -e "${GREEN}[+]${NC} $*"; }

if [[ -d "$DEST" ]]; then
  rm -rf "$DEST"
  log "Removed ${DEST}."
else
  log "Not installed at ${DEST}, nothing to do."
fi

log "Restart Claude Code for changes to take effect."
