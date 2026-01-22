#!/bin/bash
# Save a skill to the registry (bookmark it)
# Usage: save.sh owner/repo [skill-name] [--install]

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/common.sh"

check_deps
require_config

# Parse arguments
SOURCE=""
SKILL_NAME=""
INSTALL_FLAG=false

for arg in "$@"; do
    case $arg in
        --install)
            INSTALL_FLAG=true
            ;;
        *)
            if [ -z "$SOURCE" ]; then
                SOURCE="$arg"
            else
                SKILL_NAME="$arg"
            fi
            ;;
    esac
done

if [ -z "$SOURCE" ]; then
    echo "Usage: save.sh owner/repo [skill-name] [--install]"
    echo ""
    echo "Examples:"
    echo "  save.sh vercel-labs/agent-skills react-best-practices"
    echo "  save.sh vercel-labs/agent-skills react-best-practices --install"
    exit 1
fi

# Parse owner and repo
OWNER=$(echo "$SOURCE" | cut -d'/' -f1)
REPO=$(echo "$SOURCE" | cut -d'/' -f2)

if [ -z "$OWNER" ] || [ -z "$REPO" ]; then
    echo "Error: Invalid source format. Use owner/repo"
    exit 1
fi

# Determine skill name and path
if [ -n "$SKILL_NAME" ]; then
    SKILL_PATH="skills/$SKILL_NAME"
else
    SKILL_NAME="$REPO"
    SKILL_PATH=""
fi

# Get registry file
REPO_PATH=$(get_repo_path)
REGISTRY_FILE="$REPO_PATH/skills-registry.json"

# Check if skill already exists in registry
if jq -e ".skills[\"$SKILL_NAME\"]" "$REGISTRY_FILE" > /dev/null 2>&1; then
    echo "Skill '$SKILL_NAME' is already saved in registry."
    exit 0
fi

# Add to registry
TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
TEMP_FILE=$(mktemp)

jq --arg name "$SKILL_NAME" \
   --arg source "$SOURCE" \
   --arg path "$SKILL_PATH" \
   --arg timestamp "$TIMESTAMP" \
   '.skills[$name] = {
     "source": $source,
     "path": $path,
     "savedAt": $timestamp
   }' "$REGISTRY_FILE" > "$TEMP_FILE"

mv "$TEMP_FILE" "$REGISTRY_FILE"

echo "Saved '$SKILL_NAME' to registry"
echo "  Source: $SOURCE"
if [ -n "$SKILL_PATH" ]; then
    echo "  Path: $SKILL_PATH"
fi

# Install if requested
if [ "$INSTALL_FLAG" = true ]; then
    echo ""
    echo "Installing..."
    if [ -n "$SKILL_PATH" ]; then
        npx skills add "$SOURCE" --skill "$SKILL_NAME" --agent claude-code --yes
    else
        npx skills add "$SOURCE" --agent claude-code --yes
    fi
    echo "Done!"
fi
