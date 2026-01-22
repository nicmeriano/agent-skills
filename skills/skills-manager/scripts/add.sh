#!/bin/bash
# Add/install a skill (passthrough to npx skills add)
# Does NOT save to registry
# Usage: add.sh owner/repo [skill-name] [--global]

set -e

if [ -z "$1" ]; then
    echo "Usage: add.sh owner/repo [skill-name] [--global]"
    echo ""
    echo "Examples:"
    echo "  add.sh vercel-labs/agent-skills react-best-practices"
    echo "  add.sh vercel-labs/agent-skills react-best-practices --global"
    echo "  add.sh owner/repo  # install all skills from repo"
    exit 1
fi

SOURCE="$1"
SKILL_NAME=""
GLOBAL_FLAG=""

# Parse arguments
shift
for arg in "$@"; do
    case $arg in
        --global|-g)
            GLOBAL_FLAG="--global"
            ;;
        *)
            SKILL_NAME="$arg"
            ;;
    esac
done

echo "Installing from $SOURCE..."
echo "(Not saving to registry)"
echo ""

# Build command
CMD="npx skills add $SOURCE --agent claude-code --yes"

if [ -n "$SKILL_NAME" ]; then
    CMD="$CMD --skill $SKILL_NAME"
fi

if [ -n "$GLOBAL_FLAG" ]; then
    CMD="$CMD --global"
fi

# Run it
eval $CMD

echo ""
echo "Done! (not saved to registry - use save.sh to bookmark)"
