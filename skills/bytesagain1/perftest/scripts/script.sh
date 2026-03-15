#!/usr/bin/env bash
# perftest — description: "Performance testing and benchmarking tool. Measure command executi
# Powered by BytesAgain | bytesagain.com
set -euo pipefail

VERSION="1.0.0"
DATA_DIR="${PERFTEST_DIR:-${XDG_DATA_HOME:-$HOME/.local/share}/perftest}"
ENTRIES="$DATA_DIR/entries.jsonl"
CONFIG="$DATA_DIR/config.json"

ensure_dirs() {
    mkdir -p "$DATA_DIR"
    [ -f "$ENTRIES" ] || touch "$ENTRIES"
    [ -f "$CONFIG" ] || echo '{"created":"'"$(date -Iseconds)"'"}' > "$CONFIG"
}

now_ts() { date '+%Y-%m-%d %H:%M:%S'; }
entry_count() { wc -l < "$ENTRIES" 2>/dev/null || echo 0; }
line_at() { sed -n "${1}p" "$ENTRIES"; }

show_help() {
    cat << EOF
perftest v$VERSION

Usage: perftest <command> [args]

Commands:
  init             First-time setup
  add <text>       Add a new entry
  list             List all entries
  show <id>        Show entry details
  remove <id>      Remove entry by index
  search <term>    Search entries
  export <fmt>     Export (json|csv|txt)
  stats            Summary statistics
  config           View configuration
  status           Health check
  reset            Clear all data
  help             Show this help
  version          Show version

Data: $DATA_DIR
EOF
}

cmd_init() {
    ensure_dirs
    echo "[perftest] Initialized at $DATA_DIR"
    echo "  Entries file: $ENTRIES"
    echo "  Config file:  $CONFIG"
    echo ""
    echo "Ready. Try: perftest add \"your first item\""
}

cmd_add() {
    ensure_dirs
    local text="${*:?Usage: perftest add <text>}"
    local ts=$(now_ts)
    local id=$(($(entry_count) + 1))
    printf '{"id":%d,"text":"%s","created":"%s"}\n' "$id" "$text" "$ts" >> "$ENTRIES"
    echo "[perftest] #$id added: $text"
}

cmd_list() {
    ensure_dirs
    local total=$(entry_count)
    if [ "$total" -eq 0 ]; then
        echo "[perftest] No entries yet. Use: perftest add <text>"
        return
    fi
    echo "[perftest] $total entries:"
    echo ""
    local n=0
    while IFS= read -r line; do
        n=$((n + 1))
        local text=$(echo "$line" | python3 -c "import json,sys; print(json.load(sys.stdin).get('text','?'))" 2>/dev/null || echo "$line")
        local ts=$(echo "$line" | python3 -c "import json,sys; print(json.load(sys.stdin).get('created',''))" 2>/dev/null || echo "")
        printf "  %3d. %s" "$n" "$text"
        [ -n "$ts" ] && printf "  (%s)" "$ts"
        echo ""
    done < "$ENTRIES"
}

cmd_show() {
    ensure_dirs
    local id="${1:?Usage: perftest show <id>}"
    local total=$(entry_count)
    if [ "$id" -lt 1 ] || [ "$id" -gt "$total" ]; then
        echo "Error: id must be 1-$total"; return 1
    fi
    local line=$(line_at "$id")
    echo "[perftest] Entry #$id:"
    echo "$line" | python3 -c "
import json, sys
d = json.load(sys.stdin)
for k,v in d.items():
    print('  {}: {}'.format(k, v))
" 2>/dev/null || echo "  $line"
}

cmd_remove() {
    ensure_dirs
    local id="${1:?Usage: perftest remove <id>}"
    local total=$(entry_count)
    if [ "$id" -lt 1 ] || [ "$id" -gt "$total" ]; then
        echo "Error: id must be 1-$total"; return 1
    fi
    local removed=$(line_at "$id")
    sed -i "${id}d" "$ENTRIES"
    local text=$(echo "$removed" | python3 -c "import json,sys; print(json.load(sys.stdin).get('text','?'))" 2>/dev/null || echo "?")
    echo "[perftest] Removed #$id: $text"
}

