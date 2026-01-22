#!/bin/bash
# Add a skill to the registry and install it locally
# Usage: add.sh owner/repo [skill-path]

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
    echo "Usage: add.sh owner/repo [skill-path]"
    echo "Example: add.sh vercel-labs/agent-skills skills/react-best-practices"
    exit 1
fi

SOURCE="$1"
SKILL_PATH="${2:-}"

# Parse owner and repo
OWNER=$(echo "$SOURCE" | cut -d'/' -f1)
REPO=$(echo "$SOURCE" | cut -d'/' -f2)

if [ -z "$OWNER" ] || [ -z "$REPO" ]; then
    echo "Error: Invalid source format. Use owner/repo"
    exit 1
fi

# Get the latest commit SHA from GitHub API
echo "Fetching latest version from GitHub..."
LATEST_SHA=$(curl -s "https://api.github.com/repos/$OWNER/$REPO/commits/main" | jq -r '.sha // empty')

if [ -z "$LATEST_SHA" ]; then
    # Try master branch
    LATEST_SHA=$(curl -s "https://api.github.com/repos/$OWNER/$REPO/commits/master" | jq -r '.sha // empty')
fi

if [ -z "$LATEST_SHA" ]; then
    echo "Error: Could not fetch latest commit. Check if repo exists and is accessible."
    exit 1
fi

SHORT_SHA="${LATEST_SHA:0:7}"

# Determine skill name
if [ -n "$SKILL_PATH" ]; then
    SKILL_NAME=$(basename "$SKILL_PATH")
else
    SKILL_NAME="$REPO"
fi

# Check if skill already exists in registry
if jq -e ".skills[\"$SKILL_NAME\"]" "$REGISTRY_FILE" > /dev/null 2>&1; then
    echo "Skill '$SKILL_NAME' already exists in registry."
    echo "Use update.sh to update it, or remove.sh to remove it first."
    exit 1
fi

# Add to registry
TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
TEMP_FILE=$(mktemp)

jq --arg name "$SKILL_NAME" \
   --arg source "$SOURCE" \
   --arg path "$SKILL_PATH" \
   --arg version "$SHORT_SHA" \
   --arg timestamp "$TIMESTAMP" \
   '.skills[$name] = {
     "source": $source,
     "path": $path,
     "version": $version,
     "installedAt": $timestamp
   }' "$REGISTRY_FILE" > "$TEMP_FILE"

mv "$TEMP_FILE" "$REGISTRY_FILE"

echo "Added '$SKILL_NAME' to registry (version: $SHORT_SHA)"

# Install via npx skills
echo "Installing skill..."
if [ -n "$SKILL_PATH" ]; then
    npx skills add "$SOURCE" "$SKILL_PATH"
else
    npx skills add "$SOURCE"
fi

echo "Successfully added and installed '$SKILL_NAME'"
