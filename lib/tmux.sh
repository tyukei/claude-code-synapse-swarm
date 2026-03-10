#!/usr/bin/env bash
# tmux session/pane management for Synapse Swarm

source "${SYNAPSE_ROOT}/lib/log.sh"

# Create a tmux session for the swarm
# Usage: tmux_create_session <session_name>
tmux_create_session() {
    local session="$1"

    if tmux has-session -t "$session" 2>/dev/null; then
        log_warn "tmux session already exists: ${session}"
        return 0
    fi

    tmux new-session -d -s "$session" -x 200 -y 50
    log_ok "tmux session created: ${session}"
}

# Create a new pane for an agent and run a command
# Usage: tmux_spawn_pane <session> <role> <command>
tmux_spawn_pane() {
    local session="$1"
    local role="$2"
    local command="$3"

    # Check if there's a window for this role already
    if tmux list-windows -t "$session" -F '#{window_name}' 2>/dev/null | grep -q "^${role}$"; then
        log_warn "Window already exists for role: ${role}"
        return 0
    fi

    tmux new-window -t "$session" -n "$role" "$command"
    log_ok "Spawned pane: ${role}"
}

# Send a command to a specific role's pane
# Usage: tmux_send <session> <role> <command>
tmux_send() {
    local session="$1"
    local role="$2"
    local command="$3"

    tmux send-keys -t "${session}:${role}" "$command" C-m
}

# Kill the swarm session
# Usage: tmux_kill_session <session>
tmux_kill_session() {
    local session="$1"

    if tmux has-session -t "$session" 2>/dev/null; then
        tmux kill-session -t "$session"
        log_ok "tmux session killed: ${session}"
    fi
}

# Attach to the swarm session
# Usage: tmux_attach <session>
tmux_attach() {
    local session="$1"
    tmux attach-session -t "$session"
}

# Wait for all agent panes to finish
# Usage: tmux_wait_all <session> <roles...>
tmux_wait_all() {
    local session="$1"; shift
    local roles=("$@")

    log_info "Waiting for agents to complete..."

    while true; do
        local all_done=true
        for role in "${roles[@]}"; do
            # Check if the window still has a running process
            if tmux list-windows -t "$session" -F '#{window_name}' 2>/dev/null | grep -q "^${role}$"; then
                # Check if the pane's process is still running
                local pane_pid
                pane_pid=$(tmux list-panes -t "${session}:${role}" -F '#{pane_pid}' 2>/dev/null)
                if [[ -n "$pane_pid" ]] && kill -0 "$pane_pid" 2>/dev/null; then
                    all_done=false
                fi
            fi
        done

        if $all_done; then
            break
        fi
        sleep 5
    done

    log_ok "All agents completed"
}
