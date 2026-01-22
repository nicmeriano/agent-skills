#!/bin/bash
# List all registered skills
# Usage: list.sh

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
    echo "No skills registered."
    echo ""
    echo "Add a skill with: add.sh owner/repo [skill-path]"
    exit 0
fi

echo "Registered Skills ($SKILL_COUNT)"
echo "===================="
echo ""

# List each skill
jq -r '.skills | to_entries[] | "\(.key)|\(.value.source)|\(.value.path)|\(.value.version)|\(.value.installedAt)"' "$REGISTRY_FILE" | while IFS='|' read -r NAME SOURCE PATH VERSION INSTALLED; do
    echo "📦 $NAME"
    echo "   Source:    $SOURCE"
    if [ "$PATH" != "" ] && [ "$PATH" != "null" ]; then
        echo "   Path:      $PATH"
    fi
    echo "   Version:   $VERSION"
    echo "   Installed: $INSTALLED"
    echo ""
done
