#!/usr/bin/env bash
# worktree 管理

# worktree を作成する
# Usage: worktree_create <session> <task_id> <target_repo>
worktree_create() {
    local session="$1"
    local task_id="$2"
    local target="$3"
    local branch="swarm/${session}/${task_id}"
    local worktree_path="${target}/.worktrees/${session}/${task_id}"

    mkdir -p "$(dirname "$worktree_path")"

    if [[ -d "$worktree_path" ]]; then
        echo "$worktree_path"
        return 0
    fi

    git -C "$target" worktree add -b "$branch" "$worktree_path" HEAD 2>/dev/null \
        || git -C "$target" worktree add "$worktree_path" "$branch" 2>/dev/null \
        || { echo "エラー: worktree の作成に失敗しました ($task_id)" >&2; return 1; }

    echo "$worktree_path"
}
