#!/bin/bash
# Install all saved skills from the registry
# Usage: install.sh

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/common.sh"

check_deps
require_config

# Get registry file
REPO_PATH=$(get_repo_path)
REGISTRY_FILE="$REPO_PATH/skills-registry.json"

# Count skills
SKILL_COUNT=$(jq '.skills | length' "$REGISTRY_FILE")

if [ "$SKILL_COUNT" -eq 0 ]; then
    echo "No skills saved in registry. Nothing to install."
    echo ""
    echo "Save skills first with:"
    echo "  $SCRIPT_DIR/save.sh owner/repo [skill-name]"
    exit 0
fi

echo "Installing $SKILL_COUNT saved skill(s)..."
echo ""

# Track results
SUCCESS=0
FAILED=0

# Install each skill
jq -r '.skills | to_entries[] | "\(.key)|\(.value.source)|\(.value.path)"' "$REGISTRY_FILE" | while IFS='|' read -r NAME SOURCE PATH; do
    echo "Installing $NAME from $SOURCE..."

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

echo "Install complete!"
