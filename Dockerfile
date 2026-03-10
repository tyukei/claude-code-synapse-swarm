FROM ubuntu:24.04

# Prevent interactive prompts during package installation
ENV DEBIAN_FRONTEND=noninteractive

# ── System packages ──────────────────────────────────────────────
RUN apt-get update && apt-get install -y --no-install-recommends \
    # Core tools
    bash \
    git \
    curl \
    ca-certificates \
    # Terminal multiplexer (tmux is the container mux backend)
    tmux \
    # Utilities
    jq \
    && rm -rf /var/lib/apt/lists/*

# ── Node.js (for Claude Code CLI) ───────────────────────────────
# Install Node.js 22 LTS via NodeSource
RUN curl -fsSL https://deb.nodesource.com/setup_22.x | bash - \
    && apt-get install -y nodejs \
    && rm -rf /var/lib/apt/lists/*

# ── Claude Code CLI ──────────────────────────────────────────────
RUN npm install -g @anthropic-ai/claude-code

# ── Git defaults ─────────────────────────────────────────────────
# Required for git worktree operations
RUN git config --system user.email "swarm@synapse" \
    && git config --system user.name "Synapse Swarm"

# ── Workspace ────────────────────────────────────────────────────
WORKDIR /workspace

COPY . .
RUN chmod +x bin/*

# ANTHROPIC_API_KEY must be provided at runtime:
#   docker run -e ANTHROPIC_API_KEY=... synapse-swarm
#
# cmux is macOS-only and not available in this container.
# The swarm will automatically use tmux as the mux backend.
ENV MUX_BACKEND=tmux

CMD ["bash"]
