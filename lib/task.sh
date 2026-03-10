#!/usr/bin/env bash
# Task management utilities for Synapse Swarm

source "${SYNAPSE_ROOT}/lib/log.sh"

# Render a prompt template with task description
# Usage: task_render_prompt <template_file> <task_description>
task_render_prompt() {
    local template="$1"
    local task_desc="$2"

    if [[ ! -f "$template" ]]; then
        log_error "Template not found: ${template}"
        return 1
    fi

    local content
    content=$(cat "$template")

    # Replace {{TASK_DESCRIPTION}} placeholder
    echo "${content//\{\{TASK_DESCRIPTION\}\}/$task_desc}"
}

# Parse roles from a task file (simple format: one role per line under "roles:")
# Usage: task_get_roles <task_file>
task_get_roles() {
    local task_file="$1"

    if [[ ! -f "$task_file" ]]; then
        # Default roles if no task file
        echo "planner architect coder tester reviewer"
        return
    fi

    # Extract roles from YAML-like format
    local in_roles=false
    while IFS= read -r line; do
        if [[ "$line" =~ ^roles: ]]; then
            in_roles=true
            continue
        fi
        if $in_roles; then
            if [[ "$line" =~ ^[[:space:]]*-[[:space:]]*(.*) ]]; then
                echo -n "${BASH_REMATCH[1]} "
            elif [[ "$line" =~ ^[a-z] ]]; then
                break
            fi
        fi
    done < "$task_file"
    echo
}

# Get the task description from a task file
# Usage: task_get_description <task_file>
task_get_description() {
    local task_file="$1"

    if [[ ! -f "$task_file" ]]; then
        echo "No task description provided."
        return
    fi

    # Extract description field
    local in_desc=false
    local desc=""
    while IFS= read -r line; do
        if [[ "$line" =~ ^description:[[:space:]]*(.*) ]]; then
            desc="${BASH_REMATCH[1]}"
            # Handle multi-line (lines starting with spaces after description:)
            in_desc=true
            continue
        fi
        if $in_desc; then
            if [[ "$line" =~ ^[[:space:]] ]]; then
                desc="${desc} ${line##*( )}"
            else
                break
            fi
        fi
    done < "$task_file"

    echo "$desc"
}

# Get phase for a role from config
# Usage: task_get_phase <role>
task_get_phase() {
    local role="$1"
    local config="${SYNAPSE_ROOT}/config/roles.yaml"

    # Simple extraction — look for role section then phase
    local in_role=false
    while IFS= read -r line; do
        if [[ "$line" =~ ^[[:space:]]{2}${role}: ]]; then
            in_role=true
            continue
        fi
        if $in_role; then
            if [[ "$line" =~ ^[[:space:]]{4}phase:[[:space:]]*([0-9]+) ]]; then
                echo "${BASH_REMATCH[1]}"
                return
            fi
            if [[ "$line" =~ ^[[:space:]]{2}[a-z] ]]; then
                break
            fi
        fi
    done < "$config"

    echo "2"  # default phase
}
