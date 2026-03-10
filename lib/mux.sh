#!/usr/bin/env bash
# Unified multiplexer abstraction for Synapse Swarm.
#
# Supports two backends:
#   cmux  — macOS-only (cmux terminal app). Provides workspace management
#           and sidebar status/progress. Requires cmux daemon to be running.
#   tmux  — Cross-platform. Works on macOS, Linux, and in containers.
#
# Auto-detection order: cmux (if daemon running) → tmux → none (sequential)
#
# In containers / DevContainers:
#   cmux is NOT available (macOS-only). Set MUX_BACKEND=tmux explicitly via
#   the Dockerfile ENV or devcontainer.json containerEnv, or let auto-detect
#   fall back to tmux automatically.
#
# Usage:
#   source lib/mux.sh              # auto-detect
#   MUX_BACKEND=tmux source lib/mux.sh   # force tmux (containers)
#   MUX_BACKEND=none source lib/mux.sh   # sequential, no multiplexer

source "${SYNAPSE_ROOT}/lib/log.sh"

# ── Backend detection ────────────────────────────────────────────

_mux_detect_backend() {
    # Explicit override wins
    if [[ -n "${MUX_BACKEND:-}" ]]; then
        echo "$MUX_BACKEND"
        return
    fi

    # cmux: check if binary exists and responds
    if command -v cmux >/dev/null 2>&1; then
        if cmux ping >/dev/null 2>&1; then
            echo "cmux"
            return
        fi
    fi

    # tmux: check if binary exists and server is running
    if command -v tmux >/dev/null 2>&1; then
        echo "tmux"
        return
    fi

    echo "none"
}

MUX_BACKEND="${MUX_BACKEND:-$(_mux_detect_backend)}"

case "$MUX_BACKEND" in
    cmux)
        source "${SYNAPSE_ROOT}/lib/cmux.sh"
        log_info "mux: using cmux backend"
        ;;
    tmux)
        source "${SYNAPSE_ROOT}/lib/tmux.sh"
        log_info "mux: using tmux backend"
        ;;
    none)
        log_warn "mux: no multiplexer found (tmux or cmux). Using --no-mux mode."
        ;;
    *)
        log_error "mux: unknown backend '${MUX_BACKEND}'. Choose: cmux, tmux, none"
        exit 1
        ;;
esac

# ── Unified mux_* interface ──────────────────────────────────────
# Each function delegates to the active backend.

mux_available() {
    [[ "$MUX_BACKEND" != "none" ]]
}

mux_backend() {
    echo "$MUX_BACKEND"
}

mux_create_session() {
    case "$MUX_BACKEND" in
        cmux) cmux_create_session "$@" ;;
        tmux) tmux_create_session "$@" ;;
        none) log_info "mux: no-op create_session (no multiplexer)" ;;
    esac
}

mux_spawn_pane() {
    case "$MUX_BACKEND" in
        cmux) cmux_spawn_pane "$@" ;;
        tmux) tmux_spawn_pane "$@" ;;
        none) log_warn "mux: spawn_pane called but no multiplexer available" ;;
    esac
}

mux_send() {
    case "$MUX_BACKEND" in
        cmux) cmux_send "$@" ;;
        tmux) tmux_send "$@" ;;
        none) : ;;
    esac
}

mux_kill_session() {
    case "$MUX_BACKEND" in
        cmux) cmux_kill_session "$@" ;;
        tmux) tmux_kill_session "$@" ;;
        none) : ;;
    esac
}

mux_attach() {
    case "$MUX_BACKEND" in
        cmux) cmux_attach "$@" ;;
        tmux) tmux_attach "$@" ;;
        none) log_info "mux: attach not available without a multiplexer" ;;
    esac
}

mux_wait_all() {
    case "$MUX_BACKEND" in
        cmux) cmux_wait_all "$@" ;;
        tmux) tmux_wait_all "$@" ;;
        none) log_warn "mux: wait_all called but no multiplexer available" ;;
    esac
}

# cmux-specific extras (safe no-op on tmux)
mux_mark_done() {
    case "$MUX_BACKEND" in
        cmux) cmux_mark_done "$@" ;;
        *)    : ;;
    esac
}

mux_set_progress() {
    case "$MUX_BACKEND" in
        cmux) cmux_set_progress "$@" ;;
        *)    : ;;
    esac
}