cmd_search() {
    ensure_dirs
    local term="${1:?Usage: perftest search <term>}"
    local found=0
    local n=0
    while IFS= read -r line; do
        n=$((n + 1))
        if echo "$line" | grep -qi "$term"; then
            local text=$(echo "$line" | python3 -c "import json,sys; print(json.load(sys.stdin).get('text','?'))" 2>/dev/null || echo "$line")
            printf "  %3d. %s\n" "$n" "$text"
            found=$((found + 1))
        fi
    done < "$ENTRIES"
    echo "[perftest] Found $found matches for '$term'"
}

cmd_export() {
    ensure_dirs
    local fmt="${1:-json}"
    case "$fmt" in
        json)
            echo "["
            local first=1
            while IFS= read -r line; do
                [ "$first" -eq 0 ] && echo ","
                printf "  %s" "$line"
                first=0
            done < "$ENTRIES"
            echo ""
            echo "]"
            ;;
        csv)
            echo "id,text,created"
            while IFS= read -r line; do
                echo "$line" | python3 -c "
import json, sys
d = json.load(sys.stdin)
print('{},{},{}'.format(d.get('id',''), d.get('text','').replace(',',';'), d.get('created','')))
" 2>/dev/null
            done < "$ENTRIES"
            ;;
        txt)
            cat "$ENTRIES"
            ;;
        *)
            echo "Formats: json, csv, txt"
            ;;
    esac
}

cmd_stats() {
    ensure_dirs
    local total=$(entry_count)
    local size=$(du -sh "$DATA_DIR" 2>/dev/null | cut -f1)
    echo "[perftest] Statistics"
    echo "  Entries:    $total"
    echo "  Data size:  $size"
    echo "  Data dir:   $DATA_DIR"
    if [ "$total" -gt 0 ]; then
        local first=$(head -1 "$ENTRIES" | python3 -c "import json,sys; print(json.load(sys.stdin).get('created','?'))" 2>/dev/null || echo "?")
        local last=$(tail -1 "$ENTRIES" | python3 -c "import json,sys; print(json.load(sys.stdin).get('created','?'))" 2>/dev/null || echo "?")
        echo "  First:      $first"
        echo "  Latest:     $last"
    fi
}

cmd_config() {
    ensure_dirs
    echo "[perftest] Configuration"
    echo "  File: $CONFIG"
    echo ""
    python3 -c "
import json
with open('$CONFIG') as f:
    d = json.load(f)
for k,v in d.items():
    print('  {}: {}'.format(k, v))
" 2>/dev/null || echo "  (empty)"
}

cmd_status() {
    ensure_dirs
    echo "[perftest] Status Check"
    echo "  Version:  $VERSION"
    echo "  Data dir: $DATA_DIR"
    echo "  Entries:  $(entry_count)"
    [ -f "$CONFIG" ] && echo "  Config:   OK" || echo "  Config:   MISSING"
    [ -w "$DATA_DIR" ] && echo "  Writable: YES" || echo "  Writable: NO"
}

cmd_reset() {
    echo "Warning: This will delete ALL data in $DATA_DIR"
    printf "Type 'yes' to confirm: "
    read -r confirm
    if [ "$confirm" = "yes" ]; then
        rm -f "$ENTRIES" "$CONFIG"
        echo "[perftest] Data cleared."
    else
        echo "Cancelled."
    fi
}

case "${1:-help}" in
    init)           cmd_init ;;
    add)            shift; cmd_add "$@" ;;
    list|ls)        cmd_list ;;
    show|get)       shift; cmd_show "$@" ;;
    remove|rm|del)  shift; cmd_remove "$@" ;;
    search|find|grep) shift; cmd_search "$@" ;;
    export)         shift; cmd_export "$@" ;;
    stats)          cmd_stats ;;
    config|cfg)     cmd_config ;;
    status)         cmd_status ;;
    reset)          cmd_reset ;;
    help|-h|--help) show_help ;;
    version|-v)     echo "perftest v$VERSION" ;;
    *)              echo "Unknown: $1"; show_help; exit 1 ;;
esac
