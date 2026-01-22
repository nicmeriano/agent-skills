#!/bin/bash
# Update one or all skills to latest versions
# Usage: update.sh [skill-name]

set -e

REPO_ROOT="$(cd "$(dirname "$0")/../../.." && pwd)"
REGISTRY_FILE="$REPO_ROOT/skills-registry.json"

# Check dependencies
if ! command -v jq &> /dev/null; then
    echo "Error: jq is required but not installed."
    echo "Install with: brew install jq"
    exit 1
fi

update_skill() {
    local SKILL_NAME="$1"

    # Get current skill info
    local SOURCE=$(jq -r ".skills[\"$SKILL_NAME\"].source" "$REGISTRY_FILE")
    local SKILL_PATH=$(jq -r ".skills[\"$SKILL_NAME\"].path" "$REGISTRY_FILE")
    local CURRENT_VERSION=$(jq -r ".skills[\"$SKILL_NAME\"].version" "$REGISTRY_FILE")

    if [ "$SOURCE" == "null" ] || [ -z "$SOURCE" ]; then
        echo "Error: Skill '$SKILL_NAME' not found in registry."
        return 1
    fi

    # Parse owner and repo
    local OWNER=$(echo "$SOURCE" | cut -d'/' -f1)
    local REPO=$(echo "$SOURCE" | cut -d'/' -f2)

    # Get latest commit SHA
    local LATEST_SHA=$(curl -s "https://api.github.com/repos/$OWNER/$REPO/commits/main" | jq -r '.sha // empty')

    if [ -z "$LATEST_SHA" ]; then
        LATEST_SHA=$(curl -s "https://api.github.com/repos/$OWNER/$REPO/commits/master" | jq -r '.sha // empty')
    fi

    if [ -z "$LATEST_SHA" ]; then
        echo "Error: Could not fetch latest version for '$SKILL_NAME'."
        return 1
    fi

    local SHORT_SHA="${LATEST_SHA:0:7}"

    if [ "$SHORT_SHA" == "$CURRENT_VERSION" ]; then
        echo "✓ $SKILL_NAME is already up to date ($CURRENT_VERSION)"
        return 0
    fi

    echo "Updating $SKILL_NAME: $CURRENT_VERSION → $SHORT_SHA"

    # Update registry
    local TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
    local TEMP_FILE=$(mktemp)

    jq --arg name "$SKILL_NAME" \
       --arg version "$SHORT_SHA" \
       --arg timestamp "$TIMESTAMP" \
       '.skills[$name].version = $version | .skills[$name].updatedAt = $timestamp' \
       "$REGISTRY_FILE" > "$TEMP_FILE"

    mv "$TEMP_FILE" "$REGISTRY_FILE"

    # Reinstall via npx skills (non-interactive for Claude Code compatibility)
    if [ "$SKILL_PATH" != "null" ] && [ -n "$SKILL_PATH" ]; then
        npx skills add "$SOURCE" --skill "$SKILL_NAME" --agent claude-code --yes
    else
        npx skills add "$SOURCE" --agent claude-code --yes
    fi

    echo "✓ Updated $SKILL_NAME to $SHORT_SHA"
}

# Update single skill or all skills
if [ -n "$1" ]; then
    update_skill "$1"
else
    echo "Checking for updates..."
    echo ""

    # Get all skill names
    SKILLS=$(jq -r '.skills | keys[]' "$REGISTRY_FILE")

    if [ -z "$SKILLS" ]; then
        echo "No skills registered. Use add.sh to add skills."
        exit 0
    fi

    for SKILL in $SKILLS; do
        update_skill "$SKILL"
    done

    echo ""
    echo "Update check complete."
fi
