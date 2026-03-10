FROM mcr.microsoft.com/devcontainers/base:ubuntu-24.04

# ── System packages ──────────────────────────────────────────────
RUN apt-get update && apt-get install -y --no-install-recommends \
    tmux \
    jq \
    && rm -rf /var/lib/apt/lists/*

# ── Node.js (for Claude Code CLI) ───────────────────────────────
RUN curl -fsSL https://deb.nodesource.com/setup_22.x | bash - \
    && apt-get install -y nodejs \
    && rm -rf /var/lib/apt/lists/*

# ── Claude Code CLI ──────────────────────────────────────────────
RUN npm install -g @anthropic-ai/claude-code

# cmux is macOS-only. In this container, tmux is always used.
ENV MUX_BACKEND=tmux
