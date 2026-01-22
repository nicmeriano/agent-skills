#!/bin/bash
# List all saved skills in the registry
# Usage: list.sh

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
    echo "No skills saved in registry."
    echo ""
    echo "Save a skill with:"
    echo "  $SCRIPT_DIR/save.sh owner/repo [skill-name]"
    exit 0
fi

echo "Saved Skills ($SKILL_COUNT)"
echo "============="
echo ""
echo "Registry: $REGISTRY_FILE"
echo ""

# List each skill
jq -r '.skills | to_entries[] | "\(.key)|\(.value.source)|\(.value.path)|\(.value.savedAt)"' "$REGISTRY_FILE" | while IFS='|' read -r NAME SOURCE PATH SAVED; do
    echo "• $NAME"
    echo "  Source: $SOURCE"
    if [ "$PATH" != "" ] && [ "$PATH" != "null" ]; then
        echo "  Path:   $PATH"
    fi
    echo "  Saved:  $SAVED"
    echo ""
done
