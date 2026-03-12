#!/usr/bin/env bash
# uninstall-oneshot.sh — Full OpenClaw uninstall. Run by one-shot or manually.
# Usage: uninstall-oneshot.sh [OPTIONS]
#   --notify-email EMAIL   Send email when done
#   --notify-ntfy TOPIC    Send ntfy notification when done
#   --preserve LIST        Backup before delete: skills,logs,preferences,credentials or "all"
#   --no-backup            Skip backup (default: backup with "all" unless --no-backup)
#   --all-profiles         Also remove ~/.openclaw-* profile dirs (default: only STATE_DIR)

set -e

LOG_FILE="/tmp/openclaw-uninstall.log"
NOTIFY_EMAIL=""
NOTIFY_NTFY=""
PRESERVE=""
NO_BACKUP=false
ALL_PROFILES=false
declare -a ERRORS=()

while [[ $# -gt 0 ]]; do
  case "$1" in
    --notify-email)  NOTIFY_EMAIL="$2"; shift 2 ;;
    --notify-ntfy)   NOTIFY_NTFY="$2"; shift 2 ;;
    --preserve)      PRESERVE="$2"; shift 2 ;;
    --no-backup)     NO_BACKUP=true; shift ;;
    --all-profiles)  ALL_PROFILES=true; shift ;;
    *) shift ;;
  esac
done

log() { echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*" | tee -a "$LOG_FILE"; }

# Default: backup all unless --no-backup
if [[ "$NO_BACKUP" != "true" ]] && [[ -z "$PRESERVE" ]]; then
  PRESERVE="all"
fi

log "=== OpenClaw uninstall started ==="

STATE_DIR="${OPENCLAW_STATE_DIR:-$HOME/.openclaw}"
# Expand ~ to $HOME for validation
STATE_DIR="${STATE_DIR/#\~/$HOME}"
# Resolve to canonical path when dir exists (for validation)
STATE_DIR_CANON="$STATE_DIR"
if [[ -d "$STATE_DIR" ]]; then
  STATE_DIR_CANON="$(cd -P "$STATE_DIR" 2>/dev/null && pwd)" || STATE_DIR_CANON="$STATE_DIR"
fi

# --- Path safety: never delete outside $HOME or system paths ---
validate_state_dir() {
  local dir="$1"
  [[ -z "$dir" ]] && return 1
  case "$dir" in
    "$HOME") return 1 ;;   # Never delete $HOME itself
    "$HOME"/*) ;;
    *) log "SAFETY: Rejecting STATE_DIR outside HOME: $dir"; return 1 ;;
  esac
  case "$(basename "$dir")" in
    .openclaw|.openclaw-*) return 0 ;;
    *) log "SAFETY: Rejecting non-OpenClaw path: $dir"; return 1 ;;
  esac
}

if ! validate_state_dir "$STATE_DIR_CANON"; then
  log "FATAL: Invalid OPENCLAW_STATE_DIR. Use default ~/.openclaw or a path under \$HOME matching .openclaw*"
  exit 1
fi

# 0. Backup selected data before removing (unless --no-backup)
if [[ -n "$PRESERVE" ]] && [[ "$NO_BACKUP" != "true" ]] && [[ -d "$STATE_DIR" ]]; then
  BACKUP_DIR="$HOME/.openclaw-backup-$(date '+%Y%m%d-%H%M%S')"
  mkdir -p "$BACKUP_DIR" || { log "ERROR: Failed to create backup dir"; ERRORS+=("backup-dir"); }
  if [[ ${#ERRORS[@]} -eq 0 ]]; then
    log "Backing up to $BACKUP_DIR"

    preserve_all=false
    [[ "$PRESERVE" == "all" ]] && preserve_all=true

    preserve_item() { [[ "$preserve_all" == "true" ]] || [[ ",$PRESERVE," == *",$1,"* ]]; }

    preserve_item "skills" && [[ -d "$STATE_DIR/skills" ]] && { cp -r "$STATE_DIR/skills" "$BACKUP_DIR/" 2>/dev/null && log "Preserved: skills" || log "Preserve skills failed"; }
    preserve_item "logs" && [[ -d "$STATE_DIR/sessions" ]] && { cp -r "$STATE_DIR/sessions" "$BACKUP_DIR/" 2>/dev/null && log "Preserved: sessions" || log "Preserve sessions failed"; }
    preserve_item "preferences" && [[ -f "$STATE_DIR/openclaw.json" ]] && { cp "$STATE_DIR/openclaw.json" "$BACKUP_DIR/" 2>/dev/null && log "Preserved: openclaw.json" || log "Preserve preferences failed"; }
    if preserve_item "credentials"; then
      [[ -d "$STATE_DIR/credentials" ]] && { cp -r "$STATE_DIR/credentials" "$BACKUP_DIR/" 2>/dev/null && log "Preserved: credentials" || log "Preserve credentials failed"; }
      if [[ -d "$STATE_DIR/agents" ]]; then
        for agent_dir in "$STATE_DIR/agents"/*/agent; do
          [[ -d "$agent_dir" ]] && [[ -f "$agent_dir/auth.json" ]] || continue
          agent_name=$(basename "$(dirname "$agent_dir")")
          mkdir -p "$BACKUP_DIR/agents/$agent_name/agent"
          cp "$agent_dir/auth.json" "$BACKUP_DIR/agents/$agent_name/agent/" 2>/dev/null && log "Preserved: agents/$agent_name/agent/auth.json" || true
        done
      fi
    fi
    log "Backup complete: $BACKUP_DIR"
  fi
fi

# 1. Stop gateway (if CLI available)
if command -v openclaw &>/dev/null; then
  log "Stopping gateway..."
  openclaw gateway stop 2>/dev/null || true
  log "Uninstalling gateway service..."
  openclaw gateway uninstall 2>/dev/null || true
fi

# 2. Manual service removal (if CLI gone or as backup)
case "$(uname -s)" in
  Darwin)
    launchctl bootout "gui/$UID/ai.openclaw.gateway" 2>/dev/null || true
    rm -f ~/Library/LaunchAgents/ai.openclaw.gateway.plist
    for f in ~/Library/LaunchAgents/com.openclaw.*.plist; do
      [[ -f "$f" ]] && rm -f "$f"
    done
    ;;
  Linux)
    systemctl --user disable --now openclaw-gateway.service 2>/dev/null || true
    rm -f ~/.config/systemd/user/openclaw-gateway.service
    systemctl --user daemon-reload 2>/dev/null || true
    ;;
