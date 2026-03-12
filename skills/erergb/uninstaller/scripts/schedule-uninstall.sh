#!/usr/bin/env bash
# schedule-uninstall.sh — Create launchd/systemd one-shot to run uninstall after delay.
# Agent calls this; script returns immediately after scheduling.
# Usage: schedule-uninstall.sh [OPTIONS]
#   --notify-email EMAIL   Send email when done
#   --notify-ntfy TOPIC    Send ntfy notification when done
#   --preserve LIST        Backup: skills,logs,preferences,credentials or "all"
#   --no-backup            Skip backup
#   --all-profiles         Also remove ~/.openclaw-* profile dirs
# Requires: host=gateway (must run on host, not in sandbox)

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
UNINSTALL_SCRIPT="${SCRIPT_DIR}/uninstall-oneshot.sh"
LOG_FILE="/tmp/openclaw-uninstall.log"
DELAY=15

NOTIFY_EMAIL=""
NOTIFY_NTFY=""
PRESERVE=""
NO_BACKUP=false
ALL_PROFILES=false
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

EXTRA_ARGS=()
[[ -n "$NOTIFY_EMAIL" ]] && EXTRA_ARGS+=(--notify-email "$NOTIFY_EMAIL")
[[ -n "$NOTIFY_NTFY" ]] && EXTRA_ARGS+=(--notify-ntfy "$NOTIFY_NTFY")
[[ -n "$PRESERVE" ]] && EXTRA_ARGS+=(--preserve "$PRESERVE")
[[ "$NO_BACKUP" == "true" ]] && EXTRA_ARGS+=(--no-backup)
[[ "$ALL_PROFILES" == "true" ]] && EXTRA_ARGS+=(--all-profiles)

# Sandbox detection: if running in Docker, one-shot would be created inside container
# and lost when gateway stops. Must run on host (host=gateway).
if [[ -f /.dockerenv ]]; then
  echo "Error: Docker sandbox detected. schedule-uninstall must run on the host."
  echo "Ensure Agent calls exec with host=gateway, or run this script manually on the host."
  exit 1
fi
if [[ -f /proc/1/cgroup ]] && grep -q docker /proc/1/cgroup 2>/dev/null; then
  echo "Error: Docker sandbox detected. schedule-uninstall must run on the host."
  echo "Ensure Agent calls exec with host=gateway, or run this script manually on the host."
  exit 1
fi

# Build command string for one-shot
ARG_STR=""
for a in "${EXTRA_ARGS[@]}"; do
  ARG_STR="$ARG_STR '$a'"
done
CMD="sleep $DELAY && '$UNINSTALL_SCRIPT' $ARG_STR"

case "$(uname -s)" in
  Darwin)
    if launchctl submit -l openclaw-uninstall -o "$LOG_FILE" -e "$LOG_FILE" -- \
      /bin/bash -c "$CMD" 2>/dev/null; then
      echo "macOS uninstall scheduled (launchctl), will run in ~${DELAY}s."
    else
      # Fallback: create wrapper script + plist (avoids XML escaping of CMD)
      WRAPPER=$(mktemp /tmp/openclaw-uninstall-XXXXXX.sh)
      EXEC_LINE="exec '$UNINSTALL_SCRIPT'"
      for a in "${EXTRA_ARGS[@]}"; do
        safe=$(printf '%s' "$a" | sed "s/'/'\\\\''/g")
        EXEC_LINE="$EXEC_LINE '$safe'"
      done
      cat > "$WRAPPER" << WRAPEOF
#!/bin/bash
sleep $DELAY
$EXEC_LINE
WRAPEOF
      chmod +x "$WRAPPER"
      PLIST_DIR="${TMPDIR:-/tmp}"
      PLIST="$PLIST_DIR/openclaw-uninstall-$$.plist"
      cat > "$PLIST" << PLISTEOF
<?xml version="1.0"?>
<plist version="1.0"><dict>
  <key>Label</key><string>openclaw-uninstall</string>
  <key>ProgramArguments</key><array>
    <string>$WRAPPER</string>
  </array>
  <key>RunAtLoad</key><true/>
  <key>StandardOutPath</key><string>$LOG_FILE</string>
  <key>StandardErrorPath</key><string>$LOG_FILE</string>
</dict></plist>
PLISTEOF
      launchctl load "$PLIST" 2>/dev/null && echo "macOS uninstall scheduled (plist), will run in ~${DELAY}s." || {
        echo "Error: launchctl unavailable. Run manually: $UNINSTALL_SCRIPT"
        rm -f "$PLIST" "$WRAPPER"
        exit 1
      }
    fi
    ;;
  Linux)
    if systemd-run --user --onetime --unit=openclaw-uninstall \
      /bin/bash -c "$CMD" &>/dev/null; then
      echo "Linux uninstall scheduled (systemd), will run in ~${DELAY}s."
    else
      # Fallback: nohup + disown (works when systemd-run unavailable, e.g. WSL2 without systemd)
      (nohup bash -c "$CMD" >> "$LOG_FILE" 2>&1 &)
      disown -a 2>/dev/null || true
      echo "Linux uninstall scheduled (nohup), will run in ~${DELAY}s."
      echo "If systemd is disabled, ensure: loginctl enable-linger \$USER"
    fi
    ;;
  *)
    echo "Unsupported OS: $(uname -s). Run manually: $UNINSTALL_SCRIPT"
    exit 1
    ;;
esac
