#!/bin/bash
# Sync (install) all skills from the registry
# Usage: sync.sh

set -e

REPO_ROOT="$(cd "$(dirname "$0")/../../.." && pwd)"
REGISTRY_FILE="$REPO_ROOT/skills-registry.json"

# Check dependencies
if ! command -v jq &> /dev/null; then
    echo "Error: jq is required but not installed."
    echo "Install with: brew install jq"
    exit 1
fi

# Check if registry exists
if [ ! -f "$REGISTRY_FILE" ]; then
    echo "Error: Registry file not found at $REGISTRY_FILE"
    exit 1
fi

# Count skills
SKILL_COUNT=$(jq '.skills | length' "$REGISTRY_FILE")

if [ "$SKILL_COUNT" -eq 0 ]; then
    echo "No skills registered. Nothing to sync."
    echo ""
    echo "Add a skill with: add.sh owner/repo [skill-path]"
    exit 0
fi

echo "Syncing $SKILL_COUNT skill(s) from registry..."
echo ""

# Track results
SUCCESS=0
FAILED=0

# Install each skill (non-interactive for Claude Code compatibility)
jq -r '.skills | to_entries[] | "\(.key)|\(.value.source)|\(.value.path)"' "$REGISTRY_FILE" | while IFS='|' read -r NAME SOURCE PATH; do
    echo "Installing $NAME..."

    if [ "$PATH" != "" ] && [ "$PATH" != "null" ]; then
        if npx skills add "$SOURCE" --skill "$NAME" --agent claude-code --yes 2>/dev/null; then
            echo "✓ Installed $NAME"
        else
            echo "✗ Failed to install $NAME"
        fi
    else
        if npx skills add "$SOURCE" --agent claude-code --yes 2>/dev/null; then
            echo "✓ Installed $NAME"
        else
            echo "✗ Failed to install $NAME"
        fi
    fi
    echo ""
done

echo "Sync complete."