esac

# 3. Delete state dir (validated above)
if [[ -d "$STATE_DIR" ]]; then
  log "Removing state dir: $STATE_DIR"
  rm -rf "$STATE_DIR" || { log "ERROR: Failed to remove $STATE_DIR"; ERRORS+=("state-dir"); }
fi

# 4. Delete profile dirs (only when --all-profiles; exclude .openclaw-backup-*)
if [[ "$ALL_PROFILES" == "true" ]]; then
  for d in "$HOME"/.openclaw-*; do
    [[ -d "$d" ]] || continue
    [[ "$d" == *"/.openclaw-backup-"* ]] && continue
    # Safety: only remove paths under HOME that look like OpenClaw profile dirs
    case "$(basename "$d")" in
      .openclaw-backup-*) continue ;;
      .openclaw-*)
        log "Removing profile dir: $d"
        rm -rf "$d" || { log "ERROR: Failed to remove $d"; ERRORS+=("profile:$d"); }
        ;;
      *) log "SKIP: Ignoring non-profile dir $d" ;;
    esac
  done
else
  log "Skipping profile dirs (use --all-profiles to remove ~/.openclaw-*)"
fi

# 5. Remove CLI
for pm in npm pnpm bun; do
  if command -v "$pm" &>/dev/null; then
    if "$pm" list -g openclaw --depth=0 &>/dev/null 2>&1; then
      log "Removing npm package: $pm remove -g openclaw"
      "$pm" remove -g openclaw 2>/dev/null || { log "WARNING: $pm remove -g openclaw failed"; ERRORS+=("cli"); }
      break
    fi
  fi
done

# 6. macOS app
if [[ "$(uname -s)" == "Darwin" ]] && [[ -d "/Applications/OpenClaw.app" ]]; then
  log "Removing macOS app"
  rm -rf /Applications/OpenClaw.app || { log "ERROR: Failed to remove /Applications/OpenClaw.app"; ERRORS+=("macos-app"); }
fi

# Final report
if [[ ${#ERRORS[@]} -gt 0 ]]; then
  log "=== Uninstall completed with errors ==="
  log "Failed steps: ${ERRORS[*]}"
  log "Check $LOG_FILE for details. You may need to remove some items manually."
else
  log "=== Uninstall complete ==="
fi

# Notify
if [[ -n "$NOTIFY_EMAIL" ]]; then
  if command -v mail &>/dev/null; then
    echo "OpenClaw uninstalled. Details: $LOG_FILE" | mail -s "OpenClaw Uninstall Complete" "$NOTIFY_EMAIL" 2>/dev/null || log "Email send failed (mail unavailable)"
  else
    log "Email notification skipped (mail command unavailable)"
  fi
fi

if [[ -n "$NOTIFY_NTFY" ]]; then
  if command -v curl &>/dev/null; then
    curl -s -d "OpenClaw uninstalled" "https://ntfy.sh/$NOTIFY_NTFY" &>/dev/null || log "ntfy send failed"
  else
    log "ntfy notification skipped (curl unavailable)"
  fi
fi

[[ ${#ERRORS[@]} -gt 0 ]] && exit 1
exit 0
