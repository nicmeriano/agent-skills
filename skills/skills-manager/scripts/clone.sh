#!/bin/bash
# Clone a remote skill to your skills/ directory
# Usage: clone.sh owner/repo [skill-name]

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/common.sh"

check_deps
require_config

if [ -z "$1" ]; then
    echo "Usage: clone.sh owner/repo [skill-name]"
    echo ""
    echo "Examples:"
    echo "  clone.sh vercel-labs/agent-skills react-best-practices"
    echo "  clone.sh owner/repo  # clones entire repo's skills"
    exit 1
fi

SOURCE="$1"
SKILL_NAME="${2:-}"

# Parse owner and repo
OWNER=$(echo "$SOURCE" | cut -d'/' -f1)
REPO=$(echo "$SOURCE" | cut -d'/' -f2)

if [ -z "$OWNER" ] || [ -z "$REPO" ]; then
    echo "Error: Invalid source format. Use owner/repo"
    exit 1
fi

# Get repo path
REPO_PATH=$(get_repo_path)
SKILLS_DIR="$REPO_PATH/skills"

# Create temp directory for cloning
TEMP_DIR=$(mktemp -d)
trap "rm -rf $TEMP_DIR" EXIT

echo "Cloning from $SOURCE..."

# Clone the repo
git clone --depth 1 "https://github.com/$SOURCE.git" "$TEMP_DIR/repo" 2>/dev/null

# Determine what to copy
if [ -n "$SKILL_NAME" ]; then
    # Clone specific skill
    SOURCE_PATH="$TEMP_DIR/repo/skills/$SKILL_NAME"

    if [ ! -d "$SOURCE_PATH" ]; then
        echo "Error: Skill '$SKILL_NAME' not found in $SOURCE"
        echo ""
        echo "Available skills:"
        ls -1 "$TEMP_DIR/repo/skills" 2>/dev/null || echo "  (no skills directory found)"
        exit 1
    fi

    TARGET_PATH="$SKILLS_DIR/$SKILL_NAME"

    # Check if already exists
    if [ -d "$TARGET_PATH" ]; then
        echo "Error: Skill '$SKILL_NAME' already exists in your skills/ directory."
        echo ""
        read -p "Overwrite? [y/N] " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            echo "Aborted."
            exit 1
        fi
        rm -rf "$TARGET_PATH"
    fi

    # Copy the skill
    cp -r "$SOURCE_PATH" "$TARGET_PATH"

    echo ""
    echo "Cloned '$SKILL_NAME' to $TARGET_PATH"
    echo ""
    echo "You can now customize this skill. It's yours!"

else
    # Clone all skills from the repo
    if [ ! -d "$TEMP_DIR/repo/skills" ]; then
        echo "Error: No skills/ directory found in $SOURCE"
        exit 1
    fi

    CLONED=0
    SKIPPED=0

    for skill_dir in "$TEMP_DIR/repo/skills"/*/; do
        if [ -d "$skill_dir" ]; then
            skill_name=$(basename "$skill_dir")
            TARGET_PATH="$SKILLS_DIR/$skill_name"

            if [ -d "$TARGET_PATH" ]; then
                echo "Skipping '$skill_name' (already exists)"
                ((SKIPPED++))
            else
                cp -r "$skill_dir" "$TARGET_PATH"
                echo "Cloned '$skill_name'"
                ((CLONED++))
            fi
        fi
    done

    echo ""
    echo "Cloned $CLONED skill(s), skipped $SKIPPED"
fi
