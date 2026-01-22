#!/bin/bash
# Remove a skill from the registry
# Usage: unsave.sh skill-name

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/common.sh"

check_deps
require_config

if [ -z "$1" ]; then
    echo "Usage: unsave.sh skill-name"
    exit 1
fi

SKILL_NAME="$1"

# Get registry file
REPO_PATH=$(get_repo_path)
REGISTRY_FILE="$REPO_PATH/skills-registry.json"

# Check if skill exists in registry
if ! jq -e ".skills[\"$SKILL_NAME\"]" "$REGISTRY_FILE" > /dev/null 2>&1; then
    echo "Error: Skill '$SKILL_NAME' not found in registry."
    echo ""
    echo "Use list.sh to see saved skills."
    exit 1
fi

# Get skill info for display
SOURCE=$(jq -r ".skills[\"$SKILL_NAME\"].source" "$REGISTRY_FILE")

# Remove from registry
TEMP_FILE=$(mktemp)
jq --arg name "$SKILL_NAME" 'del(.skills[$name])' "$REGISTRY_FILE" > "$TEMP_FILE"
mv "$TEMP_FILE" "$REGISTRY_FILE"

echo "Removed '$SKILL_NAME' from registry"
echo "  Was: $SOURCE"
