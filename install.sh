#!/usr/bin/env bash
# Installs the custom Claude Code status line on the current host.
#
# Idempotent: safe to re-run. Copies statusline.sh into ~/.claude/ and
# merges the statusLine entry into ~/.claude/settings.json without
# clobbering existing keys.

set -euo pipefail

REPO_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
CLAUDE_DIR="${HOME}/.claude"
SETTINGS="${CLAUDE_DIR}/settings.json"
TARGET="${CLAUDE_DIR}/statusline.sh"
SOURCE="${REPO_DIR}/statusline.sh"

log()  { printf '\033[1;34m==>\033[0m %s\n' "$*"; }
warn() { printf '\033[1;33m!! \033[0m %s\n' "$*" >&2; }
die()  { printf '\033[1;31mxx \033[0m %s\n' "$*" >&2; exit 1; }

[[ -f "$SOURCE" ]] || die "statusline.sh missing next to install.sh ($SOURCE)"

install_jq() {
  if command -v jq >/dev/null 2>&1; then
    log "jq already installed ($(jq --version))"
    return
  fi
  log "Installing jq..."
  if   command -v apt-get >/dev/null 2>&1; then sudo apt-get update -qq && sudo apt-get install -y jq
  elif command -v dnf     >/dev/null 2>&1; then sudo dnf install -y jq
  elif command -v pacman  >/dev/null 2>&1; then sudo pacman -S --noconfirm jq
  elif command -v brew    >/dev/null 2>&1; then brew install jq
  else die "No supported package manager found. Install jq manually and re-run."
  fi
}

install_script() {
  mkdir -p "$CLAUDE_DIR"
  install -m 0755 "$SOURCE" "$TARGET"
  log "Installed status line script to $TARGET"
}

merge_settings() {
  local tmp
  tmp=$(mktemp)

  if [[ -f "$SETTINGS" ]]; then
    if ! jq empty "$SETTINGS" 2>/dev/null; then
      rm -f "$tmp"
      die "$SETTINGS exists but is not valid JSON; refusing to overwrite. Fix it and re-run."
    fi
    jq --arg cmd "$TARGET" \
       '. + {statusLine: {type: "command", command: $cmd}}' \
       "$SETTINGS" > "$tmp"
  else
    jq -n --arg cmd "$TARGET" \
       '{statusLine: {type: "command", command: $cmd}}' > "$tmp"
  fi

  mv "$tmp" "$SETTINGS"
  log "Merged statusLine entry into $SETTINGS"
}

main() {
  install_jq
  install_script
  merge_settings
  log "Done. Restart Claude Code to see the new status line."
}

main "$@"
