#!/usr/bin/env bash
# Logging utilities for Synapse Swarm

SYNAPSE_LOG_DIR="${SYNAPSE_ROOT:-.}/output"

_log() {
    local level="$1"; shift
    local timestamp
    timestamp=$(date '+%H:%M:%S')
    printf "[%s] [%s] %s\n" "$timestamp" "$level" "$*" >&2
}

log_info()  { _log "INFO " "$@"; }
log_warn()  { _log "WARN " "$@"; }
log_error() { _log "ERROR" "$@"; }
log_ok()    { _log " OK  " "$@"; }

# Log to both stderr and a file
log_to_file() {
    local file="$1"; shift
    local msg
    msg="$(date '+%Y-%m-%d %H:%M:%S') $*"
    echo "$msg" >> "$file"
    _log "INFO " "$@"
}

# Print a section header
log_section() {
    echo "" >&2
    echo "━━━ $* ━━━" >&2
    echo "" >&2
}
