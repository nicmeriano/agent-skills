#!/bin/bash
# Remove a skill from the registry
# Usage: remove.sh skill-name

set -e

REPO_ROOT="$(cd "$(dirname "$0")/../../.." && pwd)"
REGISTRY_FILE="$REPO_ROOT/skills-registry.json"

# Check dependencies
if ! command -v jq &> /dev/null; then
    echo "Error: jq is required but not installed."
    echo "Install with: brew install jq"
    exit 1
fi

if [ -z "$1" ]; then
    echo "Usage: remove.sh skill-name"
    exit 1
fi

SKILL_NAME="$1"

# Check if skill exists in registry
if ! jq -e ".skills[\"$SKILL_NAME\"]" "$REGISTRY_FILE" > /dev/null 2>&1; then
    echo "Error: Skill '$SKILL_NAME' not found in registry."
    echo "Use list.sh to see registered skills."
    exit 1
fi

# Get skill info for display
SOURCE=$(jq -r ".skills[\"$SKILL_NAME\"].source" "$REGISTRY_FILE")

# Remove from registry
TEMP_FILE=$(mktemp)
jq --arg name "$SKILL_NAME" 'del(.skills[$name])' "$REGISTRY_FILE" > "$TEMP_FILE"
mv "$TEMP_FILE" "$REGISTRY_FILE"

echo "Removed '$SKILL_NAME' from registry (source: $SOURCE)"
echo ""
echo "Note: Local skill files may still exist. Use 'npx skills remove' to uninstall locally."
