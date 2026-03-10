#!/usr/bin/env bash
# cmux backend for Synapse Swarm
# cmux is a terminal multiplexer with workspaces, surfaces, and sidebar support.
# See: cmux --help

source "${SYNAPSE_ROOT}/lib/log.sh"

# State directory for tracking workspace IDs
CMUX_STATE_DIR="${SYNAPSE_ROOT}/.worktrees/.cmux"

# ── Internal helpers ─────────────────────────────────────────────

# Run cmux, returning its output; exit if not available
_cmux() {
    cmux "$@" 2>/dev/null
}

# Get all workspace refs as newline-delimited list
_cmux_list_ws_refs() {
    _cmux --id-format refs list-workspaces | grep -o 'workspace:[^ ,]*' || true
}

# Get workspace ref saved for a role
_cmux_ws_ref() {
    local session="$1" role="$2"
    local state_file="${CMUX_STATE_DIR}/${session}/${role}.wsid"
    [[ -f "$state_file" ]] && cat "$state_file" || echo ""
}

# Save workspace ref for a role
_cmux_save_ws_ref() {
    local session="$1" role="$2" ws_ref="$3"
    mkdir -p "${CMUX_STATE_DIR}/${session}"
    echo "$ws_ref" > "${CMUX_STATE_DIR}/${session}/${role}.wsid"
}

# ── Public interface (matches mux_* abstraction) ─────────────────

# Initialize a cmux session (no-op; cmux is always running as app)
# Usage: cmux_create_session <session>
cmux_create_session() {
    local session="$1"
    mkdir -p "${CMUX_STATE_DIR}/${session}"
    log_ok "cmux: ready for session ${session}"
}

# Spawn a new workspace for an agent role running a command
# Usage: cmux_spawn_pane <session> <role> <command>
cmux_spawn_pane() {
    local session="$1"
    local role="$2"
    local command="$3"

    # Snapshot existing workspace refs to diff after creation
    local before
    before=$(_cmux_list_ws_refs)

    # Create the workspace with the agent command
    _cmux new-workspace --command "$command" >/dev/null

    # Find the newly created workspace (appears in list but not in before)
    local after ws_ref=""
    after=$(_cmux_list_ws_refs)
    ws_ref=$(comm -13 <(echo "$before" | sort) <(echo "$after" | sort) | tail -1)

    if [[ -z "$ws_ref" ]]; then
        log_warn "cmux: could not determine workspace ref for ${role}"
        # Fall back to last in list
        ws_ref=$(echo "$after" | tail -1)
    fi

    _cmux_save_ws_ref "$session" "$role" "$ws_ref"

    # Name the workspace so it's identifiable
    _cmux rename-workspace --workspace "$ws_ref" "${session}/${role}" 2>/dev/null || true

    # Show agent status in sidebar
    _cmux set-status "swarm-${role}" "running" \
        --icon "circle" --color "#f59e0b" \
        --workspace "$ws_ref" 2>/dev/null || true

    log_ok "cmux: spawned workspace for ${role} (${ws_ref})"
}

# Send text/command to a role's workspace
# Usage: cmux_send <session> <role> <text>
cmux_send() {
    local session="$1"
    local role="$2"
    local text="$3"
    local ws_ref
    ws_ref=$(_cmux_ws_ref "$session" "$role")

    if [[ -n "$ws_ref" ]]; then
        _cmux send --workspace "$ws_ref" "$text"
    else
        log_warn "cmux: no workspace ref found for ${role}"
    fi
}

# Mark a role as done in the sidebar (call from spawn-agent at completion)
# Usage: cmux_mark_done <session> <role> [success|error]
cmux_mark_done() {
    local session="$1"
    local role="$2"
    local status="${3:-success}"
    local ws_ref
    ws_ref=$(_cmux_ws_ref "$session" "$role")

    if [[ -n "$ws_ref" ]]; then
        if [[ "$status" == "success" ]]; then
            _cmux set-status "swarm-${role}" "done" \
                --icon "checkmark" --color "#10b981" \
                --workspace "$ws_ref" 2>/dev/null || true
            _cmux clear-progress --workspace "$ws_ref" 2>/dev/null || true
        else
            _cmux set-status "swarm-${role}" "error" \
                --icon "xmark" --color "#ef4444" \
                --workspace "$ws_ref" 2>/dev/null || true
        fi
    fi

    # Signal the orchestrator that this role is done
    _cmux wait-for -S "synapse-done-${session}-${role}" 2>/dev/null || true
}

# Update progress for a role in the cmux sidebar
# Usage: cmux_set_progress <session> <role> <0.0-1.0> [label]
cmux_set_progress() {
    local session="$1"
    local role="$2"
    local progress="$3"
    local label="${4:-}"
    local ws_ref
    ws_ref=$(_cmux_ws_ref "$session" "$role")

    if [[ -n "$ws_ref" ]]; then
        if [[ -n "$label" ]]; then
            _cmux set-progress "$progress" --label "$label" --workspace "$ws_ref" 2>/dev/null || true
        else
            _cmux set-progress "$progress" --workspace "$ws_ref" 2>/dev/null || true
        fi
    fi
}

# Close a role's workspace
# Usage: cmux_close_pane <session> <role>
cmux_close_pane() {
    local session="$1"
    local role="$2"
    local ws_ref
    ws_ref=$(_cmux_ws_ref "$session" "$role")

    if [[ -n "$ws_ref" ]]; then
        _cmux close-workspace --workspace "$ws_ref" 2>/dev/null || true
        log_ok "cmux: closed workspace for ${role}"
    fi

    rm -f "${CMUX_STATE_DIR}/${session}/${role}.wsid"
}

# Kill all workspaces for a session
# Usage: cmux_kill_session <session>
cmux_kill_session() {
    local session="$1"
    local session_dir="${CMUX_STATE_DIR}/${session}"

    if [[ -d "$session_dir" ]]; then
        for wsid_file in "${session_dir}"/*.wsid; do
            [[ -f "$wsid_file" ]] || continue
            local ws_ref
            ws_ref=$(cat "$wsid_file")
            _cmux close-workspace --workspace "$ws_ref" 2>/dev/null || true
        done
        rm -rf "$session_dir"
    fi

    log_ok "cmux: all workspaces closed for session ${session}"
}

# Attach to session — cmux is a GUI app, just bring focus to the window
# Usage: cmux_attach <session>
cmux_attach() {
    local session="$1"
    log_info "cmux: switch to the cmux terminal window for session ${session}"
    log_info "      Workspace names are prefixed: ${session}/<role>"
}

# Wait for all roles in a session to complete (signal-based)
# Usage: cmux_wait_all <session> <roles...>
cmux_wait_all() {
    local session="$1"; shift
    local roles=("$@")

    log_info "cmux: waiting for agents to signal completion..."

    for role in "${roles[@]}"; do
        local signal="synapse-done-${session}-${role}"
        log_info "  Waiting for: ${role}..."
        _cmux wait-for "$signal" 2>/dev/null || {
            # Fallback: poll state file if wait-for is unavailable
            local state_file="${CMUX_STATE_DIR}/${session}/${role}.done"
            while [[ ! -f "$state_file" ]]; do
                sleep 3
            done
        }
        log_ok "  ${role}: done"
    done

    log_ok "cmux: all agents completed"
}
