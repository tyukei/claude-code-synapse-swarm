#!/usr/bin/env bash
# Git worktree management for Synapse Swarm

source "${SYNAPSE_ROOT}/lib/log.sh"

WORKTREE_BASE="${SYNAPSE_ROOT}/.worktrees"

# Create a worktree for an agent role
# Usage: worktree_create <session> <role>
worktree_create() {
    local session="$1"
    local role="$2"
    local branch="swarm/${session}/${role}"
    local worktree_path="${WORKTREE_BASE}/${session}/${role}"

    if [[ -d "$worktree_path" ]]; then
        log_warn "Worktree already exists: ${worktree_path}"
        echo "$worktree_path"
        return 0
    fi

    mkdir -p "$(dirname "$worktree_path")"

    # Create a new branch from current HEAD
    git -C "${SYNAPSE_ROOT}" worktree add -b "$branch" "$worktree_path" HEAD 2>/dev/null
    if [[ $? -ne 0 ]]; then
        # Branch may already exist, try without -b
        git -C "${SYNAPSE_ROOT}" worktree add "$worktree_path" "$branch" 2>/dev/null || {
            log_error "Failed to create worktree for ${role}"
            return 1
        }
    fi

    log_ok "Worktree created: ${role} → ${worktree_path}"
    echo "$worktree_path"
}

# Remove a worktree
# Usage: worktree_remove <session> <role>
worktree_remove() {
    local session="$1"
    local role="$2"
    local worktree_path="${WORKTREE_BASE}/${session}/${role}"

    if [[ -d "$worktree_path" ]]; then
        git -C "${SYNAPSE_ROOT}" worktree remove --force "$worktree_path" 2>/dev/null
        log_ok "Worktree removed: ${role}"
    fi
}

# Remove all worktrees for a session
# Usage: worktree_remove_all <session>
worktree_remove_all() {
    local session="$1"
    local session_dir="${WORKTREE_BASE}/${session}"

    if [[ -d "$session_dir" ]]; then
        for wt in "$session_dir"/*/; do
            local role
            role=$(basename "$wt")
            worktree_remove "$session" "$role"
        done
        rmdir "$session_dir" 2>/dev/null
    fi

    git -C "${SYNAPSE_ROOT}" worktree prune 2>/dev/null
    log_ok "All worktrees cleaned for session: ${session}"
}

# List all worktrees for a session
worktree_list() {
    local session="$1"
    local session_dir="${WORKTREE_BASE}/${session}"

    if [[ -d "$session_dir" ]]; then
        for wt in "$session_dir"/*/; do
            [[ -d "$wt" ]] && basename "$wt"
        done
    fi
}

# Get the worktree path for a role
worktree_path() {
    local session="$1"
    local role="$2"
    echo "${WORKTREE_BASE}/${session}/${role}"
}
