#!/bin/bash
# Common functions for skills-manager scripts

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SKILL_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
CONFIG_FILE="$SKILL_DIR/config.json"

# Check dependencies
check_deps() {
    if ! command -v jq &> /dev/null; then
        echo "Error: jq is required but not installed."
        echo "Install with: brew install jq"
        exit 1
    fi
}

# Get the agent-skills repo path
# Priority: 1. $AGENT_SKILLS_REPO env var, 2. config.json
get_repo_path() {
    # Check environment variable first
    if [ -n "$AGENT_SKILLS_REPO" ]; then
        if [ -d "$AGENT_SKILLS_REPO" ]; then
            echo "$AGENT_SKILLS_REPO"
            return 0
        else
            echo "Warning: AGENT_SKILLS_REPO is set but directory doesn't exist: $AGENT_SKILLS_REPO" >&2
        fi
    fi

    # Check config file
    if [ -f "$CONFIG_FILE" ]; then
        local repo_path=$(jq -r '.repoPath // empty' "$CONFIG_FILE")
        if [ -n "$repo_path" ] && [ -d "$repo_path" ]; then
            echo "$repo_path"
            return 0
        fi
    fi

    # Not configured
    return 1
}

# Get registry file path
get_registry_file() {
    local repo_path=$(get_repo_path)
    if [ $? -ne 0 ]; then
        return 1
    fi
    echo "$repo_path/skills-registry.json"
}

# Save config
save_config() {
    local repo_path="$1"
    echo "{\"repoPath\": \"$repo_path\"}" > "$CONFIG_FILE"
    echo "Configuration saved to $CONFIG_FILE"
}

# Check if configured, exit with message if not
require_config() {
    if ! get_repo_path > /dev/null 2>&1; then
        echo "Error: No agent-skills repository configured."
        echo ""
        echo "Run setup first:"
        echo "  $SCRIPT_DIR/setup.sh [path]"
        echo ""
        echo "Or set the AGENT_SKILLS_REPO environment variable:"
        echo "  export AGENT_SKILLS_REPO=/path/to/your/agent-skills"
        exit 1
    fi
}
